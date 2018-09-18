/* syscalls-cfg.h
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

#ifndef SYSCALLS_CFG_H_
# define SYSCALLS_CFG_H_

#include "syscalls-cfg-mem.h"

/**
 * SYS_CFG syscall dispatcher familly.
 *
 * TODO: this dispatcher, like others, should be deleted to reduce the number
 * of displatching sequence in the SVC/softirq syscalls execution
 */
void sys_cfg(task_t *caller, __user regval_t *regs, e_task_mode mode);

/**
 * \brief Set a given GPIO with a given value
 *
 * The value is normailzed in the function.
 *
 * \param[in/out] caller the task requesting the GPIO set
 * \param[in]     regs   user params, containing the value to set
 *
 */
void sys_cfg_gpio_set(task_t *caller, __user regval_t *regs, e_task_mode mode);

/**
 * \brief Get the current GPIO value
 *
 * \param[in/out] caller the caller requesting the GPIO
 * \param[out]    regs   user params, containing the user pointer to set 
 */
void sys_cfg_gpio_get(task_t *caller, __user regval_t *regs, e_task_mode mode);


#endif /*!SYSCALLS_CFG_H_*/
