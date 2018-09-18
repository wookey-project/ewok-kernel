/* syscalls-gettick.c
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
#include "syscalls-gettick.h"
#include "syscalls-utils.h"
#include "sanitize.h"
#include "perm.h"
#include "soc-dwt.h"
#include "m4-core.h"

void sys_gettick(task_t *caller, __user regval_t *regs, e_task_mode mode)
{
    uint64_t           *val   = (uint64_t *) regs[0];
    e_tick_type         prec  = (e_tick_type) regs[1];

    if (!sanitize_is_pointer_in_slot((void *)val, caller->id, mode)) {
        goto ret_inval;
    }

    switch (prec) {
      case PREC_MILLI:
          if (!perm_ressource_is_granted(PERM_RES_TIM_GETMILLI, caller->id)) {
              goto ret_denied;
          }
          *val = core_systick_get_ticks();
          break;
      case PREC_MICRO:
          if (!perm_ressource_is_granted(PERM_RES_TIM_GETMICRO, caller->id)) {
              goto ret_denied;
          }
          *val = soc_dwt_getcycles_64() / MAIN_CLOCK_FREQUENCY_US;
          break;
      case PREC_CYCLE:
          if (!perm_ressource_is_granted(PERM_RES_TIM_GETCYCLE, caller->id)) {
              goto ret_denied;
          }
          *val = soc_dwt_getcycles_64();
          break;
      default:
          goto ret_inval;
    }


    syscall_r0_update(caller, mode, SYS_E_DONE);
    if (mode != TASK_MODE_ISRTHREAD) {
        syscall_set_target_task_runnable(caller);
    }
    return;

 ret_inval:
    syscall_r0_update(caller, mode, SYS_E_INVAL);
    if (mode != TASK_MODE_ISRTHREAD) {
        syscall_set_target_task_runnable(caller);
    }
    return;

 ret_denied:
    syscall_r0_update(caller, mode, SYS_E_DENIED);
    if (mode != TASK_MODE_ISRTHREAD) {
        syscall_set_target_task_runnable(caller);
    }
    return;
}
