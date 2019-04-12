/* syscalls-yield.c
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
#include "default_handlers.h"

/*
 * The task requires to terminate its current execution. The task is set
 * freezed while no IPC targetting it or interrupt already registered by it or is
 * received by the kernel.
 * If such IPC/interrupt arise, the task is set schedulable again and the it is executed
 */
void sys_yield(task_t *caller, e_task_mode mode)
{
    /* an ISR must not yield. There is no logic to that ! */
    if (mode == TASK_MODE_ISRTHREAD) {
        goto ret_denied;
    }
    /*
     * The main() function of the task is now finished. Instead of destroying improperly
     * the task and its stack, this function help it by releasing the processor and giving
     * it back to the kernel
     */
    syscall_r0_update(caller, mode, SYS_E_DONE);
    caller->state[mode] = TASK_STATE_IDLE;
    request_schedule();
    return;
ret_denied:
    syscall_r0_update(caller, mode, SYS_E_DENIED);
    return;
}

