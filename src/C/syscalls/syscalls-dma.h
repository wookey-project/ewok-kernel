/* syscalls-dma.h
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
#ifndef SYSCALLS_DMA_H_
# define SYSCALLS_DMA_H_

#include "tasks.h"
#include "types.h"

/*
 * If KERNEL_DMA is disable, all these syscalls will return SYS_E_DENIED to
 * the userspace, with a kernel log indicating that the kernel DMA support
 * is not included.
 */

void init_do_reg_dma(task_t *caller, __user regval_t *regs, e_task_mode mode);

void init_do_reg_dma_shm(task_t *caller, __user regval_t *regs, e_task_mode mode);

void sys_cfg_dma_reconf(task_t *caller, __user regval_t *regs, e_task_mode mode);

void sys_cfg_dma_reload(task_t *caller, __user regval_t *regs, e_task_mode mode);

void sys_cfg_dma_disable(task_t *caller, __user regval_t *regs, e_task_mode mode);


#endif /*!SYSCALLS_DMA_H_*/
