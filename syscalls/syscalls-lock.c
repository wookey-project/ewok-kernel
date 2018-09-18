/* syscalls-lock.c
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

#include "exported/syscalls.h"
#include "syscalls-utils.h"
#include "syscalls-yield.h"
#include "tasks.h"
#include "sched.h"

/*
 * The task requires to lock its ISR execution for a moment, for e.g. while
 * manipulating a specific shared variable for a short time during which a
 * race condition is possible.
 * ISR are not deleted but only postponed, which require the lock to be keeped
 * only for a very short time.
 * This syscall is a complement to the userspace semaphore implementation.
 */
void sys_lock(task_t *caller, __user regval_t *regs, e_task_mode mode)
{
    e_lock_type lockmode = regs[0];

    if (mode == TASK_MODE_ISRTHREAD) {
        goto ret_denied;
    }


    switch (lockmode) {
        case LOCK_ENTER:
            syscall_r0_update(caller, mode, SYS_E_DONE);
            caller->state[mode] = TASK_STATE_LOCKED;
            break;
        case LOCK_EXIT:
            syscall_r0_update(caller, mode, SYS_E_DONE);
            caller->state[mode] = TASK_STATE_RUNNABLE;
            break;
        default:
            goto ret_inval;
            break;
    }

    syscall_r0_update(caller, mode, SYS_E_DONE);
    caller->state[mode] = TASK_STATE_RUNNABLE;
    return;

ret_denied:
    /* ISR mode, state do not need to be updated */
    syscall_r0_update(caller, mode, SYS_E_DENIED);
    return;

ret_inval:
    syscall_r0_update(caller, mode, SYS_E_INVAL);
    caller->state[mode] = TASK_STATE_RUNNABLE;
    return;
}
