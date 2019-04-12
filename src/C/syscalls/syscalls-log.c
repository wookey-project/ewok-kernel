/* \file syscalls-log.c
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
#include "syscalls.h"
#include "tasks.h"
#include "sanitize.h"
#include "debug.h"

void sys_log (task_t *caller, __user regval_t *regs, e_task_mode mode)
{
    uint32_t size = regs[0];
    uint32_t msg = regs[1];

    /* Is the message in the task address space? */
    if (!sanitize_is_data_pointer_in_slot((void*)msg, size, caller->id, mode)) {
        goto ret_inval;
    }

    if (size >= 512) {
        goto ret_inval;
    }

    dbg_log("[%s] ", caller->name);
    dbg_log((char*)msg);
    dbg_flush();

    syscall_r0_update(caller, mode, SYS_E_DONE);
    syscall_set_target_task_runnable(caller);
    return;

 ret_inval:
    syscall_r0_update(caller, mode, SYS_E_INVAL);
    syscall_set_target_task_runnable(caller);
    return;
}
