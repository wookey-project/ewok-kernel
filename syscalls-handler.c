/* \file syscalls-handler.c
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

#include "autoconf.h"
#include "types.h"
#include "debug.h"
#include "tasks.h"
#include "sched.h"
#include "softirq.h"
#include "syscalls.h"
#include "syscalls-cfg.h"
#include "syscalls-dma.h"

static inline bool svc_is_synchronous_syscall(task_t * caller)
{
    uint32_t *args = 0;
    uint32_t syscall = 0;
    uint32_t subsyscall = 0;
    stack_frame_t *frame = caller->ctx[caller->mode].frame;

    // let's execute the effective content of the syscall from the userspace task
    // FIXME: [PTH] svc is 8bits on Thumb2, to be updated for portability
    args = (uint32_t *) frame->r0;

    syscall = (uint32_t) args[0];
    subsyscall = (uint32_t) args[1];

    if (syscall == SYS_YIELD) {
        return true;
    }
    if (syscall == SYS_GETTICK) {
        return true;
    }
    if (syscall == SYS_RESET) {
        return true;
    }
    if (syscall == SYS_SLEEP) {
        return true;
    }
    if (syscall == SYS_LOCK) {
        return true;
    }
    if (syscall == SYS_CFG) {
        if (subsyscall == CFG_GPIO_GET   ||
            subsyscall == CFG_GPIO_SET   ||
            subsyscall == CFG_GPIO_UNLOCK_EXTI||
            subsyscall == CFG_DMA_RELOAD ||
            subsyscall == CFG_DMA_RECONF ||
            subsyscall == CFG_DMA_DISABLE||
            subsyscall == CFG_DEV_MAP    ||
            subsyscall == CFG_DEV_UNMAP)
        {
            return true;
        }
    }
    return false;
}


/*
** Handler managing syscalls (svc 0) directly in hanlder mode (synchronous syscalls
** the syscall mode is given to the syscall directly
*/
static inline void svc_synchronous_syscall(task_t * caller)
{
    svcnum_t svc = 0;
    uint32_t *args = 0;
    char *svcptr = 0;
    uint32_t syscall = 0;
    uint32_t subsyscall = 0;

    stack_frame_t *frame = caller->ctx[caller->mode].frame;

    // let's execute the effective content of the syscall from the userspace task
    // FIXME: [PTH] svc is 8bits on Thumb2, to be updated for portability
    svcptr = (char *)frame->pc;
    svc = (uint32_t) svcptr[-2];
    args = (uint32_t *) frame->r0;
    subsyscall = (uint32_t) args[1];

    if (svc != 0) {
        dbg_log("unsupported system call svc=%d!\n", svc);
        dbg_flush();
    }

    syscall = (uint32_t) args[0];

    KERNLOG(DBG_DEBUG, "Executing syscall %d for task %s\n", syscall,
            caller->name);
    switch (syscall) {
    case SYS_YIELD:
        sys_yield(caller, caller->mode);
        break;
    case SYS_GETTICK:
        sys_gettick(caller, &args[1], caller->mode);
        break;
    case SYS_RESET:
        sys_reset(caller, caller->mode);
        break;
    case SYS_SLEEP:
        sys_sleep(caller, &args[1], caller->mode);
        break;
    case SYS_LOCK:
        sys_lock(caller, &args[1], caller->mode);
        break;
    case SYS_CFG: {
        switch (subsyscall) {
            case CFG_GPIO_GET:
                sys_cfg_gpio_get(caller, &args[1], caller->mode);
                break;
            case CFG_GPIO_SET:
                sys_cfg_gpio_set(caller, &args[1], caller->mode);
                break;
            case CFG_GPIO_UNLOCK_EXTI:
                sys_cfg_gpio_unlock_exti(caller, &args[1], caller->mode);
                break;
            case CFG_DMA_RECONF:
                sys_cfg_dma_reconf(caller, &args[1], caller->mode);
                break;
            case CFG_DMA_RELOAD:
                sys_cfg_dma_reload(caller, &args[1], caller->mode);
                break;
            case CFG_DMA_DISABLE:
                sys_cfg_dma_disable(caller, &args[1], caller->mode);
                break;
            case CFG_DEV_MAP:
                sys_cfg_dev_map(caller, &args[1], caller->mode);
                break;
            case CFG_DEV_UNMAP:
                sys_cfg_dev_unmap(caller, &args[1], caller->mode);
                break;
        }
        break;
    }
    default:
        WARN("Unknown syncrhonous syscall %d for task %s\n", syscall, caller->name);
        break;
    }
    return;
}

/*
 * TODO: sched_get_current() and all associated types (caller...) should use task_id.
 * This will ermit to avoid any pointer usage since the task module export enough
 * getters and setters based on the task_id argument.
 *
 * Using that, it is possible to make all syscalls SPARK compatible, in Ada mode,
 * deleting all references to _access variables.
 * The task_t structure should only be visible to the task package itself.
 */
stack_frame_t *svc_handler(stack_frame_t * stack_frame)
{
    task_t     *current_task;
    char       *svcptr = 0;
    svcnum_t    svc = 0;

#ifdef CONFIG_KERNEL_SYSCALLS_WISE_REPARTITION // requied for syscalls in ISR
    bool        wise = true;
#else
    bool        wise = false;
#endif

    current_task = sched_get_current();

    /* Saving context before executing complex content in handler */
    current_task->ctx[current_task->mode].frame = stack_frame;

    svcptr = (char *) stack_frame->pc;
    svc = (uint32_t) svcptr[-2];

    switch (svc) {

    /* Syscall */
    case 0:                    // user syscall
        KERNLOG(DBG_DEBUG, "Syscall SVC from %s\n", current_task->name);

        /*
         * Syscalls execution is usually delayed (managed by the SoftIRQ kernel
         * task).
         * Tasks in ISR mode share the same stack. For that reason, their
         * syscalls can't be delayed ('synchronous' execution).
         */

        if (current_task->mode == TASK_MODE_ISRTHREAD) {
            if (wise && svc_is_synchronous_syscall(current_task)) {
                 svc_synchronous_syscall(current_task);
            } else {
                syscall_r0_update(current_task, TASK_MODE_ISRTHREAD, SYS_E_DENIED);
            }
        } else {
            /* Only some critical syscalls executed synchronously */
            if (wise && svc_is_synchronous_syscall(current_task)) {
                 svc_synchronous_syscall(current_task);
            } else {
                 current_task->state[TASK_MODE_MAINTHREAD] = TASK_STATE_SVC_BLOCKED;
                 softirq_query(SFQ_SYSCALL, current_task->id, 0, 0, 0);
                 task_set_task_state(ID_SOFTIRQ, TASK_MODE_MAINTHREAD, TASK_STATE_RUNNABLE);
                 request_schedule();
            }
        }
        break;

    /* Task done */
    case 1:
        dbg_log("Task %s returns from main(). Set as finished.\n",
                current_task->name);
        dbg_flush();
        current_task->state[TASK_MODE_MAINTHREAD] = TASK_STATE_FINISHED;
        request_schedule();
        break;

    /* ISR done */
    case 2:
        // If the task previously executed yield syscall, it is awoken by the execution by any
        // of its ISR handlers. This change is enough for now, the task electing code will
        // update the task mode to valid context just before its election in handler mode, to avoid
        // any race condition.
        // check if the current ISR requires to force mainthread exec
        if (current_task->ctx[TASK_MODE_ISRTHREAD].irq) {
          switch (current_task->ctx[TASK_MODE_ISRTHREAD].irq->mode) {
#ifdef CONFIG_SCHED_SUPPORT_FISR
            case IRQ_ISR_FORCE_MAINTHREAD:
              //TODO: don't do this for FAULT & FINISHED tasks
              if (current_task->state[TASK_MODE_MAINTHREAD] == TASK_STATE_IDLE ||
                  current_task->state[TASK_MODE_MAINTHREAD] == TASK_STATE_RUNNABLE)
              {
                  current_task->state[TASK_MODE_MAINTHREAD] = TASK_STATE_FORCED;
              }
              break;
#endif
            default:
              break;
          }
        }
        // set ISR thread as done
        current_task->state[TASK_MODE_ISRTHREAD] = TASK_STATE_ISR_DONE;
        request_schedule();
        break;

    default:
        KERNLOG(DBG_ERR,
                "Invalid SVC request %d from %s ! locking task !\n",
                svc, current_task->name);
        dbg_flush();
        current_task->state[TASK_MODE_MAINTHREAD] = TASK_STATE_FAULT;
        request_schedule();
        break;
    }

    return stack_frame;
}
