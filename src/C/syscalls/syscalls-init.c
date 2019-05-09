/* \file syscalls-init.c
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

#include "syscalls-init.h"
#include "exported/syscalls.h"
#include "syscalls-utils.h"
#include "sanitize.h"
#include "perm.h"
#include "libc.h"
#include "sched.h"
#include "debug.h"
#include "softirq.h"
#include "soc-interrupts.h"
#include "devmap.h"
#include "devices.h"
#include "devices-shared.h"
#include "mpu.h"
#include "gpio.h"
#include "apps_layout.h"
#include "syscalls-dma.h"
#include "dma.h"
#include "sanitize.h"
#include "default_handlers.h"


void init_do_get_taskid(task_t *caller, __user regval_t *regs, e_task_mode mode)
{
    const char *task_name = (const char *)regs[1];
    uint32_t   *id = (uint32_t *) regs[2];
    task_t     *tasks_list = NULL;

    /* Generic sanitation of inputs */
    // TODO: there is a security risk here: as there is no string size, we can't check
    // that the string is fully in the task's slot. This means that this is possible to
    // get back the value of the first bytes of the data of the next task, up to the
    // max task name's size (fixed max size is 16 bytes). Here I only check that there is
    // at least 4 bytes of string in the slot (3 chars length string).

    //if (!sanitize_is_pointer_in_slot((void*)task_name, t->id)) {
    //  goto ret_inval;
    //}

    if (!sanitize_is_pointer_in_slot((void *)id, caller->id, mode)) {
        goto ret_inval;
    }

    /* End of generic sanitation */
    if (caller->init_done == true) {
        goto ret_denied;
    }

    tasks_list = task_get_tasks_list();

    for (e_task_id peer = ID_APP1; peer <= ID_APPMAX; ++peer) {
        if (strcasecmp(task_name, tasks_list[peer].name) == 0) {
#ifdef CONFIG_KERNEL_DOMAIN
            /* Checking domain */
            if (!perm_same_ipc_domain(caller->id, peer)) {
                goto ret_inval;
            }
#endif
           if (perm_ipc_is_granted(caller->id, peer) ||
               perm_ipc_is_granted(peer, caller->id)) {
               *id = peer;
               goto done;
           }
           /* for DMASHM grant check, the dmashm initiator is
            * the only one requiring the target task id */
           if (perm_dmashm_is_granted(caller->id, peer)) {
               *id = peer;
               goto done;
           }

        }
    }

 ret_inval:
    syscall_r0_update(caller, mode, SYS_E_INVAL);
    syscall_set_target_task_runnable(caller);
    return;

 ret_denied:
    syscall_r0_update(caller, TASK_MODE_MAINTHREAD, SYS_E_DENIED);
    caller->state[TASK_MODE_MAINTHREAD] = TASK_STATE_RUNNABLE;
    return;

 done:
    syscall_r0_update(caller, mode, SYS_E_DONE);
    syscall_set_target_task_runnable(caller);
    return;
}


void init_do_reg_devaccess(e_task_id caller_id, __user regval_t *regs, e_task_mode mode)
{
    /*
     * User defined device struct 'udev' has two roles:
     * - it is used by a user task to register and to configure a new device
     *   in the kernel
     * - the kernel uses it to return some informations to the user task
     */
    __user device_t    *udev = (device_t *) regs[1];
    __user int         *descriptor = (int*) regs[2];

    e_device_id         device_id;
    uint8_t             ret;
    task_t             *caller;

    caller = task_get_task(caller_id);
    if (caller == NULL) {
        panic("init_do_reg_devaccess(): invalid task id %d\n", caller_id);
    }

    if (task_is_user(caller_id)) {
        /* Generic sanitation of inputs */
        if (!sanitize_is_data_pointer_in_slot((void *)udev, sizeof(device_t), caller->id, mode) &&
            !sanitize_is_data_pointer_in_txt_slot((void *)udev, sizeof(device_t), caller->id)) {
            KERNLOG(DBG_ERR, "invalid pointer given in argument\n");
            goto ret_inval;
        }

        if (!sanitize_is_pointer_in_slot ((void *)descriptor, caller->id, mode))
        {
            goto ret_inval;
        }


        /* Check user content  */
        ret = dev_sanitize_user_device(udev, caller->id);
        if (ret != SUCCESS) {
            KERNLOG(DBG_ERR, "invalid device datas or permission is denied\n");
            goto ret_denied;
        }
    } else {
        if (!udev || !descriptor) {
            goto ret_inval;
        }
    }

    /* Enough place */
    if (udev->size != 0 &&
        udev->map_mode == DEV_MAP_AUTO &&
        caller->num_devs_mmapped >= MPU_MAX_EMPTY_REGIONS)
    {
        KERNLOG(DBG_ERR, "No more free space in task for device\n");
        goto ret_busy;
    }

    /*
     * Register a user device
     */

    device_id = dev_get_free_device_slot(caller_id, udev);
    if (device_id == ID_DEV_UNUSED) {
        KERNLOG(DBG_ERR, "No more free space in kernel for device\n");
        dbg_flush();
        goto ret_busy;
    }
    if (caller->num_devs == (MAX_DEVS_PER_TASK - 1)) {
        KERNLOG(DBG_ERR, "No more free space in task context for device\n");
        dbg_flush();
        goto ret_busy;
    }

    caller->dev_id[caller->num_devs] = device_id;

    if (udev->size != 0 && udev->map_mode == DEV_MAP_AUTO) {
        caller->num_devs_mmapped++;
    }

    /* Identifier to transmit to userspace */
    *descriptor = caller->num_devs;

    caller->num_devs++;

    ret = dev_register_gpios(device_id, caller_id);
    if (ret == 1) {
        KERNLOG(DBG_ERR, "[%s] init_do_reg_devaccess() failed\n", caller->name);
        dev_release_device_slot (device_id);
        caller->num_devs--;
        caller->dev_id[caller->num_devs] = ID_DEV_UNUSED;
        goto ret_inval;
    }
    if (ret == 2) {
        KERNLOG(DBG_ERR, "[%s] init_do_reg_devaccess() failed\n", caller->name);
        dev_release_device_slot (device_id);
        caller->num_devs--;
        caller->dev_id[caller->num_devs] = ID_DEV_UNUSED;
        goto ret_busy;
    }

    ret = dev_register_handlers(device_id, caller_id);
    if (ret != 0) {
        dev_release_device_slot (device_id);
        caller->num_devs--;
        caller->dev_id[caller->num_devs] = ID_DEV_UNUSED;
        goto ret_inval;
    }

    /*
     * Finalize device registration and return some device informations to the
     * user task via 'udev' struct
     */
    ret = dev_register_device(device_id, udev);
    if (ret != 0) {
        dev_release_device_slot (device_id);
        caller->num_devs--;
        caller->dev_id[caller->num_devs] = ID_DEV_UNUSED;
        goto ret_busy;
    }

    syscall_r0_update(caller, mode, SYS_E_DONE);
    syscall_set_target_task_runnable(caller);
    return;

 ret_inval:
    syscall_r0_update(caller, mode, SYS_E_INVAL);
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
}


static void init_do_done(task_t *caller, e_task_mode mode)
{
    // activate all devices
    for (uint8_t i = 0; i < caller->num_devs; ++i) {
        device_t *dev = dev_get_device_from_id(caller->dev_id[i]);
        /*
         * We enable only MAP_AUTO devices. MAP_VOLUNTARY devices
         * will be enabled during their first sys_cfg(CFG_MAP) call
         */
        if (dev->map_mode == DEV_MAP_AUTO) {
          dev_enable_device(caller->dev_id[i]);
        }
    }

#if CONFIG_KERNEL_DMA_ENABLE
    for (uint8_t i = 0; i < caller->num_dmas; ++i) {
        dma_enable_dma_irq(caller->dma[i]);
    }
#endif

    caller->init_done = true;
    syscall_r0_update(caller, mode, SYS_E_DONE);
    syscall_set_target_task_runnable(caller);
    /* init_done always request a scheduling to make devices mapped
     * at next execution time of the task
     */
    request_schedule();
}

/*
** Initialize the userspace task device and handler access. Also lock initialize sequence.
*/
void sys_init(task_t *caller, __user regval_t *regs, e_task_mode mode)
{
    regval_t type = regs[0];

    // sanitation
    // check that msg toward msg+size is in task's data section.
    if (caller->init_done == true) {
        syscall_r0_update(caller, mode, SYS_E_DENIED);
        caller->state[mode] = TASK_STATE_RUNNABLE;
        return;
    }

    switch (type) {
    case INIT_DEVACCESS:
        init_do_reg_devaccess(caller->id, regs, mode);
        break;
#ifdef CONFIG_KERNEL_DMA_ENABLE
    case INIT_DMA:
        init_do_reg_dma(caller, regs, mode);
        break;
    case INIT_DMA_SHM:
        init_do_reg_dma_shm(caller, regs, mode);
        break;
#endif
    case INIT_GETTASKID:
        init_do_get_taskid(caller, regs, mode);
        break;
    case INIT_DONE:
        init_do_done(caller, mode);
        break;
    default:
        syscall_r0_update(caller, mode, SYS_E_INVAL);
        syscall_set_target_task_runnable(caller);
        break;
    }
    return;
}

