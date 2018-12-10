/* syscalls-rng.c
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

#include "debug.h"
#include "syscalls.h"
#include "syscalls-utils.h"
#include "syscalls-rng.h"
#include "sanitize.h"
#include "perm.h"
#include "get_random.h"

void sys_get_random(task_t *caller, __user regval_t *regs, e_task_mode mode)
{
    char    *buffer = (char*) regs[0];
    uint16_t length = (uint16_t) regs[1];
    retval_t ret;

    /* Generic sanitation of inputs */
    if (caller->init_done == false) {
        syscall_r0_update(caller, mode, SYS_E_DENIED);
        syscall_set_target_task_runnable(caller);
        return;
    }

    /* Verifying parameters */
    if (!sanitize_is_data_pointer_in_slot
            ((void *)buffer, length, caller->id, mode))
    {
        dbg_log("invalid pointer !!! : %x, size:%d\n", buffer, length);
        goto ret_inval;
    }

    /* buffer for random content should not be bigger than 16 bytes */
    if (length > 16) {
        goto ret_inval;
    }

    /* check for task permissions */
    if (!perm_ressource_is_granted(PERM_RES_TSK_RNG, caller->id)) {
        goto ret_denied;
    }

    ret = get_random((unsigned char*)buffer, length);
    if (ret != SUCCESS) {
        goto ret_busy;
    }

    syscall_r0_update(caller, mode, SYS_E_DONE);
    syscall_set_target_task_runnable(caller);
    return;

ret_busy:
    syscall_r0_update(caller, mode, SYS_E_BUSY);
    syscall_set_target_task_runnable(caller);
    return;

ret_denied:
    syscall_r0_update(caller, mode, SYS_E_DENIED);
    syscall_set_target_task_runnable(caller);
    return;

ret_inval:
    syscall_r0_update(caller, mode, SYS_E_INVAL);
    syscall_set_target_task_runnable(caller);
    return;
}
