/* \file soc-dma.h
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
#ifndef SOC_DMA_H_
#define SOC_DMA_H_

#include "autoconf.h"
#include "types.h"
#include "C/exported/dmas.h"
#include "soc-interrupts.h"

enum dma_controller {
    DMA1 = 1,
    DMA2 = 2
};


typedef enum {
    DMA_INITIALIZE,
    DMA_RECONFIGURE
} dma_config_state_t;



#ifdef CONFIG_KERNEL_DMA_ENABLE
/*
** Only for secure DMA
*/

#define DMA_NB_CONTROLER    2
#define DMA_NB_STREAM		8

void soc_dma_reset(void);

void soc_dma_reset_stream(enum dma_controller ctrl, uint8_t stream);

uint8_t soc_dma_init(enum dma_controller controller,
                     uint8_t stream,
                     dma_t *param);

uint8_t soc_dma_reconf(enum dma_controller controller,
                       uint8_t stream,
                       dma_t *param,
                       dma_config_state_t configstate,
                       uint8_t mask);

void soc_dma_enable(uint8_t controller, uint8_t stream);

void soc_dma_disable(uint8_t controller, uint8_t stream);
#endif
/*
** Bellow functions are for all DMA cases (Secure & Unsecure)
*/

/* Say true if the current irq is a DMA interrupt */
bool soc_is_dma_irq(uint8_t irq);

void soc_dma_clean_int(enum dma_controller ctrl, uint8_t stream);

uint32_t soc_dma_get_status(enum dma_controller ctrl, uint8_t stream);

#ifdef CONFIG_KERNEL_UNSAFE_DMA_ENABLE

uint8_t soc_dma_get_controller(uint8_t irq);

uint8_t soc_dma_get_stream(uint8_t irq);

#endif

#endif /*! SOC_DMA_H_ */
