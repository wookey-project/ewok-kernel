/* dma-shared.h
 *
 * Copyright (C) 2018 ANSSI
 * All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the BSD license.  See the LICENSE file for details.
 */

#ifndef DMA_ENUMS_H_
# define DMA_ENUMS_H_

#ifdef CONFIG_KERNEL_DMA_ENABLE

typedef enum {
    ID_DMA_UNUSED = 0,
    ID_DMA1,
    ID_DMA2,
    ID_DMA3,
    ID_DMA4,
    ID_DMA5,
    ID_DMA6,
    ID_DMA7,
    ID_DMA8
} e_dma_id;

/**
 * \brief current dma record status.
 */
typedef enum {
    DMA_UNUSED,

    /**
     * The DMA Steam is just declared but requires sys_ipc(DMA_RECONF) to
     * be operationnal. Only the DMA controller, stream and channel are
     * verified.
     */
    DMA_INITIALIZED,

    /**
     * The DMA stream is already properly set. It is possible to use
     * sys_ipc(DMA_RELOAD) immediatly. The structure fields are all highly
     * tested
     */
    DMA_CONFIGURED
} dma_status_t;

#endif

#endif
