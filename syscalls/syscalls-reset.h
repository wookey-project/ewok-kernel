/* syscalls-reset.h
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

#ifndef SYSCALLS_RESET
# define SYSCALLS_RESET

#include "tasks.h"
#include "types.h"



/*
 * The task requires to reset the board.
 * This happends when detecting invalid/dangerous behaviors requiring
 * fast reaction from the device. This syscall is associated to a specific
 * permission.
 */
void sys_reset(task_t *caller, e_task_mode mode);

#endif/*!SYSCALLS_RESET*/
