/* syscalls-rng.h
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

#ifndef SYSCALLS_RNG
# define SYSCALLS_RNG

#include "syscalls-utils.h"
#include "tasks.h"
#include "types.h"

/*
 * The task requires to get back a random content from the kernel in order
 * to generate entropy.
 * This random content can be True random (if a TRNG source exists on the
 * hardware platform) or pseudo-random content. Check the corresponding
 * SoC BSP implementation for more information about the SoC-specific RNG
 * source.
 * This syscall is associated to a specific permission, RES_TSK_RNG, in order
 * to avoid over-usage of entropy source (mostly for pseudorandom sources)
 * which may lead to more predictible content.
 */
void sys_get_random(task_t *caller, __user regval_t *regs, e_task_mode mode);

#endif/*!SYSCALLS_RNG*/
