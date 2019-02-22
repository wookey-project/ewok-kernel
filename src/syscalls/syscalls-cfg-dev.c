/* \file syscalls-cfg-mem.c
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
#include "syscalls-cfg-dev.h"
#include "devices.h"
#include "sched.h"
#include "debug.h"
#include "default_handlers.h"

void sys_cfg_dev_map(task_t *caller, __user regval_t *regs, e_task_mode mode)
{
    uint8_t     user_dev_id = (uint8_t) regs[1];
    device_t   *dev = 0;
    e_device_id dev_id;

    if (user_dev_id >= caller->num_devs ) {
        KERNLOG(DBG_ERR,
            "[task %d] sys_cfg(CFG_DEV_MAP): invalid descriptor\n", caller->id);
        goto ret_denied;
    }

    dev_id = caller->dev_id[user_dev_id];

    /* forbidden from ISR... */
    if (mode == TASK_MODE_ISRTHREAD) {
        KERNLOG(DBG_ERR,
            "[task %d] sys_cfg(CFG_DEV_MAP): not allowed in SR mode\n", caller->id);
        goto ret_denied;
    }

    /* Should be out of initialization sequence */
    if (caller->init_done == false) {
        KERNLOG(DBG_ERR,
            "[task %d] sys_cfg(CFG_DEV_MAP): not allowed before end of init\n", caller->id);
        goto ret_denied;
        return;
    }

    /* check that the device is owned by the task */
    if (!(dev_get_task_from_id(dev_id) == caller->id)) {
        KERNLOG(DBG_ERR,
            "[task %d] sys_cfg(CFG_DEV_MAP): device not owned by the task\n", caller->id);
        /* no 'DENIED' to avoid detecting which devid is owned by other tasks */
        goto ret_inval;
        return;
    }

    dev = dev_get_device_from_id(dev_id);
    if (dev->map_mode != DEV_MAP_VOLUNTARY) {
        KERNLOG(DBG_ERR,
            "[task %d] sys_cfg(CFG_DEV_MAP): not a DEV_MAP_VOLUNTARY device\n", caller->id);
        /* DEV_MAP_AUTO devices can't be (un)mapped */
        goto ret_denied;
    }

    if (dev_is_mapped(dev_id)) {
        KERNLOG(DBG_ERR,
            "[task %d] sys_cfg(CFG_DEV_MAP): device is already mapped\n", caller->id);
        /* already mapped... */
        goto ret_busy;
    }

    /*
     * As the device may have never been mapped (and activated) we activate
     * its clock here
     */
    dev_enable_device(dev_id);

    /* Okay now map the device */
    if (dev_set_device_map(true, dev_id) == FAILURE) {
        /* max mapped devices already reached ! */
        KERNLOG(DBG_ERR,
            "[task %d] sys_cfg(CFG_DEV_MAP): unable to map device !\n", caller->id);
        goto ret_busy;
    }
    // FIXME: the number of mapped device should be increased in the task_t struct (num_devs_mmaped

    syscall_r0_update(caller, mode, SYS_E_DONE);
    syscall_set_target_task_runnable(caller);
    request_schedule();
    return;


ret_busy:
    syscall_r0_update(caller, mode, SYS_E_BUSY);
    syscall_set_target_task_runnable(caller);
    return;

ret_denied:
    syscall_r0_update(caller, mode, SYS_E_DENIED);
    syscall_set_target_task_runnable(caller);
    return;

ret_inval:
    syscall_r0_update(caller, mode, SYS_E_INVAL);
    syscall_set_target_task_runnable(caller);
    return;


}

void sys_cfg_dev_unmap(task_t *caller, __user regval_t *regs, e_task_mode mode)
{
    uint8_t     user_dev_id = (uint8_t) regs[1];
    device_t   *dev = 0;
    e_device_id dev_id;

    if (user_dev_id >= caller->num_devs ) {
        KERNLOG(DBG_ERR,
            "[task %d] sys_cfg(CFG_DEV_MAP): invalid descriptor\n", caller->id);
        goto ret_denied;
    }

    dev_id = caller->dev_id[user_dev_id];

    /* forbidden from ISR... */
    if (mode == TASK_MODE_ISRTHREAD) {
        KERNLOG(DBG_ERR,
            "[task %d] sys_cfg(CFG_DEV_UNMAP): not allowed in SR mode\n", caller->id);
        goto ret_denied;
    }

    /* Should be out of initialization sequence */
    if (caller->init_done == false) {
        KERNLOG(DBG_ERR,
            "[task %d] sys_cfg(CFG_DEV_UNMAP): not allowed before end of init\n", caller->id);
        goto ret_denied;
        return;
    }

    /* check that the device is owned by the task */
    if (!(dev_get_task_from_id(dev_id) == caller->id)) {
        /* no 'DENIED' to avoid detecting which dev_id is owned by other tasks */
        KERNLOG(DBG_ERR,
            "[task %d] sys_cfg(CFG_DEV_UNMAP): device not owned by the task\n", caller->id);
        goto ret_inval;
        return;
    }

    if (!dev_is_mapped(dev_id)) {
        /* not already mapped...  */
        goto ret_inval;
    }
    dev = dev_get_device_from_id(dev_id);
    if (dev->map_mode != DEV_MAP_VOLUNTARY) {
        KERNLOG(DBG_ERR,
            "[task %d] sys_cfg(CFG_DEV_UNMAP): not a DEV_MAP_VOLUNTARY device\n", caller->id);
        /* DEV_MAP_AUTO devices can't be (un)mapped */
        goto ret_denied;
    }

    /* Okay now unmap the device. If already unmapped, nothing is done */
    dev_set_device_map(false, dev_id);

    syscall_r0_update(caller, mode, SYS_E_DONE);
    syscall_set_target_task_runnable(caller);
    request_schedule();
    return;

ret_inval:
    syscall_r0_update(caller, mode, SYS_E_INVAL);
    syscall_set_target_task_runnable(caller);
    return;

ret_denied:
    syscall_r0_update(caller, mode, SYS_E_DENIED);
    syscall_set_target_task_runnable(caller);
    return;

}

void sys_cfg_dev_release(task_t *caller, __user regval_t *regs, e_task_mode mode)
{
    uint8_t     user_dev_id = (uint8_t) regs[1];
    e_device_id dev_id;

    if (user_dev_id >= caller->num_devs ) {
        KERNLOG(DBG_ERR,
            "[task %d] sys_cfg(CFG_DEV_MAP): invalid descriptor\n", caller->id);
        goto ret_denied;
    }

    dev_id = caller->dev_id[user_dev_id];

    /* forbidden from ISR... */
    if (mode == TASK_MODE_ISRTHREAD) {
        KERNLOG(DBG_ERR,
            "[task %d] sys_cfg(CFG_DEV_UNMAP): not allowed in SR mode\n", caller->id);
        goto ret_denied;
    }

    /* Should be out of initialization sequence */
    if (caller->init_done == false) {
        KERNLOG(DBG_ERR,
            "[task %d] sys_cfg(CFG_DEV_UNMAP): not allowed before end of init\n", caller->id);
        goto ret_denied;
        return;
    }

    /* check that the device is owned by the task */
    if (!(dev_get_task_from_id(dev_id) == caller->id)) {
        /* no 'DENIED' to avoid detecting which dev_id is owned by other tasks */
        KERNLOG(DBG_ERR,
            "[task %d] sys_cfg(CFG_DEV_UNMAP): device not owned by the task\n", caller->id);
        goto ret_inval;
    }

    if (dev_is_mapped(dev_id)) {
        dev_set_device_map(false, dev_id);
    }

    if (dev_disable_device(caller->id, dev_id)) {
        /* FIXME: there should be a fallback mechanism here */
        goto ret_inval;
    }

    syscall_r0_update(caller, mode, SYS_E_DONE);
    syscall_set_target_task_runnable(caller);
    /* C implementation of the MPU request schedule (Ada does not) */
    request_schedule();
    return;

ret_inval:
    syscall_r0_update(caller, mode, SYS_E_INVAL);
    syscall_set_target_task_runnable(caller);
    return;

ret_denied:
    syscall_r0_update(caller, mode, SYS_E_DENIED);
    syscall_set_target_task_runnable(caller);
    return;

}
