/* \file syscalls.h
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

#ifndef SYSCALLS_H_
#define SYSCALLS_H_

#include "types.h"
#include "syscalls-utils.h"
#include "exported/syscalls.h"
#include "autoconf.h"
#include "tasks.h"
#include "devices.h"

/* including all syscalls header */
#include "syscalls-yield.h"
#include "syscalls-sleep.h"
#include "syscalls-reset.h"
#include "syscalls-gettick.h"
#include "syscalls-lock.h"
#include "syscalls-init.h"
#include "syscalls-log.h"

/*
** IPC type to define, please use register based, not buffer based to
** set type and content (r1, r2, r3, r4... r1 = target, r2 = ipctype, r3 = ipc arg1...)
*/
void sys_ipc(task_t * t, regval_t * regs, e_task_mode mode);

void sys_cfg(task_t *caller, __user regval_t *regs, e_task_mode mode);

#endif
