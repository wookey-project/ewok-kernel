/* syscalls-cfg.c
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

#include "autoconf.h"
#include "libc.h"
#include "tasks.h"
#include "sched.h"
#include "debug.h"
#include "softirq.h"
#include "soc-interrupts.h"
#include "soc-devmap.h"
#include "devices.h"
#include "devices-shared.h"
#include "mpu.h"
#include "gpio.h"
#include "apps_layout.h"
#include "syscalls-dma.h"
#include "sanitize.h"

#ifdef CONFIG_ARCH_ARMV7M
#include "m4-core.h"
#else
#error "undefined core header for this arch!"
#endif

#include "syscalls.h"
#include "syscalls-utils.h"
#include "syscalls-cfg.h"
#include "syscalls-cfg-gpio.h"
#include "syscalls-cfg-mem.h"



#ifdef CONFIG_KERNEL_DMA_ENABLE
/****************************
* DMA sys_cfg sycalls familly
*****************************/



#endif



/*
** CFG type to define, please use register based, not buffer based to
** set type and content (r1, r2, r3, r4... r1 = target, r2 = ipctype, r3 = ipc arg1...)
*/
void sys_cfg(task_t *caller, __user regval_t *regs, e_task_mode mode)
{
    uint32_t type = regs[0];
    // check that msg toward msg+size is in task's data section.
    switch (type) {
    case CFG_GPIO_SET:
        KERNLOG(DBG_DEBUG, "[syscall][cfg][task %s] gpio set\n", caller->name);
        sys_cfg_gpio_set(caller, regs, mode);
        break;
    case CFG_GPIO_GET:
        KERNLOG(DBG_DEBUG, "[syscall][cfg][task %s] gpio get\n", caller->name);
        sys_cfg_gpio_get(caller, regs, mode);
        break;
    case CFG_GPIO_UNLOCK_EXTI:
        KERNLOG(DBG_DEBUG, "[syscall][cfg][task %s] gpio exti unlock\n", caller->name);
        sys_cfg_gpio_unlock_exti(caller, regs, mode);
        break;
#ifdef CONFIG_KERNEL_DMA_ENABLE
    case CFG_DMA_RECONF:
        KERNLOG(DBG_DEBUG, "[syscall][cfg][task %s] dma reconf\n", caller->name);
        sys_cfg_dma_reconf(caller, regs, mode);
        break;
    case CFG_DMA_RELOAD:
        KERNLOG(DBG_DEBUG, "[syscall][cfg][task %s] dma reload\n", caller->name);
        sys_cfg_dma_reload(caller, regs, mode);
        break;
    case CFG_DMA_DISABLE:
        KERNLOG(DBG_DEBUG, "[syscall][cfg][task %s] dma disable\n", caller->name);
        sys_cfg_dma_disable(caller, regs, mode);
        break;

#endif
    case CFG_DEV_MAP:
        KERNLOG(DBG_DEBUG, "[syscall][cfg][task %s] device map\n", caller->name);
        sys_cfg_dev_map(caller, regs, mode);
        break;
    case CFG_DEV_UNMAP:
        KERNLOG(DBG_DEBUG, "[syscall][cfg][task %s] device unmap\n", caller->name);
        sys_cfg_dev_unmap(caller, regs, mode);
        break;
    default:
        KERNLOG(DBG_DEBUG, "[syscall][cfg][task %s] invalid!!\n", caller->name);
        syscall_r0_update(caller, mode, SYS_E_INVAL);
        syscall_set_target_task_runnable(caller);
        break;
    }
    return;
}

