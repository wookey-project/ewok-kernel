/* \file sched.c
 *
 * Copyright 2018 The wookey project team <wookey@ssi.gouv.fr>
 *   - Ryad     Benadjila
 *   - Arnauld  Michelizza
 *   - Mathieu  Renard
 *   - Philippe Thierry
 *   - Philippe Trebuchet
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 *
 */

#include "m4-mpu.h"
#include "m4-core.h"
#include "m4-cpu.h"
#include "tasks.h"
#include "sched.h"
#include "mpu.h"
#include "devices.h"
#include "apps_layout.h"
#include "layout.h"
#include "libc.h"
#include "debug.h"
#include "sleep.h"
#include "default_handlers.h"

#if CONFIG_SCHED_RAND
#include "soc-rng.h"
#endif

extern stack_frame_t *svc_handler(stack_frame_t* );

#define SCHED_PERIOD CONFIG_SCHED_PERIOD

/*
** current task
*/

static task_t *current_task = NULL;
static task_t *last_user_task = NULL;

/* default first user task */

#ifdef CONFIG_KERNEL_SCHED_DEBUG
typedef struct {
  uint32_t ts;   /* timestamp          */
  uint8_t  id;   /* task id            */
  uint8_t  mode; /* task mode (ISR/MT) */
} sched_debug_t;

static struct {
    uint32_t start;
    uint32_t end;
    sched_debug_t buf[CONFIG_KERNEL_SCHED_DEBUG_BUFSIZE];
} sched_ring_buffer;

void init_sched_ring_buffer(void)
{
    sched_ring_buffer.end = 0;
    sched_ring_buffer.start = sched_ring_buffer.end;
    memset((void*)sched_ring_buffer.buf, 0, CONFIG_KERNEL_SCHED_DEBUG_BUFSIZE * sizeof(sched_debug_t));
}

static void push_sched_info(uint32_t ts, uint8_t id, uint8_t mode)
{
    sched_ring_buffer.buf[sched_ring_buffer.end].ts = ts;
    sched_ring_buffer.buf[sched_ring_buffer.end].id = id;
    sched_ring_buffer.buf[sched_ring_buffer.end++].mode = mode;
    sched_ring_buffer.end %= CONFIG_KERNEL_SCHED_DEBUG_BUFSIZE;
    if (sched_ring_buffer.end == sched_ring_buffer.start) {
        sched_ring_buffer.start++;
        sched_ring_buffer.start %= CONFIG_KERNEL_SCHED_DEBUG_BUFSIZE;
    }
}
#endif



#if defined(CONFIG_SCHED_RR) || defined(CONFIG_SCHED_MLQ_RR)
//static uint8_t current_id = 0;
#endif

static uint32_t sched_period = 0;

task_t *sched_get_current(void)
{
    return current_task;
}

/**
** Elect the task. This function host the EwoK scheduling policy.
** EwoK supports various policies by configuration but keeps the same
** general principle:
** 1) If an ISR has to be executed, execute it
** 2) If a forced main-thread exec is required by a currently finishing ISR, execute it
**    This specific property is for high reactivity hardware drivers, that need to execute
      their main thread just after their ISR
** 3) If softirq (handling syscalls, prepare ISR) has to be executed, execute it
** 4) Current scheduling policy on all schedulable tasks (RAND, RR or MLQ_RR)
** 5) If none of the above, execute Idle
**
*/
static task_t *sched_task_elect(void)
{
    e_task_id   id;
    task_t     *tasks_list = task_get_tasks_list();
    task_t     *elected = 0;

    /* Execute pending user ISR first */
    for (id = ID_APP1; id <= ID_APPMAX; ++id) {
        if (tasks_list[id].mode == TASK_MODE_ISRTHREAD &&
            tasks_list[id].state[TASK_MODE_ISRTHREAD] == TASK_STATE_RUNNABLE)
        {
            DEBUG(DBG_DEBUG, "task %s (id: %d, slot %d) is in ISR mode\n",
                  tasks_list[id].name, tasks_list[id].id, tasks_list[id].slot);
#ifdef CONFIG_KERNEL_SCHED_DEBUG
            tasks_list[id].isr_count++;
#endif
            elected = &tasks_list[id];
            goto end;
        }
    }

    /* Execute tasks in critical sections */
    for (id = ID_APP1; id <= ID_APPMAX; ++id) {
        if (tasks_list[id].state[TASK_MODE_MAINTHREAD] == TASK_STATE_LOCKED) {
            elected = &tasks_list[id];
            goto end;
        }
    }

    /* Any finished ISR is updated in order to go back to its main thread
     * state
     */
    for (id = ID_APP1; id <= ID_APPMAX; ++id) {
        if (tasks_list[id].mode == TASK_MODE_ISRTHREAD &&
            tasks_list[id].state[TASK_MODE_ISRTHREAD] == TASK_STATE_ISR_DONE)
        {
            tasks_list[id].state[TASK_MODE_ISRTHREAD] = TASK_STATE_IDLE;
            tasks_list[id].ctx[TASK_MODE_ISRTHREAD].frame = 0;
            tasks_list[id].ctx[TASK_MODE_ISRTHREAD].dev_id = ID_DEV_UNUSED;
            tasks_list[id].ctx[TASK_MODE_ISRTHREAD].irq = 0;
            tasks_list[id].mode = TASK_MODE_MAINTHREAD;

#ifdef CONFIG_SCHED_SUPPORT_FISR
            /* if a task has just finished its ISR, elect its main thread
               if not SVC_BLOCKED and the ISR requires a forced election */
            if (tasks_list[id].state[TASK_MODE_MAINTHREAD] == TASK_STATE_FORCED) {
                tasks_list[id].state[TASK_MODE_MAINTHREAD] = TASK_STATE_RUNNABLE;

# ifdef CONFIG_KERNEL_SCHED_DEBUG
                tasks_list[id].force_count++;
# endif
                elected = &tasks_list[id];
                goto end;
            }
#endif
            if (sleep_is_sleeping_task(id)) {
                sleep_try_waking_up(id);
            } else {
                /* finishing ISR awake their main threads when they are in IDLE
                 * mode, scheduling is leaved to the scheduler policy
                 * TODO: implement task_awake(id, state) would be better...
                 */
                if (tasks_list[id].state[TASK_MODE_MAINTHREAD] == TASK_STATE_IDLE) {
                    tasks_list[id].state[TASK_MODE_MAINTHREAD] = TASK_STATE_RUNNABLE;
                }
            }
        }
    }

    /* Check if there are some pending softirqs */
    if (tasks_list[ID_SOFTIRQ].state[TASK_MODE_MAINTHREAD] == TASK_STATE_RUNNABLE) {
#ifdef CONFIG_KERNEL_SCHED_KERNEL_SCHED_DEBUG
            tasks_list[ID_SOFTIRQ].count++;
#endif
        elected = &tasks_list[ID_SOFTIRQ];
        goto end;
    }

    /* if a task has been set as FORCED through an IPC, its priority is higher for once */
#ifdef CONFIG_SCHED_SUPPORT_FIPC
    for (id = ID_APP1; id <= ID_APPMAX; ++id) {
        if (tasks_list[id].state[TASK_MODE_MAINTHREAD] == TASK_STATE_FORCED) {
# ifdef CONFIG_KERNEL_SCHED_DEBUG
            tasks_list[id].force_count++;
# endif
            tasks_list[id].state[TASK_MODE_MAINTHREAD] = TASK_STATE_RUNNABLE;
            elected = &tasks_list[id];
            goto end;

        }
    }
#endif

#if CONFIG_SCHED_RAND
    uint32_t rand = 0;
    uint8_t  maxtests = 0;

    do {
        soc_rng_getrng(&rand);
        id = ID_APP1 + (rand % (ID_APPMAX - ID_APP1 + 1));

        /*
         * if current task mode is ISRTHREAD, its state can't be runnable but ISR_DONE or IDLE
         * it can't be elected here (automaticaly not runnable)
        */
        if (tasks_list[id].state[tasks_list[id].mode] == TASK_STATE_RUNNABLE) {
#ifdef CONFIG_KERNEL_SCHED_DEBUG
            tasks_list[id].count++;
#endif
            elected = &tasks_list[id];
            goto end;
        }
    } while (maxtests++ < 32);
#endif

#if CONFIG_SCHED_RR
    id = last_user_task->id;
    for (int i = ID_APP1; i <= ID_APPMAX; i++) {
        if (id < ID_APPMAX) {
            id++;
        }
        else {
            id = ID_APP1;
        }

        if (tasks_list[id].state[tasks_list[id].mode] == TASK_STATE_RUNNABLE)       {
#ifdef CONFIG_KERNEL_SCHED_DEBUG
            tasks_list[id].count++;
#endif
            elected = &tasks_list[id];
            last_user_task = elected;
            goto end;
        }
    }
#endif

#if CONFIG_SCHED_MLQ_RR
    uint8_t prio = 0;

    /* 1) find the max priority runnable */
    for (int i = ID_APP1; i <= ID_APPMAX; i++) {
        if (tasks_list[i].state[TASK_MODE_MAINTHREAD] == TASK_STATE_RUNNABLE &&
            tasks_list[i].prio > prio)
        {
                prio = tasks_list[i].prio;
        }
    }

    /* 2) now execute a RR scheduling on the tasks of the same priority only */
    id = last_user_task->id;
    for (int i = ID_APP1; i <= ID_APPMAX; i++) {
        if (id < ID_APPMAX) {
            id++;
        }
        else {
            id = ID_APP1;
        }

        if (   tasks_list[id].prio == prio
            && tasks_list[id].state[TASK_MODE_MAINTHREAD] == TASK_STATE_RUNNABLE)
        {
#ifdef CONFIG_KERNEL_SCHED_DEBUG
            tasks_list[id].count++;
#endif
	        elected = &tasks_list[id];
            last_user_task = elected;
            goto end;
	    }
    }

#ifdef CONFIG_KERNEL_SCHED_DEBUG
    tasks_list[id].count++;
#endif

    if (tasks_list[id].state[TASK_MODE_MAINTHREAD] == TASK_STATE_RUNNABLE) {
	    elected = &tasks_list[id];
        last_user_task = elected;
        goto end;
    }
#endif /* MLQ_RR */

    /* Execute the idle task */
#ifdef CONFIG_KERNEL_SCHED_DEBUG
    tasks_list[ID_KERNEL].count++;
#endif
    elected = &tasks_list[ID_KERNEL];

end:
#ifdef CONFIG_KERNEL_SCHED_DEBUG
    push_sched_info(soc_dwt_getcycles() / MAIN_CLOCK_FREQUENCY_US, elected->id, elected->mode);
#endif

	DEBUG(DBG_DEBUG, "task %s (id %d) has been elected\n",
	      elected->name, elected->id);

    return elected;
}

/*
 * MPU region management during scheduling
 *
 * BEWARE: Mapping new regions without disabling MPU is feasable only for
 * non-overlapping regions. Otherwhise, MPU MUST be disabled during the configuration
 * or the region being configured at least once during the init before mpu_enable,
 * even if it is replaced after.
 */
uint8_t sched_switch_mpu(task_t *next)
{
    e_region_type   region_type;
    uint8_t         mpu_region_size;
    uint8_t         ret;
    physaddr_t      dev_addr;
    uint32_t        dev_size;
    e_device_id     dev_id;

    if (next->type == TASK_TYPE_USER) {
        KERNLOG(DBG_DEBUG, "remapping MPU for user schedule !\n");

        uint8_t num_mapped_dev = 0;

        if (next->mode == TASK_MODE_ISRTHREAD) {
            dev_id   = next->ctx[TASK_MODE_ISRTHREAD].dev_id;
            dev_size = dev_get_device_size(dev_id);
            dev_addr = dev_get_device_addr(dev_id);

            if (dev_id != ID_DEV_UNUSED && dev_size != 0) {

                /* Convert size in bytes to MPU format used in RASR registers */
                mpu_region_size = core_mpu_bytes_to_region_size(dev_size);

                if (dev_is_device_region_ro(dev_id)) {
                    region_type = MPU_REGION_RO_USER_DEV;
                } else {
                    region_type = MPU_REGION_USER_DEV;
                }

                ret = mpu_regions_schedule (MPU_LAST_REGION,
                                            dev_addr,
                                            mpu_region_size,
                                            region_type,
                                            dev_get_device_region_mask(dev_id));
                if (ret > 0) {
                    KERNLOG(DBG_ERR,
                            "Unable to map userspace device id %d (@0x%x) !\n",
                            dev_id, dev_addr);
                } else {
                    num_mapped_dev++;
                }
            }

            /* Mapping the ISR stack using an empty dedicated region in the
             * kernel RAM */
            ret = mpu_regions_schedule (MPU_USER_ISR_RAM_REGION,
                                        STACK_TOP_ISR - STACK_SIZE_ISR,
                                        MPU_REGION_SIZE_4Kb,
                                        MPU_REGION_ISR_RAM,
                                        0);
            if (ret > 0) {
                 KERNLOG(DBG_ERR,
                        "Unable to remap isr stack for isr handler of task %s (%d) !\n",
                        next->name, next->id);
            }
            /*
             * Now all devices are mapped.
             * Nevertheless, as some tasks may map 0, 1, or 2 devices, ISR map 0 or 1 devices, previously mapped
             * devices may not be demapped by another mapping at scheduling time (imagine a task mapping 2 devices,
             * then another task mapping 0 device. This last app would be able to access the previous task devices
             * as they have never been unmapped.
             * This is the goald of this little part of code:
             * For each residual region used for device mapping (i.e. for which a device has not been mapped in
             * this current MPU switching context), we map a specific unaccessible region to avoid any shadowing
             * and potential leak or uncontroled communication channel.
             *
             * This loop differ from the mainthread mon one: the first free region for ISR is used to map the ISR
             * stack, not a device. This region must not be disabled as it is always remapped in ISR context.
             */
            for (uint8_t current_region = (uint8_t)(MPU_LAST_REGION - num_mapped_dev);
                    current_region > MPU_LAST_REGION - MPU_MAX_EMPTY_REGIONS + 1;
                    current_region--) {
                ret = core_mpu_region_disable(current_region);
                if (ret != 0) {
                    KERNLOG(DBG_ERR,
                            "Unable to disable region %d! leak risk!\n",
                            current_region);
                }
            }


        } else { /* TASK_MODE_MAINTHREAD */

            /* FIXME: remove MIN and use next->num_devs but still use
             *    some defensive code
             * NOTE:  a task cannot register more than 2 devices with MMIO
             * TODO: blah blah blah...
             */

            for (uint8_t i = 0; i < next->num_devs; ++i) {
                dev_id   = next->dev_id[i];
                dev_size = dev_get_device_size (dev_id);
                dev_addr = dev_get_device_addr (dev_id);

                // device is previously mapped if:
                // - declared as DEV_MAP_AUTO
                // - declared as DEV_MAP_VOLUNTARY and mapping request
                //   has already be done, with no unmap after
                if (dev_size != 0 && dev_is_mapped(dev_id)) {
                    /* previously mapped DEV_MAP_VOLUNTARY devices are falgued
                     * as previously mapped, which keep them mapped at schedule time
                     * sys_cfg(CFG_DEV_(UN)MAP only manipulate this flag to
                     * (un)map the device at next mpu configuration time,
                     * which is syncrhonous for this syscall
                     */
                    if (num_mapped_dev < MPU_MAX_EMPTY_REGIONS) {
                        mpu_region_size = core_mpu_bytes_to_region_size(dev_size);

                        if (dev_is_device_region_ro(dev_id)) {
                            region_type = MPU_REGION_RO_USER_DEV;
                        } else {
                            region_type = MPU_REGION_USER_DEV;
                        }

                        ret = mpu_regions_schedule((uint8_t)(MPU_LAST_REGION - num_mapped_dev),
                                dev_addr,
                                mpu_region_size,
                                region_type,
                                dev_get_device_region_mask(dev_id));
                        if (ret > 0) {
                            KERNLOG(DBG_ERR,
                                    "Unable to map userspace device %d (@0x%x) !\n",
                                    dev_id, dev_addr);
                        } else {
                            num_mapped_dev++;
                        }
                    } else {
                            KERNLOG(DBG_ERR,
                                    "Unable to map userspace device %d: (@0x%x): memory regions exhausted !\n",
                                    dev_id, dev_addr);
                    }
                }
            }
            /*
             * Now all devices are mapped.
             * Nevertheless, as some tasks may map 0, 1, or 2 devices, ISR map 0 or 1 devices, previously mapped
             * devices may not be demapped by another mapping at scheduling time (imagine a task mapping 2 devices,
             * then another task mapping 0 device. This last app would be able to access the previous task devices
             * as they have never been unmapped.
             * This is the goald of this little part of code:
             * For each residual region used for device mapping (i.e. for which a device has not been mapped in
             * this current MPU switching context), we map a specific unaccessible region to avoid any shadowing
             * and potential leak or uncontroled communication channel.
             */
            for (uint8_t current_region = (uint8_t)(MPU_LAST_REGION - num_mapped_dev);
                    current_region > MPU_LAST_REGION - MPU_MAX_EMPTY_REGIONS;
                    current_region--) {
                ret = core_mpu_region_disable(current_region);
                if (ret != 0) {
                    KERNLOG(DBG_ERR,
                            "Unable to disable region %d! leak risk!\n",
                            current_region);
                }
            }
        }


        /* Now remapping user txt and ram region with subregion deactivation
         * the MPU mask depends on the number of required slots */
        uint8_t mask = 0xff;

        for (uint8_t i = 0; i < next->num_slots; ++i) {
            /* Note: slot are numbered from 1 to 8 */
            mask &= mpu_region_mask[next->slot - 1 + i];
        }

        /* Mapping code */
        ret = mpu_regions_schedule (MPU_USER_TXT_REGION,
                                    TXT_USER_REGION_BASE,
                                    TXT_USER_REGION_SIZE,
                                    MPU_REGION_USER_TXT,
                                    mask);
        if (ret > 0) {
            KERNLOG(DBG_ERR,
                    "Unable to remap user txt for task %s (%d) !\n",
                    next->name, next->id);
        }

        /* Mapping data */
        ret = mpu_regions_schedule (MPU_USER_RAM_REGION,
                                    RAM_USER_BASE,
                                    RAM_USER_REGION_SIZE,
                                    MPU_REGION_USER_RAM,
                                    mask);

        if (ret > 0) {
            KERNLOG(DBG_ERR,
                    "Unable to remap user txt for task %s (%d) !\n",
                    next->name, next->id);
        }

    }

    /* TODO: not TASK_TYPE_USER, specific to STM32F4!!! */
    else {
        KERNLOG(DBG_DEBUG, "remapping MPU for kernel schedule !\n");
        /* Lock BOOTROM mapping for supervisor mode (in user mode, it is
         * already locked by the default MPU map) */
        ret = mpu_regions_schedule (MPU_BOOT_ROM_REGION,
                                    0x1FFF0000,
                                    MPU_REGION_SIZE_32Kb,
                                    MPU_REGION_BOOTROM,
                                    0);

        if (ret > 0) {
            KERNLOG(DBG_ERR, "Unable to remap bootrom lock !\n");
        }
        return ret;
    }

    return 0;
}

/* This interrupt is activated by request_schedule() */
stack_frame_t *Sched_PendSV_Handler(stack_frame_t * stack_frame)
{
    sched_period = 0;
    // no election when ISR thread is being run. It should finish with SVC
    if (current_task->mode == TASK_MODE_ISRTHREAD &&
        current_task->state[TASK_MODE_ISRTHREAD] == TASK_STATE_RUNNABLE) {
      return stack_frame;
    }
    current_task->ctx[current_task->mode].frame = stack_frame;
    current_task = sched_task_elect();
    full_memory_barrier();
    sched_switch_mpu(current_task);
    return current_task->ctx[current_task->mode].frame;
}

stack_frame_t *Sched_Systick_Handler(stack_frame_t * stack_frame)
{
    // reduce the dwt previous value scoping to this function only
    core_systick_handler(stack_frame);

    /* decrement sleep count of sleeping tasks */
    sleep_check_is_awoke();

    /* Managing DWT cycle count overflow */
    soc_dwt_ovf_manage();

    sched_period++;
    if (sched_period == SCHED_PERIOD) {
        sched_period = 0;

        // no election when ISR thread is being run. It should finish with SVC
        if (current_task->mode == TASK_MODE_ISRTHREAD &&
            current_task->state[TASK_MODE_ISRTHREAD] == TASK_STATE_RUNNABLE) {
          return stack_frame;
        }
        current_task->ctx[current_task->mode].frame = stack_frame;
        current_task = sched_task_elect();
        full_memory_barrier();
        sched_switch_mpu(current_task);
        return current_task->ctx[current_task->mode].frame;
    } else {
        return stack_frame;
    }
}


void sched_init(void)
{
    task_t *tasks_list = task_get_tasks_list();

#ifdef CONFIG_KERNEL_SCHED_DEBUG
    init_sched_ring_buffer();
#endif

    current_task = &tasks_list[ID_KERNEL];
    last_user_task = &tasks_list[ID_APP1];

    /* Set handlers involved in scheduling */
    set_interrupt_handler(SYSTICK_IRQ, Sched_Systick_Handler, 0, ID_DEV_UNUSED);
    set_interrupt_handler(PENDSV_IRQ, Sched_PendSV_Handler, 0, ID_DEV_UNUSED);
    set_interrupt_handler(SVC_IRQ, svc_handler, 0, ID_DEV_UNUSED);

    /*
     * Initial context switches to kernel.
     */
	asm volatile
       ("mov r0, %[SP]      \n\t"   \
        "msr psp, r0        \n\t"   \
        "mov r0, 2          \n\t"   \
        "msr control, r0    \n\t"   \
	    "mov r1, %[PC]      \n\t"   \
	    "bx r1              \n\t"   \
        :
        : [PC] "r" (current_task->fn),
          [SP] "r" (current_task->ctx[current_task->mode].frame)
        : "r0", "r1");
}
