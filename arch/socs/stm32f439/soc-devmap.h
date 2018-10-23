/* \file soc-devmap.h
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
#ifndef SOC_DEVMAP_H_
#define SOC_DEVMAP_H_

#include "types.h"
#include "perm.h"
#include "soc-rcc.h"
#include "soc-interrupts.h"
#include "soc-dma.h"
#include "regutils.h"


/*
** This file defines the valid adress ranges where devices are mapped.
** This allows the kernel to check that device registration requests correct
** mapping.
**
** Of course these informations are SoC specific
** This file may be completed by a bord specific file for board devices
*/

/*!
** \brief Structure defining the STM32 device map
**
** This table is based on doc STMicro RM0090 Reference manual memory map
** Only devices that may be registered by userspace are mapped here
**
** See #soc_devices_list
*/
struct device_soc_infos {
    char const *name;      /**< Device name, as as string */
    physaddr_t addr;       /**< Device MMIO base address */
    volatile uint32_t *rcc_enr;
                   /**< device's enable register (RCC reg) */
    uint32_t rcc_enb;      /**< device's enable bit in RCC reg */
    uint16_t size;         /**< Device MMIO mapping size */
    uint8_t mask;          /**< subregion mask when needed */
    uint8_t irq;           /**< IRQ line, when exist, or 0 */
    bool ro;           /**< True if the device must be mapped RO */
    res_perm_t minperm;   /**< minimum permission in comparison with the task's permission register */
};

/**
** \var struct device_soc_infos *soc_device_list
** \brief STM32F4 devices map
**
** This structure define all available devices and associated informations. This
** informations are separated in two parts:
**   - physical information (IRQ lines, RCC references, physical address and size...)
**   - security information (required permissions, usage restriction (RO mapping, etc.)
**
** This structure is used in remplacement of a full device tree for simplicity in small
** embedded systems.
*/
static struct device_soc_infos soc_devices_list[] = {
  /*
   * Various CRYP device mapping support
   */
  /* CRYP-CFG: for AES key injection only. when configuring the CRYP device, no need to handle the CRYP irq (handler is managed by CRYP user */
  { "cryp-cfg",    0x50060000, r_CORTEX_M_RCC_AHB2ENR, RCC_AHB2ENR_CRYPEN,  0x800,  0,                 0, false, PERM_RES_DEV_CRYPTO_CFG },
  /* CRYP-USER: for IV injection and data path only (no key injection) */
  { "cryp-user",   0x50060000, r_CORTEX_M_RCC_AHB2ENR, RCC_AHB2ENR_CRYPEN,  0x100,   0b11100010, CRYP_IRQ, false, PERM_RES_DEV_CRYPTO_USR },
  /* CRYP: for complete autonomous CRYP usage */
  { "cryp",        0x50060000, r_CORTEX_M_RCC_AHB2ENR, RCC_AHB2ENR_CRYPEN,  0x400,   0,          CRYP_IRQ, false, PERM_RES_DEV_CRYPTO_FULL },

  { "usb-otg-fs",  0x50000000, r_CORTEX_M_RCC_AHB2ENR, RCC_AHB2ENR_OTGFSEN, 0x4000,  0,        OTG_FS_IRQ, false, PERM_RES_DEV_BUSES },
  { "usb-otg-hs",  0x40040000, r_CORTEX_M_RCC_AHB1ENR, RCC_AHB1ENR_OTGHSEN | RCC_AHB1ENR_OTGHSULPIEN, 0x4000,  0,        OTG_HS_IRQ, false, PERM_RES_DEV_BUSES },
  { "sdio",        0x40012c00, r_CORTEX_M_RCC_APB2ENR, RCC_APB2ENR_SDIOEN,  0x400,   0,          SDIO_IRQ, false, PERM_RES_DEV_BUSES },
#if CONFIG_KERNEL_DMA_ENABLE
/* DMA 1 */
  { "dma1-info",   0x40026000, r_CORTEX_M_RCC_AHB1ENR, RCC_AHB1ENR_DMA1EN,    0x0,  0,                 0, false, PERM_RES_DEV_DMA },
  { "dma1-str0",   0x40026010, r_CORTEX_M_RCC_AHB1ENR, RCC_AHB1ENR_DMA1EN,    0x0,  0,  DMA1_Stream0_IRQ, false, PERM_RES_DEV_DMA },
  { "dma1-str1",   0x40026028, r_CORTEX_M_RCC_AHB1ENR, RCC_AHB1ENR_DMA1EN,    0x0,  0,  DMA1_Stream1_IRQ, false, PERM_RES_DEV_DMA },
  { "dma1-str2",   0x40026040, r_CORTEX_M_RCC_AHB1ENR, RCC_AHB1ENR_DMA1EN,    0x0,  0,  DMA1_Stream2_IRQ, false, PERM_RES_DEV_DMA },
  { "dma1-str3",   0x40026058, r_CORTEX_M_RCC_AHB1ENR, RCC_AHB1ENR_DMA1EN,    0x0,  0,  DMA1_Stream3_IRQ, false, PERM_RES_DEV_DMA },
  { "dma1-str4",   0x40026070, r_CORTEX_M_RCC_AHB1ENR, RCC_AHB1ENR_DMA1EN,    0x0,  0,  DMA1_Stream4_IRQ, false, PERM_RES_DEV_DMA },
  { "dma1-str5",   0x40026088, r_CORTEX_M_RCC_AHB1ENR, RCC_AHB1ENR_DMA1EN,    0x0,  0,  DMA1_Stream5_IRQ, false, PERM_RES_DEV_DMA },
  { "dma1-str6",   0x400260a0, r_CORTEX_M_RCC_AHB1ENR, RCC_AHB1ENR_DMA1EN,    0x0,  0,  DMA1_Stream6_IRQ, false, PERM_RES_DEV_DMA },
  { "dma1-str7",   0x400260b8, r_CORTEX_M_RCC_AHB1ENR, RCC_AHB1ENR_DMA1EN,    0x0,  0,  DMA1_Stream7_IRQ, false, PERM_RES_DEV_DMA },
/* DMA 2 */
  { "dma2-info",   0x40026400, r_CORTEX_M_RCC_AHB1ENR, RCC_AHB1ENR_DMA2EN,   0x0,  0,                 0, false, PERM_RES_DEV_DMA },
  { "dma2-str0",   0x40026410, r_CORTEX_M_RCC_AHB1ENR, RCC_AHB1ENR_DMA2EN,    0x0,  0,  DMA2_Stream0_IRQ, false, PERM_RES_DEV_DMA },
  { "dma2-str1",   0x40026428, r_CORTEX_M_RCC_AHB1ENR, RCC_AHB1ENR_DMA2EN,    0x0,  0,  DMA2_Stream1_IRQ, false, PERM_RES_DEV_DMA },
  { "dma2-str2",   0x40026440, r_CORTEX_M_RCC_AHB1ENR, RCC_AHB1ENR_DMA2EN,    0x0,  0,  DMA2_Stream2_IRQ, false, PERM_RES_DEV_DMA },
  { "dma2-str3",   0x40026458, r_CORTEX_M_RCC_AHB1ENR, RCC_AHB1ENR_DMA2EN,    0x0,  0,  DMA2_Stream3_IRQ, false, PERM_RES_DEV_DMA },
  { "dma2-str4",   0x40026470, r_CORTEX_M_RCC_AHB1ENR, RCC_AHB1ENR_DMA2EN,    0x0,  0,  DMA2_Stream4_IRQ, false, PERM_RES_DEV_DMA },
  { "dma2-str5",   0x40026488, r_CORTEX_M_RCC_AHB1ENR, RCC_AHB1ENR_DMA2EN,    0x0,  0,  DMA2_Stream5_IRQ, false, PERM_RES_DEV_DMA },
  { "dma2-str6",   0x400264a0, r_CORTEX_M_RCC_AHB1ENR, RCC_AHB1ENR_DMA2EN,    0x0,  0,  DMA2_Stream6_IRQ, false, PERM_RES_DEV_DMA },
  { "dma2-str7",   0x400264b8, r_CORTEX_M_RCC_AHB1ENR, RCC_AHB1ENR_DMA2EN,    0x0,  0,  DMA2_Stream7_IRQ, false, PERM_RES_DEV_DMA },
#endif
  { "eth-mac",     0x40028000, r_CORTEX_M_RCC_AHB1ENR, RCC_AHB1ENR_ETHMACEN, 0x1400, 0,          ETH_IRQ, false, PERM_RES_DEV_BUSES },
  { "crc",         0x40023000, r_CORTEX_M_RCC_AHB1ENR, RCC_AHB1ENR_CRCEN,    0x400,  0,                0, false, PERM_RES_DEV_CRYPTO_USR },
  { "spi1",        0x40013000, r_CORTEX_M_RCC_APB2ENR, RCC_APB2ENR_SPI1EN,   0x400,  0,         SPI1_IRQ, false, PERM_RES_DEV_BUSES },
  { "spi2",        0x40003800, r_CORTEX_M_RCC_APB1ENR, RCC_APB1ENR_SPI2EN,   0x400,  0,         SPI2_IRQ, false, PERM_RES_DEV_BUSES },
  { "spi3",        0x40003c00, r_CORTEX_M_RCC_APB1ENR, RCC_APB1ENR_SPI3EN,   0x400,  0,         SPI3_IRQ, false, PERM_RES_DEV_BUSES },
  { "i2c1",        0x40005400, r_CORTEX_M_RCC_APB1ENR, RCC_APB1ENR_I2C1EN,   0x400,  0,      I2C1_EV_IRQ, false, PERM_RES_DEV_BUSES },
  { "i2c2",        0x40005800, r_CORTEX_M_RCC_APB1ENR, RCC_APB1ENR_I2C2EN,   0x400,  0,      I2C2_EV_IRQ, false, PERM_RES_DEV_BUSES },
  { "i2c2",        0x40005c00, r_CORTEX_M_RCC_APB1ENR, RCC_APB1ENR_I2C3EN,   0x400,  0,      I2C3_EV_IRQ, false, PERM_RES_DEV_BUSES },
  { "can1",        0x40006400, r_CORTEX_M_RCC_APB1ENR, RCC_APB1ENR_CAN1EN,   0x400,  0,                0, false, PERM_RES_DEV_BUSES },
  { "can2",        0x40006800, r_CORTEX_M_RCC_APB1ENR, RCC_APB1ENR_CAN2EN,   0x400,  0,                0, false, PERM_RES_DEV_BUSES },
/* usarts. As the kernel register its own usart at boot time, any userspace usart registration of the same usart will return EBUSY */
  { "usart1",       0x40011000, r_CORTEX_M_RCC_APB2ENR, RCC_APB2ENR_USART1EN, 0x400,  0,       USART1_IRQ, false, PERM_RES_DEV_BUSES },
  { "usart6",       0x40011400, r_CORTEX_M_RCC_APB2ENR, RCC_APB2ENR_USART6EN, 0x400,  0,       USART6_IRQ, false, PERM_RES_DEV_BUSES },
  { "usart2",       0x40004400, r_CORTEX_M_RCC_APB1ENR, RCC_APB1ENR_USART2EN, 0x400,  0,       USART2_IRQ, false, PERM_RES_DEV_BUSES },
  { "usart3",       0x40004800, r_CORTEX_M_RCC_APB1ENR, RCC_APB1ENR_USART3EN, 0x400,  0,       USART3_IRQ, false, PERM_RES_DEV_BUSES },
  { "uart4",        0x40004c00, r_CORTEX_M_RCC_APB1ENR, RCC_APB1ENR_UART4EN,  0x400,  0,       USART3_IRQ, false, PERM_RES_DEV_BUSES },
  { "uart5",        0x40005000, r_CORTEX_M_RCC_APB1ENR, RCC_APB1ENR_UART5EN,  0x400,  0,       USART3_IRQ, false, PERM_RES_DEV_BUSES },
/* mapping timers as devices */
  { "tim1",         0x40010000, r_CORTEX_M_RCC_APB2ENR, RCC_APB2ENR_TIM1EN,   0x400,  0,                      0, false, PERM_RES_DEV_TIM },
  { "tim8",         0x40010400, r_CORTEX_M_RCC_APB2ENR, RCC_APB2ENR_TIM8EN,   0x400,  0,                      0, false, PERM_RES_DEV_TIM },
  { "tim9",         0x40014000, r_CORTEX_M_RCC_APB2ENR, RCC_APB2ENR_TIM9EN,   0x400,  0,      TIM1_BRK_TIM9_IRQ, false, PERM_RES_DEV_TIM },
  { "tim10",        0x40014400, r_CORTEX_M_RCC_APB2ENR, RCC_APB2ENR_TIM10EN,  0x400,  0,      TIM1_UP_TIM10_IRQ, false, PERM_RES_DEV_TIM },
  { "tim11",        0x40014800, r_CORTEX_M_RCC_APB2ENR, RCC_APB2ENR_TIM11EN,  0x400,  0, TIM1_TRG_COM_TIM11_IRQ, false, PERM_RES_DEV_TIM },
  { "tim2",         0x40000000, r_CORTEX_M_RCC_APB1ENR, RCC_APB1ENR_TIM2EN,   0x400,  0,               TIM2_IRQ, false, PERM_RES_DEV_TIM },
  { "tim3",         0x40000400, r_CORTEX_M_RCC_APB1ENR, RCC_APB1ENR_TIM3EN,   0x400,  0,               TIM3_IRQ, false, PERM_RES_DEV_TIM },
  { "tim4",         0x40000800, r_CORTEX_M_RCC_APB1ENR, RCC_APB1ENR_TIM4EN,   0x400,  0,               TIM4_IRQ, false, PERM_RES_DEV_TIM },
  { "tim5",         0x40000C00, r_CORTEX_M_RCC_APB1ENR, RCC_APB1ENR_TIM5EN,   0x400,  0,               TIM5_IRQ, false, PERM_RES_DEV_TIM },
  { "tim6",         0x40001000, r_CORTEX_M_RCC_APB1ENR, RCC_APB1ENR_TIM6EN,   0x400,  0,           TIM6_DAC_IRQ, false, PERM_RES_DEV_TIM },
  { "tim7",         0x40001400, r_CORTEX_M_RCC_APB1ENR, RCC_APB1ENR_TIM7EN,   0x400,  0,               TIM7_IRQ, false, PERM_RES_DEV_TIM },
  { "tim12",        0x40001800, r_CORTEX_M_RCC_APB1ENR, RCC_APB1ENR_TIM12EN,  0x400,  0,     TIM8_BRK_TIM12_IRQ, false, PERM_RES_DEV_TIM },
  { "tim13",        0x40001C00, r_CORTEX_M_RCC_APB1ENR, RCC_APB1ENR_TIM13EN,  0x400,  0,      TIM8_UP_TIM13_IRQ, false, PERM_RES_DEV_TIM },
  { "tim14",        0x40002000, r_CORTEX_M_RCC_APB1ENR, RCC_APB1ENR_TIM14EN,  0x400,  0, TIM8_TRG_COM_TIM14_IRQ, false, PERM_RES_DEV_TIM },
};

static const uint8_t soc_devices_list_size =
    sizeof(soc_devices_list) / sizeof(struct device_soc_infos);

struct device_soc_infos* soc_devmap_find_device
    (physaddr_t addr, uint16_t size);

void soc_devmap_enable_clock (const struct device_soc_infos *device);

struct device_soc_infos *soc_devices_get_dma // FIXME rename
    (enum dma_controller id, uint8_t stream);

#endif                          /*!SOC_DEVMAP_H_ */
