/* syscalls-reset.c
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
#include "syscalls-reset.h"
#include "perm.h"
#include "tasks.h"
#include "soc-nvic.h"

void sys_reset(task_t *caller, e_task_mode mode)
{
    if (!perm_ressource_is_granted(PERM_RES_TSK_RESET, caller->id)) {
        goto ret_denied;
    }
    NVIC_SystemReset();
ret_denied:
    syscall_r0_update(caller, mode, SYS_E_DENIED);
    syscall_set_target_task_runnable(caller);
    return;
}
