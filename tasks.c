/* \file tasks.c
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

#include "tasks.h"
#include "m4-cpu.h"
#include "layout.h"
#include "soc-layout.h"
#include "apps_layout.h"
#include "debug.h"
#include "sched.h"
#include "kernel.h"
#include "softirq.h"
#include "autoconf.h"
#include "sections.h"

#define EXC_THREAD_MODE  0xFFFFFFFD
#define EXC_KERN_MODE    0xFFFFFFF9
#define EXC_HANDLER_MODE 0xFFFFFFF1

/* number of task registered in the slots */
static uint8_t num_tasks = 0;

/* size of .text content of tasks (i.e. size of slots in memory mapping) */
static uint32_t task_txt_size = 0;
static uint32_t task_ram_size = 0;

/* calculate the user base @, depending on FW1, FW2, DFU1, DFU2 ctx. */
static uint32_t user_base = 0;

/*
** global task contexts tab (max 8 tasks)
** please avoid = 0 in globals, they are set in .data instead of .bss, which
** generates huge amount of memory in flash for nothing.
*/
static task_t tasks_list[ID_MAX];

/************************************************************************
 * Threads
 * This part hosts kernel-land threads others than softirq (which has
 * its dedicated package)
 ***********************************************************************/

/*
** This is the idle task. As we are in collaborative mode, this is simply a kernel task
** when no userspace task is schedulable. This task simply waits for an interrupt.
** All userspace tasks are interrupt based (HW timers, device's IRQ...)
** In this case, this idle tasks looks like a simple "main loop".
*/
static void task_idle(void)
{
    KERNLOG(DBG_NOTICE, "[II] EwoK ukernel IDLE thread starting\n");
    dbg_flush();
    enable_irq();
    while (1) {
        wait_for_interrupt();
    }
}


/************************************************************************
 * Utility functions for task execution
 ***********************************************************************/

/*
 * This function is used as LR value of the initial frame created
 * at task initialization time. Nevertheless, this is not a real
 * need as the _main function is called by do_starttask() which
 * istelf finishes with a while(1); waiting for the task state to
 * be set at finished. This function, as a consequence, should never
 * be called.
 */
static void task_finish(void)
{
    /* the task will never exit from here and will never be schedule again */
    while (1) ;
}

/************************************************************************
 * Utility functions for task creation
 * These functions create task context, task stack, etc.
 ***********************************************************************/

/*
 * This function create the first frame of the user task, before its first
 * execution
 * This construct permits to geenrate  a clean stack frame in a dedicated
 * user stack area
 *
 * args specify the 4 first registers value, if needed, to
 */
void task_create_stack(task_context_t * ctx, physaddr_t sp, physaddr_t pc,
                       physaddr_t * args)
{
    ctx->frame = (stack_frame_t *) ((uint32_t) sp - sizeof(stack_frame_t));

    if (args) {
        ctx->frame->r0 = args[0];
        ctx->frame->r1 = args[1];
        ctx->frame->r2 = args[2];
        ctx->frame->r3 = args[3];
    } else {
        ctx->frame->r0 = 0x0;
        ctx->frame->r1 = 0x0;
        ctx->frame->r2 = 0x0;
        ctx->frame->r3 = 0x0;
    }

    ctx->frame->r4 = 0x0;
    ctx->frame->r5 = 0x0;
    ctx->frame->r6 = 0x0;
    ctx->frame->r7 = 0x0;
    ctx->frame->r8 = 0x0;
    ctx->frame->r9 = 0x0;
    ctx->frame->r10 = 0x0;
    ctx->frame->r11 = 0x0;
    ctx->frame->r12 = 0x0;
    ctx->frame->lr = (uint32_t) EXC_THREAD_MODE;
    ctx->frame->prev_lr = (uint32_t) task_finish;
    ctx->frame->pc = pc;
    ctx->frame->xpsr = 0x1000000;   /* Thumb bit on */
}

/*
 * Create the softirq task context
 */
uint8_t task_init_softirq(void)
{
    task_t *tsk = &tasks_list[ID_SOFTIRQ];    // kernel task is tasks_list[9]
    tsk->name = "softirq";
    tsk->mode = TASK_MODE_MAINTHREAD;
    tsk->fn =
        ((physaddr_t) task_softirq % 2 ==
         1) ? (physaddr_t) task_softirq : (physaddr_t) task_softirq + 1;
    tsk->type = TASK_TYPE_KERNEL;
    tsk->id = ID_SOFTIRQ;
    tsk->slot = 0;              /* unused */

    memset((void*)(STACK_TOP_SOFTIRQ - STACK_SIZE_SOFTIRQ), 0, STACK_SIZE_SOFTIRQ);
    task_create_stack(&(tsk->ctx[TASK_MODE_MAINTHREAD]), STACK_TOP_SOFTIRQ,
                      tsk->fn, 0);

    tsk->stack_size = STACK_SIZE_SOFTIRQ;

    tsk->state[TASK_MODE_MAINTHREAD] = TASK_STATE_IDLE;
    tsk->state[TASK_MODE_ISRTHREAD] = TASK_STATE_IDLE;  /* always */

    for (int i=0;i<ID_MAX;i++) {
        tsk->ipc_endpoint[i] = NULL;
    }

    KERNLOG(DBG_INFO,
            "created context for softirq task '%s' (@%x) sp: @%x\n",
            tsk->name, tsk->fn, tsk->ctx[TASK_MODE_MAINTHREAD].frame);
    return 0;
}

/*
 * Create the idle task context
 */
uint8_t task_init_idle(void)
{
    task_t *tsk = &tasks_list[ID_KERNEL];
    tsk->name = "idle";
    tsk->fn =
        ((physaddr_t) task_idle % 2 ==
         1) ? (physaddr_t) task_idle : (physaddr_t) task_idle + 1;
    tsk->type = TASK_TYPE_KERNEL;
    tsk->id = ID_KERNEL;
    tsk->slot = 0;              /* unused */
    tsk->prio = 0;              /* unused */

    task_create_stack(&(tsk->ctx[TASK_MODE_MAINTHREAD]), STACK_TOP_IDLE, tsk->fn, 0);
    tsk->stack_size = STACK_SIZE_IDLE;

    tsk->mode = TASK_MODE_MAINTHREAD;
    tsk->state[TASK_MODE_MAINTHREAD] = TASK_STATE_RUNNABLE;
    tsk->state[TASK_MODE_ISRTHREAD] = TASK_STATE_IDLE;  /* always */

    for (int i=0;i<ID_MAX;i++) {
        tsk->ipc_endpoint[i] = NULL;
    }

    KERNLOG(DBG_INFO,
            "created context for kernel task '%s' (@%x), sp: @%x\n",
            tsk->name, tsk->fn, tsk->ctx[TASK_MODE_MAINTHREAD].frame);
    return 0;
}

/*
 * Initialize all userspace tasks.
 */
uint8_t task_init_apps(void)
{
    int i;

    /*
     * How many tasks ?
     * Tasks are defined in 'app_tab' array (include/generated/apps_layout.h)
     */
    num_tasks = sizeof(app_tab) / sizeof(struct app);

    if (num_tasks > 7) {
        KERNLOG(DBG_ERR,
                "[EE] too many apps ! only 7 apps can be included ! see include/generated/apps_layout.h\n");
        panic("stopping initialization\n");
    }

#ifdef CONFIG_FIRMWARE_DUALBANK
    /* Detect if we are in firmware 1 or 2 */
    if ((uint32_t) task_init_apps < FW1_USER_BASE) {
        user_base = FW1_USER_BASE;
    } else {
        user_base = FW2_USER_BASE;
    }
#else
    user_base = FW1_USER_BASE;
#endif

    /* Slot size is fixed. An application may requires more than one slot */
    task_txt_size = TXT_USER_SIZE / 8; // MPU specific
    task_ram_size = RAM_USER_SIZE;

    for (i = 0; i < num_tasks; ++i) {
        physaddr_t args[4] = { 0, 0, 0, 0 };

        task_t *tsk = &tasks_list[ID_APP1 + i];
        memset(tsk, 0, sizeof(tsk));

        tsk->id = ID_APP1 + i; /* id range from ID_APP1 to ID_APP7 */
        tsk->slot = app_tab[i].slot;
        tsk->num_slots = app_tab[i].num_slots;
#if CONFIG_KERNEL_DOMAIN
        tsk->domain = app_tab[i].domain;
#endif
        tsk->fn =
            (physaddr_t) user_base +
            (uint32_t) ((uint8_t) (tsk->slot - 1) * (uint32_t) task_txt_size);

        tsk->fn = tsk->fn % 2 == 1 ? tsk->fn : tsk->fn + 1;
        tsk->name = app_tab[i].name;
        tsk->type = TASK_TYPE_USER;
        tsk->ctx[TASK_MODE_ISRTHREAD].fn = app_tab[i].startisr;
        tsk->prio = app_tab[i].prio;
#ifdef CONFIG_KERNEL_SCHED_DEBUG
        tsk->count = 0;
        tsk->force_count = 0;
        tsk->isr_count = 0;
#endif
        tsk->num_devs = 0;
        tsk->num_devs_mmapped = 0;

        /* RAM size depends on the number of required slots
         * less big */
        tsk->ram_slot_start = RAM_USER_BASE +
            ((uint32_t)tsk->slot - 1) * task_ram_size;

        tsk->ram_slot_end = RAM_USER_BASE +
            ((uint32_t)tsk->slot + tsk->num_slots - 1) * task_ram_size;

        /* FLASH size depends on the number of required slots */
        tsk->txt_slot_start = user_base +
            ((uint32_t)tsk->slot - 1) * task_txt_size;

        tsk->txt_slot_end = user_base +
            ((uint32_t)tsk->slot + tsk->num_slots - 1) * task_txt_size;

        /* Top of the stack is at the end of the task's address space */
        args[0] = tsk->id;
        task_create_stack(&(tsk->ctx[TASK_MODE_MAINTHREAD]), tsk->ram_slot_end, tsk->fn, args);

        tsk->stack_size = app_tab[i].stacksize;
        tsk->mode = TASK_MODE_MAINTHREAD;
        tsk->state[TASK_MODE_MAINTHREAD] = TASK_STATE_RUNNABLE;
        tsk->state[TASK_MODE_ISRTHREAD] = TASK_STATE_IDLE;
        tsk->init_done = false;

        for (int i=0;i<ID_MAX;i++) {
            tsk->ipc_endpoint[i] = NULL;
        }

        KERNLOG(DBG_INFO,
                "created context for task '%s' (@%x), sp: %x\n",
                tsk->name, tsk->fn, tsk->ctx[TASK_MODE_MAINTHREAD].frame);
        KERNLOG(DBG_DEBUG, "context for task '%s'\n", tsk->name);
        KERNLOG(DBG_DEBUG, " - _start '%x'\n", tsk->fn);
        KERNLOG(DBG_DEBUG, " - SP '%x'\n", tsk->ctx[TASK_MODE_MAINTHREAD].frame);
    }
    dbg_flush();

    return 0;
}

/************************************************************************
 * Task package getters and setters
 ***********************************************************************/

/*
 * Get the list of tasks
 */
task_t* task_get_tasks_list(void)
{
    return tasks_list;
}

/*
 * get the task structure using its identifier
 */
task_t* task_get_task(e_task_id id)
{
    return &tasks_list[id];
}


/*
 * Set the given task thread to a given state
 */
void task_set_task_state(e_task_id id, e_task_mode thread, e_task_state state)
{
    tasks_list[id].state[thread] = state;
}

e_task_state task_get_task_state(e_task_id id, e_task_mode mode)
{
    return tasks_list[id].state[mode];
}

/*
 * Get the task name using its identifier
 */
const char* task_get_name(e_task_id id)
{
    return tasks_list[id].name;
}


/*
** return true if the task is an existing userspace task
*/
uint8_t task_is_user(e_task_id id)
{
    if (id > ID_MAX) {
        /* Not a valid id (generates a table overflow), may be a ANY_APP id */
        return 0;
    }
    /* id higher thant MAXTASKS */
    if (id >= ID_APP1 && id <= ID_APP1 + CONFIG_MAXTASKS - 1) {
        return 1;
    }
    return 0;
}

/************************************************************************
 * Global task package initializer
 ***********************************************************************/
/*
** \fn task module initialization function
*/
void task_init(void)
{
    e_task_id id;

    for (id = 0; id < ID_MAX; id++) {
        tasks_list[id].state[TASK_MODE_MAINTHREAD] = TASK_STATE_EMPTY;
    }

    if (task_init_idle()) {
        ERROR("idle task context initialization fails!\n");
        dbg_flush();
        panic("Unable to prepare for creating idle task.\n");
    }
    if (task_init_softirq()) {
        ERROR("softirq task context initialization fails!\n");
        dbg_flush();
        panic("Unable to prepare for creating softirq task.\n");
    }
    if (task_init_apps()) {
        ERROR("Userspace tasks contexts initialization fails!\n");
        dbg_flush();
        panic("Unable to prepare for creating user tasks.\n");
    }
    task_map_data();
    KERNLOG(DBG_NOTICE,
            "data sections of userspace tasks mapped in user RAM slots\n");
    KERNLOG(DBG_NOTICE, "bss sections of userspace tasks zero'ified\n");
    dbg_flush();
}
