/* syscalls-sleep.c
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
#include "syscalls-sleep.h"
#include "perm.h"
#include "tasks.h"
#include "sleep.h"
#include "sanitize.h"
#include "sched.h"

void sys_sleep(task_t *caller, __user regval_t *regs, e_task_mode mode)
{
    /* ISRs can't sleep */
    if (mode == TASK_MODE_ISRTHREAD) {
        goto ret_denied;
    }
    uint32_t            sleeptime = (uint32_t)        regs[0];
    sleep_mode_t        sleepmode = (sleep_mode_t)    regs[1];

    sleeping(caller->id, sleeptime, sleepmode); 

    /* Set caller as SLEEPING */
    syscall_r0_update(caller, mode, SYS_E_DONE);
    task_set_task_state(caller->id, mode, TASK_STATE_SLEEPING);
    /* request schedule, as current task is no more executable */
    request_schedule();
    return;

ret_denied:
    syscall_r0_update(caller, mode, SYS_E_DENIED);
    if (mode != TASK_MODE_ISRTHREAD) {
        syscall_set_target_task_runnable(caller);
    }
    return;
}
