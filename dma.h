/* \file dma.h
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

#ifndef DMA_H
#define DMA_H

/**
 * \file dma
 *
 * \brief this is the kernel, arch-generic support for secure DMA
 *
 * This file declare the kernel internal API for secure DMA API. This file
 * exports types and prototypes only if CONFIG_KERNEL_DMA_ENABLE is set in
 * kernel Kconfig.
 *
 */

#include "types.h"
#include "exported/dmas.h"
#include "tasks.h"
#include "dma-shared.h"
#include "autoconf.h"

#ifdef CONFIG_KERNEL_DMA_ENABLE

/**
 * \brief kernel DMA record, containing the user-configured DMA record
 *
 * In order to keep kernel-specific metadata internals, the kernel use
 * this structure in union with dma_t user-specified structure.
 * This permit to expose the dma_t structure in the exported/dma.h header
 * and keep the complete dma kernel structure here.
 * the dma_t structure is keeped as a udma param in the k_dma_t
 * structure
 */
typedef struct {
        dma_t        udma;
        e_task_id    task;
        dma_status_t status;
        const struct device_soc_infos *devinfo;
} k_dma_t;

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
 *
 * \return 0 if the structure is good, or non-zero
 */
uint8_t dma_sanitize_dma(dma_t      *dma,
                         e_task_id   caller,
                         uint8_t     mask,
                         e_task_mode mode);

/**
 * \brief Initialize the DMA controller
 *
 * The DMA is configured but *not* enabled. Enabling the DMA (i.e. starting
 * a memory copy) is a voluntary configuration action from the task.
 *
 * \param[in] dma the user DMA structure
 * \param[in] task the task requesting the DMA
 * \param[out] DMA handle identifier
 *
 * \return 0 if the DMA is configured properly, or non-zero
 */
uint8_t dma_init_dma(dma_t        *dma,
                     e_task_id     task,
                     e_dma_id     *id);


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
 *
 * \return 0 if the reconfiguration succeeded, or 1 if an invalid value has
 *    been found.
 */
uint8_t dma_reconf_dma(__user dma_t     *dma,
                              e_dma_id   dma_id,
                              uint8_t    mask,
                              e_task_id  caller);

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
uint8_t dma_enable_dma_irq(e_dma_id dma);

/**
 * \brief Kernel DMA subsystem init
 *
 * Enable the clock input of the DMA controllers.
 */
void dma_init(void);

/**
 * \brief return the DMA status register of the given controller
 *
 * \param [in] calller the task associated to the IRQ
 * \param [in] irq the IRQ number as managed in soc-interrupts.h
 *
 */
uint32_t dma_get_status(e_task_id caller, uint8_t irq);

/**
 * \brief clean the pending interrupt in the DMA controller
 *
 * This is not a NVIC-level cleaning here, but a SR cleaning
 *
 * \param [in] calller the task associated to the IRQ
 * \param [in] irq the IRQ number as managed in soc-irq.h
 *
 */
void dma_clean_int(e_task_id caller, uint8_t irq);

/**
 * \brief check the dma_shm_t user-provided content
 *
 * \return 0 if structure is clean, or 1 if invalid.
 */
uint8_t dma_shm_sanitize(dma_shm_t *dmashm, e_task_id caller, e_task_mode mode);

/*
 * \return true if the dma config and the related dma_tab[id] share the same dma/stream/channel
 */
bool dma_same_dma_stream_channel (e_dma_id id, const dma_t *dma);

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
bool dma_stream_is_already_registered(const __user dma_t *dma);

/**
 * \brief load the DMA channel specified by its kernel identifier
 */
void dma_enable_dma_stream(e_dma_id dma_id);

/**
 * \brief disable the DMA channel specified by its kernel identifier
 */
void dma_disable_dma_stream(e_dma_id dma_id);


bool dma_is_complete_dma(e_dma_id dma_id);

#endif
#endif
