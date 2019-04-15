/* \file syscalls-utils.h
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

#ifndef SYSCALLS_UTILS_H
# define SYSCALLS_UTILS_H

#include "exported/syscalls.h"
#include "tasks.h"

/*
 * This function update the target task's state.
 *
 * CAUTION !
 * - Target task might currently be in ISR mode (state ==
 *   TASK_STATE_RUNNABLE or state == TASK_STATE_ISR_DONE). In theory, it's state should
 *   not be updated. But as it will be automatically set as runnable by the
 *   scheduler when returning in THREAD mode, it causes no problem.
 */
static inline void syscall_set_target_task_runnable (task_t *target)
{
    if (target->state[TASK_MODE_MAINTHREAD] == TASK_STATE_SVC_BLOCKED ||
        target->state[TASK_MODE_MAINTHREAD] == TASK_STATE_IDLE) {
        target->state[TASK_MODE_MAINTHREAD] = TASK_STATE_RUNNABLE;
    }
}

#ifdef CONFIG_SCHED_SUPPORT_FIPC
static inline void syscall_set_target_task_forced (task_t * t)
{
    if (t->state[TASK_MODE_MAINTHREAD] == TASK_STATE_RUNNABLE ||
        t->state[TASK_MODE_MAINTHREAD] == TASK_STATE_IDLE) {
        t->state[TASK_MODE_MAINTHREAD] = TASK_STATE_FORCED;
    }

}
#endif

/*
** Update the user r0 register for syscall return value
*/
static inline void syscall_r0_update(task_t * t, e_task_mode mode, e_syscall_ret val)
{
    /* This task (or any of its handlers) should not be executed while 
     ** updating the return value. It is, as softirq_syscall_handler deactivate
     ** irq by now. */
    t->ctx[mode].frame->r0 = val;
}

#endif
