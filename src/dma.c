/* dma.c
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
anit*/

#include "dma.h"
#include "soc-nvic.h"
#include "soc-dma.h"
#include "kernel.h"
#include "debug.h"
#include "autoconf.h"
#include "sanitize.h"
#include "libc.h"
#include "devmap.h"
#include "tasks.h"

#ifdef CONFIG_KERNEL_DMA_ENABLE
/* Ewok support up to 16 declared DMA streams at a time */
#define MAX_DMAS 8

static k_dma_t dma_tab[MAX_DMAS];
uint8_t num_dmas = ID_DMA1;

static e_dma_id dma_get_dma_slot(void)
{
    if (num_dmas < MAX_DMAS) {
        return num_dmas++;
    }
    return 0;
}

bool dma_same_dma_stream_channel (e_dma_id id, const dma_t *dma)
{
    return (dma->dma     == dma_tab[id].udma.dma    &&
            dma->stream  == dma_tab[id].udma.stream &&
            dma->channel == dma_tab[id].udma.channel);
}

/**
 * \brief check if there is no previously registered dma collisioning
 *
 * A DMA controller can serve only one configuration per controller/stream
 * pair, whatever the channel is.
 *
 * \param[in] dma the current requested dma information
 *
 * \return true if the requested dma is free to use
 */
bool dma_stream_is_already_registered(const __user dma_t *dma)
{
    for (uint8_t id = ID_DMA1; id < num_dmas; id++) {
        if (dma->dma     == dma_tab[id].udma.dma    &&
            dma->stream  == dma_tab[id].udma.stream)
        {
            KERNLOG(DBG_ERR, "dma %d stream %d channel %d is already registered!\n", dma->dma, dma->stream, dma->channel);
            return true;
        }
    }
    return false;
}

/**
 * \brief load the DMA channel specified by its kernel identifier
 */
void dma_enable_dma_stream(e_dma_id dma_id) // FIXME - rename
{
    if (dma_tab[dma_id].status == DMA_CONFIGURED) {
        soc_dma_enable(dma_tab[dma_id].udma.dma, dma_tab[dma_id].udma.stream);
    }
}

/**
 * \brief disable the DMA channel specified by its kernel identifier
 */
void dma_disable_dma_stream(e_dma_id dma_id)
{
    if (dma_tab[dma_id].status == DMA_CONFIGURED) {
        soc_dma_disable(dma_tab[dma_id].udma.dma, dma_tab[dma_id].udma.stream);
    }

}

/***********************************************************
 * Kernel main syscalls control-flow related function
 ***********************************************************/

/*
** Return true if all necessary fields are set in order to make the DMA
** works without risk. the enable bit can be set.
*/
static bool dma_is_complete_dma(dma_t * dma)
{
    if (dma->in_addr == 0   ||
        dma->out_addr == 0  ||
        dma->size == 0      ||
        (dma->dir == MEMORY_TO_PERIPHERAL && dma->in_handler == 0) ||
        (dma->dir == PERIPHERAL_TO_MEMORY && dma->out_handler == 0))
    {
        return false;
    } else {
        return true;
    }
}

uint32_t  ts0, ts1, ts2, ts3, ts4, ts5, ts6 = 0;

/**
 * \brief reconfigure a previously declared DMA stream
 *
 * This function reconfigure fields of a previously declared DMA stream of
 * the caller task, using the mask argument. Authorized fields are the
 * ones described in the dma_reconf_mask_t.
 *
 * \param[in/out] dma the user-provided new DMA configuration. May be
 *                    incomplete, reduced to the DMA fields to reconfigure
 * \param[in/out] kdma the kernel dma structure to update
 * \param[in]     mask the reconfiguration mask provided by the user
 * \param[in]     caller the task requesting the reconfiguration
 * \param[in]     mode task mode at syscall time (main thread or ISR thread)
 *
 * \return 0 if the reconfiguration succeeded, or 1 if an invalid value has
 *    been found.
 */
uint8_t dma_reconf_dma(__user dma_t *dma,
                       e_dma_id     dma_id,
                       uint8_t      mask,
                       e_task_id    caller)
{
    /*
     * Sanitizing buffer require the correct buffer size. If not set in
     * the user-provided structure, the previous size (hosted in the kdma_t
     * structure will be used. We update the dma_t structure with the good
     * size before sanitation to permit a correct buffers boundcheck
     */
    if (!(mask & DMA_RECONF_BUFSIZE)) {
        dma->size = dma_tab[dma_id].udma.size;
    }

    /*
     * Now that we have checked the user structure, we can reconfigure
     * the kernel structure with the user-provided fields, using the
     * user-provided mask
     */
    /* Update DMA direction (PERIPHERAL_TO_MEMORY, MEMORY_TO_PERIPHERAL...) */
    if (mask & DMA_RECONF_DIR) {
        dma_tab[dma_id].udma.dir = dma->dir;
    }

    /* Update buffer size if requested */
    if (mask & DMA_RECONF_BUFSIZE) {
        dma_tab[dma_id].udma.size = dma->size;
    }

    /* Update input buffer if requested */
    if (mask & DMA_RECONF_BUFIN) {
        dma_tab[dma_id].udma.in_addr = dma->in_addr;
    }

    /* Update output buffer if requested */
    if (mask & DMA_RECONF_BUFOUT) {
        dma_tab[dma_id].udma.out_addr = dma->out_addr;
    }

    /* Update DMA stream mode (direct/FIFO/... if requested */
    if (mask & DMA_RECONF_MODE) {
        dma_tab[dma_id].udma.mode = dma->mode;
    }

    /* Update DMA stream priority if requested */
    if (mask & DMA_RECONF_PRIO) {
        switch (dma->dir) {
        case MEMORY_TO_PERIPHERAL:
            dma_tab[dma_id].udma.in_prio = dma->in_prio;
            break;
        case PERIPHERAL_TO_MEMORY:
            dma_tab[dma_id].udma.out_prio = dma->out_prio;
            break;
        default:
            break;
        }
    }

    /* Update DMA ISR handlers if requested */
    if (mask & DMA_RECONF_HANDLERS) {
        switch (dma->dir) {
        case MEMORY_TO_PERIPHERAL:
            dma_tab[dma_id].udma.in_handler = dma->in_handler;
            set_interrupt_handler(dma_tab[dma_id].devinfo->irq[0],
                            dma->in_handler, caller, ID_DEV_UNUSED);
            break;
        case PERIPHERAL_TO_MEMORY:
            dma_tab[dma_id].udma.out_handler = dma->out_handler;
            set_interrupt_handler(dma_tab[dma_id].devinfo->irq[0],
                            dma->out_handler, caller, ID_DEV_UNUSED);
            break;
        default:
            break;
        }
    }

    soc_dma_reconf(dma_tab[dma_id].udma.dma, dma_tab[dma_id].udma.stream,
        &dma_tab[dma_id].udma, DMA_RECONFIGURE, mask);

    /*
     * To finish, we have to check if the completed DMA structure has all
     * needed informations to permit DMA stream activation. If not, the
     * kernel waits for another DMA reconfiguration.
     */
    if (dma_is_complete_dma(&dma_tab[dma_id].udma)) {
        dma_tab[dma_id].status = DMA_CONFIGURED;
        soc_dma_enable(dma_tab[dma_id].udma.dma, dma_tab[dma_id].udma.stream);
    }
    ts6 = soc_dwt_getcycles();
    return 0;

}

/**
 * \brief sanitize the user-specified DMA structure
 *
 * If the mask is null, all user fields are checked for invalid
 * content (addresses, size, etc.). This is the case for initial
 * dma configuration.
 *
 * If the mask is non-null, it is considered as a dma_reconf_mode_t
 * enumerate and is used as is to detect which field has to be sanitized.
 * This is the case for DMA reconfiguration.
 *
 * \param[in] dma the user-specified structure
 * \param[in] task the task requesting the DMA
 * \param[in] mask the field mask to limit the sanitation. 0 means no limit
 * \param[in] mode task mode at syscall time (main thread or ISR thread)
 *
 * \return 0 if the structure is good, or non-zero
 */
uint8_t dma_sanitize_dma(dma_t      *dma,
                         e_task_id   caller,
                         uint8_t     mask,
                         e_task_mode mode)
{
    /********************************************
     * Sanitize for DMA declaration
     ********************************************/
    if (mask == 0) {
        mask = 255; /* set all configurable field enabled */
    }

    if (mask == 255) {
        if (dma->stream >= DMA_NB_STREAM) {
            KERNLOG(DBG_ERR, "%s: dma stream %d invalid\n", task_get_name(caller), dma->stream);
            goto ret_inval;
        }
        if (dma->dma > DMA_NB_CONTROLER) {
            KERNLOG(DBG_ERR, "%s: dma controller %d invalid\n", task_get_name(caller), dma->dma);
            goto ret_inval;
        }
    }


    /*************************************************
     * Sanitize for DMA declaration & reconfiguration
     *************************************************/

    /* Buffer size */
    if (mask & DMA_RECONF_BUFSIZE) {
    }

    /* Direction */
    if (mask & DMA_RECONF_DIR) {
        if (   dma->dir != PERIPHERAL_TO_MEMORY
            && dma->dir != MEMORY_TO_PERIPHERAL)
        {
           KERNLOG(DBG_ERR, "%s: dma direction %x invalid\n", task_get_name(caller), dma->dir);
           KERNLOG(DBG_ERR, "dma direction MEMORY_TO_MEMORY is forbidden by now\n");
           goto ret_inval;
        }
    }

    /* Input Buffer */
    if (mask & DMA_RECONF_BUFIN) {
        if ((dma->dir != PERIPHERAL_TO_MEMORY)) {
            if (!(   sanitize_is_data_pointer_in_any_slot((void *)dma->in_addr, dma->size, caller, mode)
                  || sanitize_is_data_pointer_in_dma_shm((void *)dma->in_addr, dma->size, DMA_SHM_ACCESS_RD, caller)
                  || (dma->in_addr == 0) /* bufin not initialized */))
            {
                KERNLOG(DBG_ERR, "%s: dma input buf %x invalid\n", task_get_name(caller), dma->in_addr);
                goto ret_inval;
            }
        }
    }

    /* Security TODO: Buffers in peripherals (in for PERIPHERAL_TO_MEMORY, out for MEMORY_TO_PERIPHERAL) should
     * be mapped in the task's list of devices memories. Add a generic sanitize for _is_in_mapped_devices() */

    /* Output Buffer */
    if (mask & DMA_RECONF_BUFOUT) {
        if ((dma->dir != MEMORY_TO_PERIPHERAL)) {
            if (!(   sanitize_is_data_pointer_in_slot((void *)dma->out_addr, dma->size, caller, mode)
                  || sanitize_is_data_pointer_in_dma_shm((void *)dma->out_addr, dma->size, DMA_SHM_ACCESS_WR, caller)
                  || (dma->out_addr == 0) /* bufout not initialized */))
            {
                KERNLOG(DBG_ERR, "%s: dma output buf %x invalid\n", task_get_name(caller), dma->out_addr);
                goto ret_inval;
            }
        }
    }

    /* DMA ISR handlers */
    if (mask & DMA_RECONF_HANDLERS) {
        switch (dma->dir) {
        case MEMORY_TO_PERIPHERAL:
            if (!(   sanitize_is_pointer_in_txt_slot((void *)dma->in_handler, caller)
                  || (dma->in_handler == 0)))
            {
                KERNLOG(DBG_ERR, "%s: dma in handler %x invalid\n", task_get_name(caller), dma->in_handler);
                goto ret_inval;
            }
            break;
        case PERIPHERAL_TO_MEMORY:
            if (!(   sanitize_is_pointer_in_txt_slot((void *)dma->out_handler, caller)
                  || (dma->in_handler == 0)))
            {
                KERNLOG(DBG_ERR, "%s: dma out handler %x invalid\n", task_get_name(caller), dma->out_handler);
                goto ret_inval;
            }
            break;
        default:
            break;
        }
    }

    /* End of sanitation */
    return 0;

 ret_inval:
    return 1;
}

/**
 * \brief Initialize the DMA controller
 *
 * The DMA controller is configured but not enabled.
 *
 * \param[in] dma  the task's kernel dma structure
 * \param[in] caller the task requesting the init
 * \param[in] dma structure kernel identifier
 *
 * \return 0.
 */
uint8_t dma_init_dma(__user dma_t  *dma,
                     e_task_id      caller,
                     e_dma_id      *id)
{
    e_dma_id dma_id  = 0;

    dma_id = dma_get_dma_slot();
    if (!dma_id) {
        goto ret_busy;
    }

    // and duplicate in kernel
    memcpy(&dma_tab[dma_id], dma, sizeof(dma_t));
    const struct device_soc_infos *devinfo = soc_devices_get_dma(dma->dma, dma->stream);
    dma_tab[dma_id].task    = caller;
    dma_tab[dma_id].status  = DMA_INITIALIZED;
    dma_tab[dma_id].devinfo = devinfo;

    // registering IRQ handler FIXME: check between in or out
    switch (dma_tab[dma_id].udma.dir) {
    case MEMORY_TO_PERIPHERAL:
        set_interrupt_handler
            (dma_tab[dma_id].devinfo->irq[0], dma_tab[dma_id].udma.in_handler,
                caller, ID_DEV_UNUSED);
        break;
    case PERIPHERAL_TO_MEMORY:
        set_interrupt_handler
            (dma_tab[dma_id].devinfo->irq[0], dma_tab[dma_id].udma.out_handler,
                caller, ID_DEV_UNUSED);
        break;
    case MEMORY_TO_MEMORY:
        // TODO...
        break;
    }

    set_reg_bits(dma_tab[dma_id].devinfo->rcc_enr, dma_tab[dma_id].devinfo->rcc_enb);
    soc_dma_init(dma_tab[dma_id].udma.dma, dma_tab[dma_id].udma.stream, &dma_tab[dma_id].udma);
    *id = dma_id;
    return 0;

ret_busy:
    return 1;
}

/**
 * \brief Enable the DMA IRQ line.
 *
 * Enable CEN bit of DMA stream CR register & TCIE/HTIE/TEIE/DMEIE bits are
 * volunaty set by IPC_DMA_RECONF/RELOAD syscall. This permit to wait for a
 * potential other task to initialize a device (e.g. CRYP) before starting
 * the DMA. This make the userspace task mastering the DMA start time.
 *
 * \param[in] dma the kernel dma structure to enable.
 *
 * \return 0.
 */
uint8_t dma_enable_dma_irq(e_dma_id dma)
{
    /* activate IRQ line for stream */
    NVIC_EnableIRQ((uint32_t) dma_tab[dma].devinfo->irq[0] - 0x10);    /* minus core interrupts */
    KERNLOG(DBG_INFO, "Enabled IRQ %x, for device %s\n",
            dma_tab[dma].devinfo->irq[0] - 16, dma_tab[dma].devinfo->name);
       return 0;
}



/****************************************************
 * Kernel DMA module init
 ***************************************************/

/**
 * \brief Kernel DMA subsystem init
 *
 * Enable the clock input of the DMA controllers.
 */
void dma_init(void)
{
    const struct device_soc_infos *devinfo;

    // Activate RCC input for DMA1 & 2.
    devinfo = soc_devices_get_dma(1, 0);
    set_reg_bits(devinfo->rcc_enr, devinfo->rcc_enb);
    devinfo = soc_devices_get_dma(2, 0);
    set_reg_bits(devinfo->rcc_enr, devinfo->rcc_enb);
    /* full DMA reset (all controllers) */
    soc_dma_reset();
}

/****************************************************
 * Kernel internal utility function
 ***************************************************/

/**
 * \brief clean the pending interrupt in the DMA controller
 *
 * This is not a NVIC-level cleaning here, but a SR cleaning
 *
 * \param [in] calller the task associated to the IRQ
 * \param [in] irq the IRQ number as managed in soc-interrupts.h
 *
 */
void dma_clean_int(const e_task_id caller, uint8_t irq)
{
    k_dma_t *kdma;
    task_t  *caller_task = task_get_task(caller);

    for (uint8_t i = 0; i < caller_task->num_dmas; ++i) {
        kdma = &dma_tab[caller_task->dma[i]];
        if (kdma->devinfo->irq[0] == irq) {
            soc_dma_clean_int(kdma->udma.dma, kdma->udma.stream);
            break;
        }
    }
}

/**
 * \brief return the DMA status register of the given controller
 *
 * \param [in] calller the task associated to the IRQ
 * \param [in] irq the IRQ number as managed in soc-irq.h
 *
 */
uint32_t dma_get_status(e_task_id caller, uint8_t irq) // FIXME - irq or interrupt ?
{
    k_dma_t *kdma;
    uint32_t status = 0;
    task_t  *caller_task = task_get_task(caller);

    for (uint8_t i = 0; i < caller_task->num_dmas; ++i) {
        kdma = &dma_tab[caller_task->dma[i]];   // FIXME
        if (kdma->devinfo->irq[0] == irq) {        // FIXME
            status = soc_dma_get_status(kdma->udma.dma, kdma->udma.stream);
            break;
        }
    }
    return status;
}

/*********************************************************
 * DMA SHM related
 ********************************************************/

/**
 * \brief check the dma_shm_t user-provided content
 *
 * \return 0 if structure is clean, or 1 if invalid.
 */
uint8_t dma_shm_sanitize(dma_shm_t *dmashm, e_task_id caller, e_task_mode mode)
{
    /* target doesn't exist or is not a user task ? */
    if (!task_is_user(dmashm->target)) {
        KERNLOG(DBG_ERR, "Invalid task %d declaring DMA SHM\n", caller);
        return 1;
    }

    /* The user application has tried to spoof its own identifier */
    if (dmashm->source != caller) {
        KERNLOG(DBG_ERR,
            "DMA SHM source identifier is not own by caller task %d\n",
            caller);
        return 1;
    }

#ifdef CONFIG_KERNEL_DOMAIN
    /* if target is not in the same domain, return inval instead of
       denied to avoid giving some hint to the task about other domains's
       tasks id.
     */
    if (!perm_same_ipc_domain(dmashm->target, caller)) {
        KERNLOG(DBG_ERR,
            "DMA SHM target %d doesn't exist or is not in the same IPC domain\n",
            dmashm->target);
        return 1;
    }
#endif

    /* check region address and size */
    if (!sanitize_is_data_pointer_in_slot((void*)dmashm->address, dmashm->size, caller, mode) &&
        !sanitize_is_pointer_in_devices_slot((void*)dmashm->address, dmashm->size, caller)) {
        KERNLOG(DBG_ERR,
            "DMA SHM buffer %x is not owned by the declaring task\n",
            dmashm->address);
        return 1;
    }

    return 0;
}

#endif
