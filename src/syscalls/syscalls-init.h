/* syscalls-init.h
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

#ifndef SYSCALLS_INIT
#define SYSCALLS_INIT

#include "kernel.h"
#include "tasks.h"


void init_do_get_taskid(task_t *caller, __user regval_t *regs, e_task_mode mode);

/*
** Userspace task device and handler registration initialization
** and locking
*/
void sys_init(task_t * t, regval_t * regs, e_task_mode mode);

/*
** Also used by kernel to declare its own devices in devices.c. In this case,
** the kernel use DEV_KERNEL as a third argument.
*/
void init_do_reg_devaccess(e_task_id caller_id, __user regval_t *regs, e_task_mode mode);


static void init_do_done(task_t *caller, e_task_mode mode);


#endif /* SYSCALLS_GET_TASKID_ */
