/* \file syscalls-dma.c
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

#include "debug.h"
#include "devices.h"
#include "devices-shared.h"
#include "dma.h"
#include "sanitize.h"
#include "perm.h"
#include "libc.h"

#include "syscalls.h"
#include "syscalls-utils.h"
#include "syscalls-dma.h"

void init_do_reg_dma(task_t *caller, __user regval_t *regs, e_task_mode mode)
{
#ifdef CONFIG_KERNEL_DMA_ENABLE
    __user dma_t   *dma = (dma_t *) regs[1];
    int            *descriptor = (int*) regs[2];
    e_dma_id        dma_id = 0;
    uint8_t         ret;

    /* Generic sanitation of inputs */
    if (!sanitize_is_data_pointer_in_slot
            ((void *)dma, sizeof(dma_t), caller->id, mode))
    {
        goto ret_inval;
    }

    if (!sanitize_is_pointer_in_slot ((void *)descriptor, caller->id, mode)) {
        goto ret_inval;
    }

    /* Is DMA allowed ? */
    if (!perm_ressource_is_granted(PERM_RES_DEV_DMA, caller->id)) {
        goto ret_denied;
    }

    /* check user content  */
    ret = dma_sanitize_dma(dma, caller->id, (uint8_t)0, mode);
    if (ret == 1) {
        goto ret_inval;
    }

    if (ret == 2) {
        goto ret_denied;
    }

    /* Check if Controller/Stream couple is already registered */
    if(dma_stream_is_already_registered(dma)) {
        goto ret_busy;
    }

    /* Does any user descriptor is available ?*/
    if (caller->num_dmas >= MAX_DMAS_PER_TASK) {
        goto ret_busy;
    }

    /* Initialization */
    ret = dma_init_dma(dma, caller->id, &dma_id);
    if (ret != 0) {
        goto ret_inval;
    }

    caller->dma[caller->num_dmas] = dma_id;
    *descriptor = (int) caller->num_dmas;
    caller->num_dmas++;

    syscall_r0_update(caller, mode, SYS_E_DONE);
    syscall_set_target_task_runnable(caller);
    return;

 ret_inval:
    *descriptor = -1;
    syscall_r0_update(caller, mode, SYS_E_INVAL);
    syscall_set_target_task_runnable(caller);
    return;

 ret_busy:
    *descriptor = -1;
    syscall_r0_update(caller, mode, SYS_E_BUSY);
    syscall_set_target_task_runnable(caller);
    return;

 ret_denied:
    *descriptor = -1;
    syscall_r0_update(caller, mode, SYS_E_DENIED);
    syscall_set_target_task_runnable(caller);
    return;

#else
    KERNLOG(DBG_INFO, "DMA not activated at config time\n");
    regs = regs;
    syscall_r0_update(caller, mode, SYS_E_DENIED);
    syscall_set_target_task_runnable(caller);
    return;
#endif
}

/*
** syscall handling DMA SHM declaration between tasks
*/
void init_do_reg_dma_shm(task_t *caller, __user regval_t *regs, e_task_mode mode)
{
#ifdef CONFIG_KERNEL_DMA_ENABLE
    __user dma_shm_t *dma_shm = (dma_shm_t *)regs[1];
    uint8_t ret;
    task_t *target_task = 0;

    /* Generic sanitation of inputs */
    if (!sanitize_is_data_pointer_in_slot((void *)dma_shm, sizeof(dma_shm_t), caller->id, mode)) {
        goto ret_inval;
    }
    /* end of generic sanitation */
    /* check user content  */
    ret = dma_shm_sanitize(dma_shm, caller->id, mode);
    if (ret == 1) {
        goto ret_inval;
    }

    /***********************
     * Verifying permissions
     ***********************/
    if (!perm_dmashm_is_granted(caller->id, dma_shm->target)) {
        goto ret_denied;
    }

    /* still place in the target task ? */
    target_task = task_get_task(dma_shm->target);
    /* target_task is non-null because task_is_user() didn't fail */

    if (target_task->num_dma_shms == MAX_DMA_SHM_PER_TASK) {
        goto ret_busy;
    }

    /* copy the SHM information into the target task */
    memcpy(&target_task->dma_shm[target_task->num_dma_shms++], dma_shm, sizeof(dma_shm_t));

    KERNLOG(DBG_INFO, "DMA SHM has been declared by %s with %s (access mode %d)\n", caller->name, target_task->name, dma_shm->mode);

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
#else
    KERNLOG(DBG_INFO, "DMA not activated at config time\n");
    regs = regs;
    syscall_r0_update(caller, mode, SYS_E_DENIED);
    syscall_set_target_task_runnable(caller);
    return;
#endif
}


/*
 * Reconfigure the DMA. A fully configure dma_t structure must be given.
 */
void sys_cfg_dma_reconf(task_t *caller, __user regval_t *regs, e_task_mode mode)
{
#ifdef CONFIG_KERNEL_DMA_ENABLE
    uint8_t     ret = 1;
    dma_t      *dma = (dma_t *) regs[1];
    uint8_t     reconfmask = (uint8_t)regs[2];
    int         desc = (int) regs[3];

    /* Generic sanitation of inputs */
    if (!sanitize_is_data_pointer_in_slot
           ((void *)dma, sizeof(dma_t), caller->id, mode)) {
        goto ret_inval;
    }

    /* The DMA user descriptor must be already defined in the task */
    if (desc < 0 || desc > (int) caller->num_dmas - 1) {
        goto ret_inval;
    }

    /* The DMA ctrl/channel/stream must be the same */
    if (!dma_same_dma_stream_channel (caller->dma[desc], dma)) {
        goto ret_inval;
    }

    /* check user content  */
    ret = dma_sanitize_dma(dma, caller->id, (uint8_t)0, mode); // FIXME - reconfmask must be used
    if (ret != 0) {
        goto ret_inval;
    }

    ret = dma_reconf_dma(dma, caller->dma[desc], reconfmask, caller->id);
    if (ret != 0) {
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
#else
    KERNLOG(DBG_INFO, "DMA not activated at config time\n");
    regs = regs;
    syscall_r0_update(caller, mode, SYS_E_DENIED);
    syscall_set_target_task_runnable(caller);
    return;
#endif
}

/*
** Reload the DMA. Just set CR register CEN bit to 1 for the the given
** DMA if the task already owns it.
*/
void sys_cfg_dma_reload(task_t *caller, __user regval_t *regs, e_task_mode mode)
{
#ifdef CONFIG_KERNEL_DMA_ENABLE
    uint8_t     ret = 1;
    int         desc = (int) regs[1];

    /* The DMA user descriptor must be already defined in the task */
    if (desc < 0 || desc > (int) caller->num_dmas - 1) {
        goto ret_inval;
    }

    dma_enable_dma_stream(caller->dma[desc]);
    ret = 0;

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
#else
    KERNLOG(DBG_INFO, "DMA not activated at config time\n");
    regs = regs;
    syscall_r0_update(caller, mode, SYS_E_DENIED);
    syscall_set_target_task_runnable(caller);
    return;
#endif

}

/*
** Reset the DMA Stream. DMA is then disable. It can be reenable by
** IPC_DMA_RECONF syscall.
*/
void sys_cfg_dma_disable(task_t *caller, __user regval_t *regs, e_task_mode mode)
{
#ifdef CONFIG_KERNEL_DMA_ENABLE
    uint8_t  ret = 1;
    int      desc = (int) regs[1];

    /* The DMA user descriptor must be already defined in the task */
    if (desc < 0 || desc > (int) caller->num_dmas - 1) {
        goto ret_inval;
    }

    dma_disable_dma_stream(caller->dma[desc]);
    ret = 0;

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
#else
    KERNLOG(DBG_INFO, "DMA not activated at config time\n");
    regs = regs;
    syscall_r0_update(caller, mode, SYS_E_DENIED);
    syscall_set_target_task_runnable(caller);
    return;
#endif
}
