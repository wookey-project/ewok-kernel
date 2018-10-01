/* \file soc-dma.c
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
#include "soc-dma.h"
#include "soc-dma_regs.h"
#include "debug.h"


// TODO: for memory_to_peripheral and peripheral to memory, out/in addr should
// be controlled by the kernel, the userland should only be able to set an
// offset in a controlled memory area of the device

#ifdef CONFIG_KERNEL_DMA_ENABLE
void soc_dma_reset_stream(enum dma_controller ctrl, uint8_t stream)
{
    soc_dma_disable(ctrl, stream);
    if (stream < 4) {
        set_reg_bits(r_CORTEX_M_DMA_LIFCR(ctrl), DMA_LIFCR_CFEIFx_Msk(stream));
        set_reg_bits(r_CORTEX_M_DMA_LIFCR(ctrl), DMA_LIFCR_CDMEIFx_Msk(stream));
        set_reg_bits(r_CORTEX_M_DMA_LIFCR(ctrl), DMA_LIFCR_CTEIFx_Msk(stream));
        set_reg_bits(r_CORTEX_M_DMA_LIFCR(ctrl), DMA_LIFCR_CHTIFx_Msk(stream));
        set_reg_bits(r_CORTEX_M_DMA_LIFCR(ctrl), DMA_LIFCR_CTCIFx_Msk(stream));
    } else {
        set_reg_bits(r_CORTEX_M_DMA_HIFCR(ctrl), DMA_HIFCR_CFEIFx_Msk(stream));
        set_reg_bits(r_CORTEX_M_DMA_HIFCR(ctrl), DMA_HIFCR_CDMEIFx_Msk(stream));
        set_reg_bits(r_CORTEX_M_DMA_HIFCR(ctrl), DMA_HIFCR_CTEIFx_Msk(stream));
        set_reg_bits(r_CORTEX_M_DMA_HIFCR(ctrl), DMA_HIFCR_CHTIFx_Msk(stream));
        set_reg_bits(r_CORTEX_M_DMA_HIFCR(ctrl), DMA_HIFCR_CTCIFx_Msk(stream));
    }

    write_reg_value(r_CORTEX_M_DMA_SxCR(ctrl, stream), 0);
    while (get_reg(r_CORTEX_M_DMA_SxCR(ctrl, stream), DMA_SxCR_EN)) {
        continue;
    }
    write_reg_value(r_CORTEX_M_DMA_SxNDTR(ctrl, stream), 0);
    write_reg_value(r_CORTEX_M_DMA_SxPAR(ctrl, stream), 0);
    write_reg_value(r_CORTEX_M_DMA_SxM0AR(ctrl, stream), 0);
    write_reg_value(r_CORTEX_M_DMA_SxM1AR(ctrl, stream), 0);
    write_reg_value(r_CORTEX_M_DMA_SxFCR(ctrl, stream), 0x21);
}

static void soc_dma_set_addresses(enum dma_controller ctrl,
                                  uint8_t stream, dma_t *param,
                                  uint8_t mask)
{
    if (mask & DMA_RECONF_DIR) {
        set_reg(r_CORTEX_M_DMA_SxCR(ctrl, stream), param->dir, DMA_SxCR_DIR);
    }

    if (param->dir == PERIPHERAL_TO_MEMORY || param->dir == MEMORY_TO_MEMORY) {
        if (mask & DMA_RECONF_BUFIN) {
            set_reg(r_CORTEX_M_DMA_SxPAR(ctrl, stream),
                    (uint32_t) param->in_addr, DMA_SxPAR_PAR);
        }
        if (mask & DMA_RECONF_BUFOUT) {
            set_reg(r_CORTEX_M_DMA_SxM0AR(ctrl, stream),
                    (uint32_t) param->out_addr, DMA_SxM0AR_M0A);
        }
    } else {
        if (mask & DMA_RECONF_BUFIN) {
            set_reg(r_CORTEX_M_DMA_SxM0AR(ctrl, stream),
                    (uint32_t) param->in_addr, DMA_SxM0AR_M0A);
        }
        if (mask & DMA_RECONF_BUFOUT) {
            set_reg(r_CORTEX_M_DMA_SxPAR(ctrl, stream),
                    (uint32_t) param->out_addr, DMA_SxPAR_PAR);

        }
    }
}

static void soc_dma_set_configuration(enum dma_controller ctrl,
                                      uint8_t stream,
                                      dma_t*  param,
                                      dma_config_state_t configstate,
                                      uint8_t mask)
{
    if (configstate == DMA_INITIALIZE) {
        set_reg(r_CORTEX_M_DMA_SxCR(ctrl, stream), param->channel, DMA_SxCR_CHSEL);
        set_reg(r_CORTEX_M_DMA_SxCR(ctrl, stream), param->mem_burst,
                DMA_SxCR_MBURST);
        set_reg(r_CORTEX_M_DMA_SxCR(ctrl, stream), param->dev_burst,
                DMA_SxCR_PBURST);

        clear_reg_bits(r_CORTEX_M_DMA_SxCR(ctrl, stream), DMA_SxCR_CT_Msk);
        clear_reg_bits(r_CORTEX_M_DMA_SxCR(ctrl, stream), DMA_SxCR_DBM_Msk);
    }

    if (mask & DMA_RECONF_PRIO) {
        if (param->dir == (uint8_t) PERIPHERAL_TO_MEMORY) {
          set_reg(r_CORTEX_M_DMA_SxCR(ctrl, stream), param->out_prio, DMA_SxCR_PL);
        } else {
          set_reg(r_CORTEX_M_DMA_SxCR(ctrl, stream), param->in_prio, DMA_SxCR_PL);
        }
    }
    if (configstate == DMA_INITIALIZE) {
        clear_reg_bits(r_CORTEX_M_DMA_SxCR(ctrl, stream), DMA_SxCR_PINCOS_Msk);

        set_reg(r_CORTEX_M_DMA_SxCR(ctrl, stream), param->datasize,
                DMA_SxCR_MSIZE);
        set_reg(r_CORTEX_M_DMA_SxCR(ctrl, stream), param->datasize,
                DMA_SxCR_PSIZE);
        if (param->mem_inc) {
            set_reg(r_CORTEX_M_DMA_SxCR(ctrl, stream),
                    DMA_SxCR_MINC_ADDR_INCREMENTED, DMA_SxCR_MINC);
        } else {
            set_reg(r_CORTEX_M_DMA_SxCR(ctrl, stream),
                    DMA_SxCR_MINC_ADDR_FIXED, DMA_SxCR_MINC);
        }
        if (param->dev_inc) {
            set_reg(r_CORTEX_M_DMA_SxCR(ctrl, stream),
                    DMA_SxCR_PINC_ADDR_INCREMENTED, DMA_SxCR_PINC);
        } else {
            set_reg(r_CORTEX_M_DMA_SxCR(ctrl, stream),
                    DMA_SxCR_PINC_ADDR_FIXED, DMA_SxCR_PINC);
        }
        clear_reg_bits(r_CORTEX_M_DMA_SxCR(ctrl, stream), DMA_SxCR_CIRC_Msk);
        if (param->flow_control) {
            set_reg(r_CORTEX_M_DMA_SxCR(ctrl, stream),
                    DMA_SxCR_PFCTRL_PERIPH_FLOW_CONTROLLER, DMA_SxCR_PFCTRL);
        } else {
            set_reg(r_CORTEX_M_DMA_SxCR(ctrl, stream),
                    DMA_SxCR_PFCTRL_DMA_FLOW_CONTROLLER, DMA_SxCR_PFCTRL);
        }
    }
}


uint8_t soc_dma_reconf(enum dma_controller controller,
                       uint8_t stream,
                       dma_t *param,
                       dma_config_state_t configstate,
                       uint8_t mask)
{
    uint32_t size = 0;
    /*
     * In Direct mode, item size in the DMA bufsize register is 
     * calculated using the datasize unit, in FIFO/Circular mode,
     * the increment is in bytes, and the size must stay in bytes too
     */
    if (param->mode == DMA_DIRECT_MODE) {
        switch (param->datasize) {
            case DMA_DS_WORD:
                size = param->size >> 2; // FIXME /
                break;
            case DMA_DS_HALFWORD:
                size = param->size >> 1; // FIXME /
                break;
            default:
                size = param->size;
        }
    } else {
        size = param->size;
    }

    soc_dma_disable(controller, stream);

    soc_dma_set_addresses(controller, stream, param, mask);
    soc_dma_set_configuration(controller, stream, param, configstate, mask);
    /* interrupts have already been declared by the caller */

    if (configstate == DMA_INITIALIZE) {
        set_reg_bits(r_CORTEX_M_DMA_SxCR(controller, stream), DMA_SxCR_TCIE_Msk
                | DMA_SxCR_HTIE_Msk | DMA_SxCR_TEIE_Msk | DMA_SxCR_DMEIE_Msk);
    }
    if (param->flow_control != DMA_FLOWCTRL_DEV) { // FIXME == DMA_FLOWCTRL_DMA
        set_reg(r_CORTEX_M_DMA_SxNDTR(controller, stream), size, DMA_SxNDTR_NDT);
    }
    if (mask & DMA_RECONF_MODE) {
        if (param->mode & DMA_FIFO_MODE) {
            /* FIFO mode instead of direct mode */
            set_reg_bits(r_CORTEX_M_DMA_SxFCR(controller, stream),
                    DMA_SxFCR_FEIE_Msk | DMA_SxFCR_DMDIS_Msk);
            set_reg(r_CORTEX_M_DMA_SxFCR(controller, stream),
                    DMA_SxFCR_FTH_FULL, DMA_SxFCR_FTH);
        } else {
            clear_reg_bits(r_CORTEX_M_DMA_SxFCR(controller, stream),
                    DMA_SxFCR_FEIE_Msk);
        }

        if (param->mode & DMA_CIRCULAR_MODE) {
            if (param->dir == MEMORY_TO_MEMORY) {
                dbg_log("DMA%x Circular mode forbidden\n", controller);
            } else {
                set_reg_bits(r_CORTEX_M_DMA_SxCR(controller, stream),
                        DMA_SxCR_CIRC_Msk);
            }
        }
        /*
         * activating IT... is made by userspace. This action depends on when the
         * userspace want to be awoken by a DMA event.
         * This example make the usespae being awoken in all various cases (same IRQ)
         */
        if (param->mode & DMA_DIRECT_MODE) {
            set_reg_bits(r_CORTEX_M_DMA_SxCR(controller, stream), DMA_SxCR_TCIE_Msk
                    | DMA_SxCR_TEIE_Msk | DMA_SxCR_DMEIE_Msk);
        } else if (param->mode & DMA_FIFO_MODE) {
            set_reg_bits(r_CORTEX_M_DMA_SxCR(controller, stream), DMA_SxCR_TCIE_Msk
                    | DMA_SxCR_TEIE_Msk);
        } else {
            set_reg_bits(r_CORTEX_M_DMA_SxCR(controller, stream), DMA_SxCR_TCIE_Msk
                    | DMA_SxCR_TEIE_Msk);
        }
    }

     return 0;
}

uint8_t soc_dma_init(enum dma_controller controller,
                     uint8_t stream,
                     dma_t *param)
{
    soc_dma_reset_stream(controller, stream);
    soc_dma_reconf(controller, stream, param, DMA_INITIALIZE, 0xff);

    return 0;
}

/* should be a userspace  function */
void soc_dma_enable(uint8_t controller, uint8_t stream)
{
    DEBUG(DBG_DEBUG, "Enabling DMA Stream %x, controller %x\n", stream,
          controller);
    set_reg_bits(r_CORTEX_M_DMA_SxCR(controller, stream), DMA_SxCR_EN_Msk);
}

void soc_dma_disable(uint8_t controller, uint8_t stream)
{
    DEBUG(DBG_DEBUG, "Disabling DMA Stream %x, controller %x\n", stream,
          controller);
    clear_reg_bits(r_CORTEX_M_DMA_SxCR(controller, stream), DMA_SxCR_EN_Msk);
}


void soc_dma_reset(void)
{
    for (enum dma_controller i = DMA1; i <= DMA2; ++i) {
        for (uint8_t j = 0; j < DMA_NB_STREAM; ++j) {
            soc_dma_reset_stream(i, j);
        }
    }
}

#endif

bool soc_is_dma_irq(uint8_t irq)
{
    bool ret = false;
    if (irq >= DMA1_Stream0_IRQ && irq <= DMA1_Stream6_IRQ) {
        ret = true;
    }
    if (irq == DMA1_Stream7_IRQ) {
        ret = true;
    }
    if (irq >= DMA2_Stream0_IRQ && irq <= DMA2_Stream4_IRQ) {
        ret = true;
    }
    if (irq >= DMA2_Stream5_IRQ && irq <= DMA2_Stream7_IRQ) {
        ret = true;
    }
    return ret;
}

void soc_dma_clean_int(enum dma_controller ctrl, uint8_t stream)
{
    if (stream < 4) {
        if (get_reg(r_CORTEX_M_DMA_SxFCR(ctrl, stream), DMA_SxFCR_FEIE)
            && get_reg_value(r_CORTEX_M_DMA_LISR(ctrl),
                             DMA_LISR_FEIFx_Msk(stream),
                             DMA_LISR_FEIFx_Pos(stream))) {
            set_reg_bits(r_CORTEX_M_DMA_LIFCR(ctrl),
                         DMA_LIFCR_CFEIFx_Msk(stream));
        }
        if (get_reg(r_CORTEX_M_DMA_SxCR(ctrl, stream), DMA_SxCR_DMEIE)
            && get_reg_value(r_CORTEX_M_DMA_LISR(ctrl),
                             DMA_LISR_DMEIFx_Msk(stream),
                             DMA_LISR_DMEIFx_Pos(stream))) {
            set_reg_bits(r_CORTEX_M_DMA_LIFCR(ctrl),
                         DMA_LIFCR_CDMEIFx_Msk(stream));
        }
        if (get_reg(r_CORTEX_M_DMA_SxCR(ctrl, stream), DMA_SxCR_TEIE) &&
            get_reg_value(r_CORTEX_M_DMA_LISR(ctrl),
                          DMA_LISR_TEIFx_Msk(stream),
                          DMA_LISR_TEIFx_Pos(stream))) {
            set_reg_bits(r_CORTEX_M_DMA_LIFCR(ctrl),
                         DMA_LIFCR_CTEIFx_Msk(stream));
        }
        if (get_reg(r_CORTEX_M_DMA_SxCR(ctrl, stream), DMA_SxCR_HTIE) &&
            get_reg_value(r_CORTEX_M_DMA_LISR(ctrl),
                          DMA_LISR_HTIFx_Msk(stream),
                          DMA_LISR_HTIFx_Pos(stream))) {
            set_reg_bits(r_CORTEX_M_DMA_LIFCR(ctrl),
                         DMA_LIFCR_CHTIFx_Msk(stream));
        }
        if (get_reg(r_CORTEX_M_DMA_SxCR(ctrl, stream), DMA_SxCR_TCIE) &&
            get_reg_value(r_CORTEX_M_DMA_LISR(ctrl),
                          DMA_LISR_TCIFx_Msk(stream),
                          DMA_LISR_TCIFx_Pos(stream))) {
            set_reg_bits(r_CORTEX_M_DMA_LIFCR(ctrl),
                         DMA_LIFCR_CTCIFx_Msk(stream));
        }
    } else {
        if (get_reg(r_CORTEX_M_DMA_SxFCR(ctrl, stream), DMA_SxFCR_FEIE)
            && get_reg_value(r_CORTEX_M_DMA_HISR(ctrl),
                             DMA_HISR_FEIFx_Msk(stream),
                             DMA_HISR_FEIFx_Pos(stream))) {
            set_reg_bits(r_CORTEX_M_DMA_HIFCR(ctrl),
                         DMA_HIFCR_CFEIFx_Msk(stream));
        }
        if (get_reg(r_CORTEX_M_DMA_SxCR(ctrl, stream), DMA_SxCR_DMEIE)
            && get_reg_value(r_CORTEX_M_DMA_HISR(ctrl),
                             DMA_HISR_DMEIFx_Msk(stream),
                             DMA_HISR_DMEIFx_Pos(stream))) {
            set_reg_bits(r_CORTEX_M_DMA_HIFCR(ctrl),
                         DMA_HIFCR_CDMEIFx_Msk(stream));
        }
        if (get_reg(r_CORTEX_M_DMA_SxCR(ctrl, stream), DMA_SxCR_TEIE) &&
            get_reg_value(r_CORTEX_M_DMA_HISR(ctrl),
                          DMA_HISR_TEIFx_Msk(stream),
                          DMA_HISR_TEIFx_Pos(stream))) {
            set_reg_bits(r_CORTEX_M_DMA_HIFCR(ctrl),
                         DMA_HIFCR_CTEIFx_Msk(stream));
        }
        if (get_reg(r_CORTEX_M_DMA_SxCR(ctrl, stream), DMA_SxCR_HTIE) &&
            get_reg_value(r_CORTEX_M_DMA_HISR(ctrl),
                          DMA_HISR_HTIFx_Msk(stream),
                          DMA_HISR_HTIFx_Pos(stream))) {
            set_reg_bits(r_CORTEX_M_DMA_HIFCR(ctrl),
                         DMA_HIFCR_CHTIFx_Msk(stream));
        }
        if (get_reg(r_CORTEX_M_DMA_SxCR(ctrl, stream), DMA_SxCR_TCIE) &&
            get_reg_value(r_CORTEX_M_DMA_HISR(ctrl),
                          DMA_HISR_TCIFx_Msk(stream),
                          DMA_HISR_TCIFx_Pos(stream))) {
            set_reg_bits(r_CORTEX_M_DMA_HIFCR(ctrl),
                         DMA_HIFCR_CTCIFx_Msk(stream));
        }
    }
}

uint32_t soc_dma_get_status(enum dma_controller ctrl, uint8_t stream)
{
    uint32_t reg = 0;

    /*
     ** TODO: we read the entire register here (4 streams status). A safer way
     ** would be to read only the bits corresponding to the current stream, to
     ** keep other streams status inaccessible to the current task
     **
     ** We then clean the status bits.
     */
    if (stream < 4) {
        reg = read_reg_value(r_CORTEX_M_DMA_LISR(ctrl));
        set_reg_bits(r_CORTEX_M_DMA_LIFCR(ctrl), DMA_LIFCR_CFEIFx_Msk(stream));
        set_reg_bits(r_CORTEX_M_DMA_LIFCR(ctrl), DMA_LIFCR_CDMEIFx_Msk(stream));
        set_reg_bits(r_CORTEX_M_DMA_LIFCR(ctrl), DMA_LIFCR_CTEIFx_Msk(stream));
        set_reg_bits(r_CORTEX_M_DMA_LIFCR(ctrl), DMA_LIFCR_CHTIFx_Msk(stream));
        set_reg_bits(r_CORTEX_M_DMA_LIFCR(ctrl), DMA_LIFCR_CTCIFx_Msk(stream));
    } else {
        reg = read_reg_value(r_CORTEX_M_DMA_HISR(ctrl));
        set_reg_bits(r_CORTEX_M_DMA_HIFCR(ctrl), DMA_HIFCR_CFEIFx_Msk(stream));
        set_reg_bits(r_CORTEX_M_DMA_HIFCR(ctrl), DMA_HIFCR_CDMEIFx_Msk(stream));
        set_reg_bits(r_CORTEX_M_DMA_HIFCR(ctrl), DMA_HIFCR_CTEIFx_Msk(stream));
        set_reg_bits(r_CORTEX_M_DMA_HIFCR(ctrl), DMA_HIFCR_CHTIFx_Msk(stream));
        set_reg_bits(r_CORTEX_M_DMA_HIFCR(ctrl), DMA_HIFCR_CTCIFx_Msk(stream));
    }
    return reg;
}

#ifdef CONFIG_KERNEL_UNSAFE_DMA_ENABLE
/*
** When DMA is managed as a general purpose device, the kernel has no
** information about stream or controller. Nevertheless, the DMA status
** registers has to be cleared in Handler mode to avoid IRQ burst
** In that case, the kernel clear the status register to stop the DMA,
** waiting for the ISR to be executed. The status value is given in
** argument of the ISR
*/

static const struct {
    uint8_t irq;
    uint8_t ctrl;
    uint8_t stream;
} dma_table[] = {
    {
    DMA1_Stream0_IRQ, DMA1, 0}, {
    DMA1_Stream1_IRQ, DMA1, 1}, {
    DMA1_Stream2_IRQ, DMA1, 2}, {
    DMA1_Stream3_IRQ, DMA1, 3}, {
    DMA1_Stream4_IRQ, DMA1, 4}, {
    DMA1_Stream5_IRQ, DMA1, 5}, {
    DMA1_Stream6_IRQ, DMA1, 6}, {
    DMA1_Stream7_IRQ, DMA1, 7}, {
    DMA2_Stream0_IRQ, DMA2, 0}, {
    DMA2_Stream1_IRQ, DMA2, 1}, {
    DMA2_Stream2_IRQ, DMA2, 2}, {
    DMA2_Stream3_IRQ, DMA2, 3}, {
    DMA2_Stream4_IRQ, DMA2, 4}, {
    DMA2_Stream5_IRQ, DMA2, 5}, {
    DMA2_Stream6_IRQ, DMA2, 6}, {
    DMA2_Stream7_IRQ, DMA2, 7}
};

uint8_t soc_dma_get_controller(uint8_t irq)
{
    for (uint8_t i = 0; i < 16; ++i) {
        if (dma_table[i].irq == irq) {
            return dma_table[i].ctrl;
        }
    }
    return 0;
}

uint8_t soc_dma_get_stream(uint8_t irq)
{
    for (uint8_t i = 0; i < 16; ++i) {
        if (dma_table[i].irq == irq) {
            return dma_table[i].stream;
        }
    }
    return 0;
}

#endif
