/* \file soc-rcc.h
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
#ifndef SOC_RCC_H
#define SOC_RCC_H

#include "soc-init.h"
#include "soc-core.h"

#define r_CORTEX_M_RCC_CR           REG_ADDR(RCC_BASE + (uint32_t) 0x00)
#define r_CORTEX_M_RCC_PLLCFGR      REG_ADDR(RCC_BASE + (uint32_t) 0x04)
#define r_CORTEX_M_RCC_CFGR         REG_ADDR(RCC_BASE + (uint32_t) 0x08)
#define r_CORTEX_M_RCC_CIR          REG_ADDR(RCC_BASE + (uint32_t) 0x0C)
#define r_CORTEX_M_RCC_AHB1RSTR     REG_ADDR(RCC_BASE + (uint32_t) 0x10)
#define r_CORTEX_M_RCC_AHB2RSTR     REG_ADDR(RCC_BASE + (uint32_t) 0x14)
#define r_CORTEX_M_RCC_AHB3RSTR     REG_ADDR(RCC_BASE + (uint32_t) 0x18)
#define r_CORTEX_M_RCC_APB1RSTR     REG_ADDR(RCC_BASE + (uint32_t) 0x20)
#define r_CORTEX_M_RCC_APB2RSTR     REG_ADDR(RCC_BASE + (uint32_t) 0x24)
#define r_CORTEX_M_RCC_AHB1ENR      REG_ADDR(RCC_BASE + (uint32_t) 0x30)
#define r_CORTEX_M_RCC_AHB2ENR      REG_ADDR(RCC_BASE + (uint32_t) 0x34)
#define r_CORTEX_M_RCC_AHB3ENR      REG_ADDR(RCC_BASE + (uint32_t) 0x38)
#define r_CORTEX_M_RCC_APB1ENR      REG_ADDR(RCC_BASE + (uint32_t) 0x40)
#define r_CORTEX_M_RCC_APB2ENR      REG_ADDR(RCC_BASE + (uint32_t) 0x44)
#define r_CORTEX_M_RCC_AHB1LPENR    REG_ADDR(RCC_BASE + (uint32_t) 0x50)
#define r_CORTEX_M_RCC_AHB2LPENR    REG_ADDR(RCC_BASE + (uint32_t) 0x54)
#define r_CORTEX_M_RCC_AHB3LPENR    REG_ADDR(RCC_BASE + (uint32_t) 0x58)
#define r_CORTEX_M_RCC_APB1LPENR    REG_ADDR(RCC_BASE + (uint32_t) 0x60)
#define r_CORTEX_M_RCC_APB2LPENR    REG_ADDR(RCC_BASE + (uint32_t) 0x64)
#define r_CORTEX_M_RCC_BDCR         REG_ADDR(RCC_BASE + (uint32_t) 0x70)
#define r_CORTEX_M_RCC_CSR          REG_ADDR(RCC_BASE + (uint32_t) 0x74)
#define r_CORTEX_M_RCC_SSCGR        REG_ADDR(RCC_BASE + (uint32_t) 0x80)
#define r_CORTEX_M_RCC_PLLI2SCFGR   REG_ADDR(RCC_BASE + (uint32_t) 0x84)
#define r_CORTEX_M_RCC_PLLSAICFGR   REG_ADDR(RCC_BASE + (uint32_t) 0x88)
#define r_CORTEX_M_RCC_DCKCFGR      REG_ADDR(RCC_BASE + (uint32_t) 0x8C)

/* RCC clock control register (RCC_CR) */
#define  RCC_CR_HSION                        ((uint32_t) 0x00000001)
#define  RCC_CR_HSIRDY                       ((uint32_t) 0x00000002)

#define  RCC_CR_HSITRIM                      ((uint32_t) 0x000000F8)
#define  RCC_CR_HSITRIM_0                    ((uint32_t) 0x00000008)    /*Bit 0 */
#define  RCC_CR_HSITRIM_1                    ((uint32_t) 0x00000010)    /*Bit 1 */
#define  RCC_CR_HSITRIM_2                    ((uint32_t) 0x00000020)    /*Bit 2 */
#define  RCC_CR_HSITRIM_3                    ((uint32_t) 0x00000040)    /*Bit 3 */
#define  RCC_CR_HSITRIM_4                    ((uint32_t) 0x00000080)    /*Bit 4 */

#define  RCC_CR_HSICAL                       ((uint32_t) 0x0000FF00)
#define  RCC_CR_HSICAL_0                     ((uint32_t) 0x00000100)    /*Bit 0 */
#define  RCC_CR_HSICAL_1                     ((uint32_t) 0x00000200)    /*Bit 1 */
#define  RCC_CR_HSICAL_2                     ((uint32_t) 0x00000400)    /*Bit 2 */
#define  RCC_CR_HSICAL_3                     ((uint32_t) 0x00000800)    /*Bit 3 */
#define  RCC_CR_HSICAL_4                     ((uint32_t) 0x00001000)    /*Bit 4 */
#define  RCC_CR_HSICAL_5                     ((uint32_t) 0x00002000)    /*Bit 5 */
#define  RCC_CR_HSICAL_6                     ((uint32_t) 0x00004000)    /*Bit 6 */
#define  RCC_CR_HSICAL_7                     ((uint32_t) 0x00008000)    /*Bit 7 */

#define  RCC_CR_HSEON                        ((uint32_t) 0x00010000)
#define  RCC_CR_HSERDY                       ((uint32_t) 0x00020000)
#define  RCC_CR_HSEBYP                       ((uint32_t) 0x00040000)
#define  RCC_CR_CSSON                        ((uint32_t) 0x00080000)
#define  RCC_CR_PLLON                        ((uint32_t) 0x01000000)
#define  RCC_CR_PLLRDY                       ((uint32_t) 0x02000000)
#define  RCC_CR_PLLI2SON                     ((uint32_t) 0x04000000)
#define  RCC_CR_PLLI2SRDY                    ((uint32_t) 0x08000000)

/* RCC PLL configuration register (RCC_PLLCFGR) */
#define  RCC_PLLCFGR_PLLM                    ((uint32_t) 0x0000003F)
#define  RCC_PLLCFGR_PLLM_0                  ((uint32_t) 0x00000001)
#define  RCC_PLLCFGR_PLLM_1                  ((uint32_t) 0x00000002)
#define  RCC_PLLCFGR_PLLM_2                  ((uint32_t) 0x00000004)
#define  RCC_PLLCFGR_PLLM_3                  ((uint32_t) 0x00000008)
#define  RCC_PLLCFGR_PLLM_4                  ((uint32_t) 0x00000010)
#define  RCC_PLLCFGR_PLLM_5                  ((uint32_t) 0x00000020)

#define  RCC_PLLCFGR_PLLN                     ((uint32_t) 0x00007FC0)
#define  RCC_PLLCFGR_PLLN_0                   ((uint32_t) 0x00000040)
#define  RCC_PLLCFGR_PLLN_1                   ((uint32_t) 0x00000080)
#define  RCC_PLLCFGR_PLLN_2                   ((uint32_t) 0x00000100)
#define  RCC_PLLCFGR_PLLN_3                   ((uint32_t) 0x00000200)
#define  RCC_PLLCFGR_PLLN_4                   ((uint32_t) 0x00000400)
#define  RCC_PLLCFGR_PLLN_5                   ((uint32_t) 0x00000800)
#define  RCC_PLLCFGR_PLLN_6                   ((uint32_t) 0x00001000)
#define  RCC_PLLCFGR_PLLN_7                   ((uint32_t) 0x00002000)
#define  RCC_PLLCFGR_PLLN_8                   ((uint32_t) 0x00004000)

#define  RCC_PLLCFGR_PLLP                    ((uint32_t) 0x00030000)
#define  RCC_PLLCFGR_PLLP_0                  ((uint32_t) 0x00010000)
#define  RCC_PLLCFGR_PLLP_1                  ((uint32_t) 0x00020000)

#define  RCC_PLLCFGR_PLLSRC                  ((uint32_t) 0x00400000)
#define  RCC_PLLCFGR_PLLSRC_HSE              ((uint32_t) 0x00400000)
#define  RCC_PLLCFGR_PLLSRC_HSI              ((uint32_t) 0x00000000)

#define  RCC_PLLCFGR_PLLQ                    ((uint32_t) 0x0F000000)
#define  RCC_PLLCFGR_PLLQ_0                  ((uint32_t) 0x01000000)
#define  RCC_PLLCFGR_PLLQ_1                  ((uint32_t) 0x02000000)
#define  RCC_PLLCFGR_PLLQ_2                  ((uint32_t) 0x04000000)
#define  RCC_PLLCFGR_PLLQ_3                  ((uint32_t) 0x08000000)

/* RCC clock configuration register (RCC_CFGR) */
#define  RCC_CFGR_SW                         ((uint32_t) 0x00000003)    /* SW[1:0] bits (System clock Switch) */
#define  RCC_CFGR_SW_0                       ((uint32_t) 0x00000001)    /* Bit 0 */
#define  RCC_CFGR_SW_1                       ((uint32_t) 0x00000002)    /* Bit 1 */

#define  RCC_CFGR_SW_HSI                     ((uint32_t) 0x00000000)    /* HSI selected as system clock */
#define  RCC_CFGR_SW_HSE                     ((uint32_t) 0x00000001)    /* HSE selected as system clock */
#define  RCC_CFGR_SW_PLL                     ((uint32_t) 0x00000002)    /* PLL selected as system clock */

/* SWS configuration */
#define  RCC_CFGR_SWS                        ((uint32_t) 0x0000000C)    /* SWS[1:0] bits (System Clock Switch Status) */
#define  RCC_CFGR_SWS_0                      ((uint32_t) 0x00000004)    /* Bit 0 */
#define  RCC_CFGR_SWS_1                      ((uint32_t) 0x00000008)    /* Bit 1 */

#define  RCC_CFGR_SWS_HSI                    ((uint32_t) 0x00000000)    /* HSI oscillator used as system clock */
#define  RCC_CFGR_SWS_HSE                    ((uint32_t) 0x00000004)    /* HSE oscillator used as system clock */
#define  RCC_CFGR_SWS_PLL                    ((uint32_t) 0x00000008)    /* PLL used as system clock */

/* HPRE configuration */
#define  RCC_CFGR_HPRE                       ((uint32_t) 0x000000F0)    /* HPRE[3:0] bits (AHB prescaler) */
#define  RCC_CFGR_HPRE_0                     ((uint32_t) 0x00000010)    /* Bit 0 */
#define  RCC_CFGR_HPRE_1                     ((uint32_t) 0x00000020)    /* Bit 1 */
#define  RCC_CFGR_HPRE_2                     ((uint32_t) 0x00000040)    /* Bit 2 */
#define  RCC_CFGR_HPRE_3                     ((uint32_t) 0x00000080)    /* Bit 3 */

#define  RCC_CFGR_HPRE_DIV1                  ((uint32_t) 0x00000000)    /* SYSCLK not divided */
#define  RCC_CFGR_HPRE_DIV2                  ((uint32_t) 0x00000080)    /* SYSCLK divided by 2 */
#define  RCC_CFGR_HPRE_DIV4                  ((uint32_t) 0x00000090)    /* SYSCLK divided by 4 */
#define  RCC_CFGR_HPRE_DIV8                  ((uint32_t) 0x000000A0)    /* SYSCLK divided by 8 */
#define  RCC_CFGR_HPRE_DIV16                 ((uint32_t) 0x000000B0)    /* SYSCLK divided by 16 */
#define  RCC_CFGR_HPRE_DIV64                 ((uint32_t) 0x000000C0)    /* SYSCLK divided by 64 */
#define  RCC_CFGR_HPRE_DIV128                ((uint32_t) 0x000000D0)    /* SYSCLK divided by 128 */
#define  RCC_CFGR_HPRE_DIV256                ((uint32_t) 0x000000E0)    /* SYSCLK divided by 256 */
#define  RCC_CFGR_HPRE_DIV512                ((uint32_t) 0x000000F0)    /* SYSCLK divided by 512 */

/* PPRE1 configuration */
#define  RCC_CFGR_HPRE1                      ((uint32_t) 0x00001C00)    /* PRE1[2:0] bits (APB1 prescaler) */
#define  RCC_CFGR_HPRE1_0                    ((uint32_t) 0x00000400)    /* Bit 0 */
#define  RCC_CFGR_HPRE1_1                    ((uint32_t) 0x00000800)    /* Bit 1 */
#define  RCC_CFGR_HPRE1_2                    ((uint32_t) 0x00001000)    /* Bit 2 */

#define  RCC_CFGR_HPRE1_DIV1                 ((uint32_t) 0x00000000)    /* HCLK not divided */
#define  RCC_CFGR_HPRE1_DIV2                 ((uint32_t) 0x00001000)    /* HCLK divided by 2 */
#define  RCC_CFGR_HPRE1_DIV4                 ((uint32_t) 0x00001400)    /* HCLK divided by 4 */
#define  RCC_CFGR_HPRE1_DIV8                 ((uint32_t) 0x00001800)    /* HCLK divided by 8 */
#define  RCC_CFGR_HPRE1_DIV16                ((uint32_t) 0x00001C00)    /* HCLK divided by 16 */

/* PPRE2 configuration */
#define  RCC_CFGR_HPRE2                      ((uint32_t) 0x0000E000)    /* PRE2[2:0] bits (APB2 prescaler) */
#define  RCC_CFGR_HPRE2_0                    ((uint32_t) 0x00002000)    /* Bit 0 */
#define  RCC_CFGR_HPRE2_1                    ((uint32_t) 0x00004000)    /* Bit 1 */
#define  RCC_CFGR_HPRE2_2                    ((uint32_t) 0x00008000)    /* Bit 2 */

#define  RCC_CFGR_HPRE2_DIV1                 ((uint32_t) 0x00000000)    /* HCLK not divided */
#define  RCC_CFGR_HPRE2_DIV2                 ((uint32_t) 0x00008000)    /* HCLK divided by 2 */
#define  RCC_CFGR_HPRE2_DIV4                 ((uint32_t) 0x0000A000)    /* HCLK divided by 4 */
#define  RCC_CFGR_HPRE2_DIV8                 ((uint32_t) 0x0000C000)    /* HCLK divided by 8 */
#define  RCC_CFGR_HPRE2_DIV16                ((uint32_t) 0x0000E000)    /* HCLK divided by 16 */

/* RTCPRE configuration */
#define  RCC_CFGR_RTCPRE                     ((uint32_t) 0x001F0000)
#define  RCC_CFGR_RTCPRE_0                   ((uint32_t) 0x00010000)
#define  RCC_CFGR_RTCPRE_1                   ((uint32_t) 0x00020000)
#define  RCC_CFGR_RTCPRE_2                   ((uint32_t) 0x00040000)
#define  RCC_CFGR_RTCPRE_3                   ((uint32_t) 0x00080000)
#define  RCC_CFGR_RTCPRE_4                   ((uint32_t) 0x00100000)

/* MCO1 configuration */
#define  RCC_CFGR_MCO1                       ((uint32_t) 0x00600000)
#define  RCC_CFGR_MCO1_0                     ((uint32_t) 0x00200000)
#define  RCC_CFGR_MCO1_1                     ((uint32_t) 0x00400000)

#define  RCC_CFGR_I2SSRC                     ((uint32_t) 0x00800000)

#define  RCC_CFGR_MCO1PRE                    ((uint32_t) 0x07000000)
#define  RCC_CFGR_MCO1PRE_0                  ((uint32_t) 0x01000000)
#define  RCC_CFGR_MCO1PRE_1                  ((uint32_t) 0x02000000)
#define  RCC_CFGR_MCO1PRE_2                  ((uint32_t) 0x04000000)

#define  RCC_CFGR_MCO2PRE                    ((uint32_t) 0x38000000)
#define  RCC_CFGR_MCO2PRE_0                  ((uint32_t) 0x08000000)
#define  RCC_CFGR_MCO2PRE_1                  ((uint32_t) 0x10000000)
#define  RCC_CFGR_MCO2PRE_2                  ((uint32_t) 0x20000000)

#define  RCC_CFGR_MCO2                       ((uint32_t) 0xC0000000)
#define  RCC_CFGR_MCO2_0                     ((uint32_t) 0x40000000)
#define  RCC_CFGR_MCO2_1                     ((uint32_t) 0x80000000)

/* RCC clock interrupt register (RCC_CIR) */
#define  RCC_CIR_LSIRDYF                     ((uint32_t) 0x00000001)
#define  RCC_CIR_LSERDYF                     ((uint32_t) 0x00000002)
#define  RCC_CIR_HSIRDYF                     ((uint32_t) 0x00000004)
#define  RCC_CIR_HSERDYF                     ((uint32_t) 0x00000008)
#define  RCC_CIR_PLLRDYF                     ((uint32_t) 0x00000010)
#define  RCC_CIR_PLLI2SRDYF                  ((uint32_t) 0x00000020)
#define  RCC_CIR_CSSF                        ((uint32_t) 0x00000080)
#define  RCC_CIR_LSIRDYIE                    ((uint32_t) 0x00000100)
#define  RCC_CIR_LSERDYIE                    ((uint32_t) 0x00000200)
#define  RCC_CIR_HSIRDYIE                    ((uint32_t) 0x00000400)
#define  RCC_CIR_HSERDYIE                    ((uint32_t) 0x00000800)
#define  RCC_CIR_PLLRDYIE                    ((uint32_t) 0x00001000)
#define  RCC_CIR_PLLI2SRDYIE                 ((uint32_t) 0x00002000)
#define  RCC_CIR_LSIRDYC                     ((uint32_t) 0x00010000)
#define  RCC_CIR_LSERDYC                     ((uint32_t) 0x00020000)
#define  RCC_CIR_HSIRDYC                     ((uint32_t) 0x00040000)
#define  RCC_CIR_HSERDYC                     ((uint32_t) 0x00080000)
#define  RCC_CIR_PLLRDYC                     ((uint32_t) 0x00100000)
#define  RCC_CIR_PLLI2SRDYC                  ((uint32_t) 0x00200000)
#define  RCC_CIR_CSSC                        ((uint32_t) 0x00800000)

/* RCC AHB1 peripheral reset register (RCC_AHB1RSTR) */
#define  RCC_AHB1RSTR_GPIOARST               ((uint32_t) 0x00000001)
#define  RCC_AHB1RSTR_GPIOBRST               ((uint32_t) 0x00000002)
#define  RCC_AHB1RSTR_GPIOCRST               ((uint32_t) 0x00000004)
#define  RCC_AHB1RSTR_GPIODRST               ((uint32_t) 0x00000008)
#define  RCC_AHB1RSTR_GPIOERST               ((uint32_t) 0x00000010)
#define  RCC_AHB1RSTR_GPIOFRST               ((uint32_t) 0x00000020)
#define  RCC_AHB1RSTR_GPIOGRST               ((uint32_t) 0x00000040)
#define  RCC_AHB1RSTR_GPIOHRST               ((uint32_t) 0x00000080)
#define  RCC_AHB1RSTR_GPIOIRST               ((uint32_t) 0x00000100)
#define  RCC_AHB1RSTR_CRCRST                 ((uint32_t) 0x00001000)
#define  RCC_AHB1RSTR_DMA1RST                ((uint32_t) 0x00200000)
#define  RCC_AHB1RSTR_DMA2RST                ((uint32_t) 0x00400000)
#define  RCC_AHB1RSTR_ETHMACRST              ((uint32_t) 0x02000000)
#define  RCC_AHB1RSTR_OTGHRST                ((uint32_t) 0x10000000)

/* RCC AHB2 peripheral reset register (RCC_AHB2RSTR) */
#define  RCC_AHB2RSTR_DCMIRST                ((uint32_t) 0x00000001)
#define  RCC_AHB2RSTR_CRYPRST                ((uint32_t) 0x00000010)
#define  RCC_AHB2RSTR_HSAHRST                ((uint32_t) 0x00000020)
#define  RCC_AHB2RSTR_RNGRST                 ((uint32_t) 0x00000040)
#define  RCC_AHB2RSTR_OTGFSRST               ((uint32_t) 0x00000080)

/* RCC AHB3 peripheral reset register (RCC_AHB3RSTR) */
#define  RCC_AHB3RSTR_FSMCRST                ((uint32_t) 0x00000001

/* RCC AHB1 peripheral clock register (RCC_AHB1ENR) */
#define  RCC_AHB1ENR_GPIOAEN                 ((uint32_t) 0x00000001)
#define  RCC_AHB1ENR_GPIOBEN                 ((uint32_t) 0x00000002)
#define  RCC_AHB1ENR_GPIOCEN                 ((uint32_t) 0x00000004)
#define  RCC_AHB1ENR_GPIODEN                 ((uint32_t) 0x00000008)
#define  RCC_AHB1ENR_GPIOEEN                 ((uint32_t) 0x00000010)
#define  RCC_AHB1ENR_GPIOFEN                 ((uint32_t) 0x00000020)
#define  RCC_AHB1ENR_GPIOGEN                 ((uint32_t) 0x00000040)
#define  RCC_AHB1ENR_GPIOHEN                 ((uint32_t) 0x00000080)
#define  RCC_AHB1ENR_GPIOIEN                 ((uint32_t) 0x00000100)
#define  RCC_AHB1ENR_CRCEN                   ((uint32_t) 0x00001000)
#define  RCC_AHB1ENR_BKPSRAMEN               ((uint32_t) 0x00040000)
#define  RCC_AHB1ENR_CCMDATARAMEN            ((uint32_t) 0x00100000)
#define  RCC_AHB1ENR_DMA1EN                  ((uint32_t) 0x00200000)
#define  RCC_AHB1ENR_DMA2EN                  ((uint32_t) 0x00400000)
#define  RCC_AHB1ENR_ETHMACEN                ((uint32_t) 0x02000000)
#define  RCC_AHB1ENR_ETHMACTXEN              ((uint32_t) 0x04000000)
#define  RCC_AHB1ENR_ETHMACRXEN              ((uint32_t) 0x08000000)
#define  RCC_AHB1ENR_ETHMACPTPEN             ((uint32_t) 0x10000000)
#define  RCC_AHB1ENR_OTGHSEN                 ((uint32_t) 0x20000000)
#define  RCC_AHB1ENR_OTGHSULPIEN             ((uint32_t) 0x40000000)

/* RCC AHB2 peripheral clock enable register (RCC_AHB2ENR)*/
#define  RCC_AHB2ENR_DCMIEN                  ((uint32_t) 0x00000001)
#define  RCC_AHB2ENR_CRYPEN                  ((uint32_t) 0x00000010)
#define  RCC_AHB2ENR_HASHEN                  ((uint32_t) 0x00000020)
#define  RCC_AHB2ENR_RNGEN                   ((uint32_t) 0x00000040)
#define  RCC_AHB2ENR_OTGFSEN                 ((uint32_t) 0x00000080)

/* RCC AHB3 peripheral clock enable register (RCC_AHB3ENR)*/
#define  RCC_AHB3ENR_FSMCEN                  ((uint32_t) 0x00000001)

/* RCC APB1 peripheral clock enable register (RCC_APB1ENR)*/
#define  RCC_APB1ENR_TIM2EN                  ((uint32_t) 0x00000001)
#define  RCC_APB1ENR_TIM3EN                  ((uint32_t) 0x00000002)
#define  RCC_APB1ENR_TIM4EN                  ((uint32_t) 0x00000004)
#define  RCC_APB1ENR_TIM5EN                  ((uint32_t) 0x00000008)
#define  RCC_APB1ENR_TIM6EN                  ((uint32_t) 0x00000010)
#define  RCC_APB1ENR_TIM7EN                  ((uint32_t) 0x00000020)
#define  RCC_APB1ENR_TIM12EN                 ((uint32_t) 0x00000040)
#define  RCC_APB1ENR_TIM13EN                 ((uint32_t) 0x00000080)
#define  RCC_APB1ENR_TIM14EN                 ((uint32_t) 0x00000100)
#define  RCC_APB1ENR_WWDGEN                  ((uint32_t) 0x00000800)
#define  RCC_APB1ENR_SPI2EN                  ((uint32_t) 0x00004000)
#define  RCC_APB1ENR_SPI3EN                  ((uint32_t) 0x00008000)
#define  RCC_APB1ENR_USART2EN                ((uint32_t) 0x00020000)
#define  RCC_APB1ENR_USART3EN                ((uint32_t) 0x00040000)
#define  RCC_APB1ENR_UART4EN                 ((uint32_t) 0x00080000)
#define  RCC_APB1ENR_UART5EN                 ((uint32_t) 0x00100000)
#define  RCC_APB1ENR_I2C1EN                  ((uint32_t) 0x00200000)
#define  RCC_APB1ENR_I2C2EN                  ((uint32_t) 0x00400000)
#define  RCC_APB1ENR_I2C3EN                  ((uint32_t) 0x00800000)
#define  RCC_APB1ENR_CAN1EN                  ((uint32_t) 0x02000000)
#define  RCC_APB1ENR_CAN2EN                  ((uint32_t) 0x04000000)
#define  RCC_APB1ENR_PWREN                   ((uint32_t) 0x10000000)
#define  RCC_APB1ENR_DACEN                   ((uint32_t) 0x20000000)

/* RCC APB2 peripheral clock enable register (RCC_APB2ENR) */
#define  RCC_APB2ENR_TIM1EN                  ((uint32_t) 0x00000001)
#define  RCC_APB2ENR_TIM8EN                  ((uint32_t) 0x00000002)
#define  RCC_APB2ENR_USART1EN                ((uint32_t) 0x00000010)
#define  RCC_APB2ENR_USART6EN                ((uint32_t) 0x00000020)
#define  RCC_APB2ENR_ADC1EN                  ((uint32_t) 0x00000100)
#define  RCC_APB2ENR_ADC2EN                  ((uint32_t) 0x00000200)
#define  RCC_APB2ENR_ADC3EN                  ((uint32_t) 0x00000400)
#define  RCC_APB2ENR_SDIOEN                  ((uint32_t) 0x00000800)
#define  RCC_APB2ENR_SPI1EN                  ((uint32_t) 0x00001000)
#define  RCC_APB2ENR_SYSCFGEN                ((uint32_t) 0x00004000)
#define  RCC_APB2ENR_TIM11EN                 ((uint32_t) 0x00040000)
#define  RCC_APB2ENR_TIM10EN                 ((uint32_t) 0x00020000)
#define  RCC_APB2ENR_TIM9EN                  ((uint32_t) 0x00010000)

/* RCC AHB1 peripheral clock enable in low power mode register (RCC_AHB1LPENR) */
#define  RCC_AHB1LPENR_GPIOALPEN             ((uint32_t) 0x00000001)
#define  RCC_AHB1LPENR_GPIOBLPEN             ((uint32_t) 0x00000002)
#define  RCC_AHB1LPENR_GPIOCLPEN             ((uint32_t) 0x00000004)
#define  RCC_AHB1LPENR_GPIODLPEN             ((uint32_t) 0x00000008)
#define  RCC_AHB1LPENR_GPIOELPEN             ((uint32_t) 0x00000010)
#define  RCC_AHB1LPENR_GPIOFLPEN             ((uint32_t) 0x00000020)
#define  RCC_AHB1LPENR_GPIOGLPEN             ((uint32_t) 0x00000040)
#define  RCC_AHB1LPENR_GPIOHLPEN             ((uint32_t) 0x00000080)
#define  RCC_AHB1LPENR_GPIOILPEN             ((uint32_t) 0x00000100)
#define  RCC_AHB1LPENR_CRCLPEN               ((uint32_t) 0x00001000)
#define  RCC_AHB1LPENR_FLITFLPEN             ((uint32_t) 0x00008000)
#define  RCC_AHB1LPENR_SRAM1LPEN             ((uint32_t) 0x00010000)
#define  RCC_AHB1LPENR_SRAM2LPEN             ((uint32_t) 0x00020000)
#define  RCC_AHB1LPENR_BKPSRAMLPEN           ((uint32_t) 0x00040000)
#define  RCC_AHB1LPENR_DMA1LPEN              ((uint32_t) 0x00200000)
#define  RCC_AHB1LPENR_DMA2LPEN              ((uint32_t) 0x00400000)
#define  RCC_AHB1LPENR_ETHMACLPEN            ((uint32_t) 0x02000000)
#define  RCC_AHB1LPENR_ETHMACTXLPEN          ((uint32_t) 0x04000000)
#define  RCC_AHB1LPENR_ETHMACRXLPEN          ((uint32_t) 0x08000000)
#define  RCC_AHB1LPENR_ETHMACPTPLPEN         ((uint32_t) 0x10000000)
#define  RCC_AHB1LPENR_OTGHSLPEN             ((uint32_t) 0x20000000)
#define  RCC_AHB1LPENR_OTGHSULPILPEN         ((uint32_t) 0x40000000)

/* RCC AHB2 peripheral clock enable in low power mode register (RCC_AHB2LPENR) */
#define  RCC_AHB2LPENR_DCMILPEN              ((uint32_t) 0x00000001)
#define  RCC_AHB2LPENR_CRYPLPEN              ((uint32_t) 0x00000010)
#define  RCC_AHB2LPENR_HASHLPEN              ((uint32_t) 0x00000020)
#define  RCC_AHB2LPENR_RNGLPEN               ((uint32_t) 0x00000040)
#define  RCC_AHB2LPENR_OTGFSLPEN             ((uint32_t) 0x00000080)

/* RCC AHB3 peripheral clock enable in low power mode register (RCC_AHB3LPENR) */
#define  RCC_AHB3LPENR_FSMCLPEN              ((uint32_t) 0x00000001)

/* RCC APB1 peripheral clock enable in low power mode register (RCC_APB1LPENR) */
#define  RCC_APB1LPENR_TIM2LPEN              ((uint32_t) 0x00000001)
#define  RCC_APB1LPENR_TIM3LPEN              ((uint32_t) 0x00000002)
#define  RCC_APB1LPENR_TIM4LPEN              ((uint32_t) 0x00000004)
#define  RCC_APB1LPENR_TIM5LPEN              ((uint32_t) 0x00000008)
#define  RCC_APB1LPENR_TIM6LPEN              ((uint32_t) 0x00000010)
#define  RCC_APB1LPENR_TIM7LPEN              ((uint32_t) 0x00000020)
#define  RCC_APB1LPENR_TIM12LPEN             ((uint32_t) 0x00000040)
#define  RCC_APB1LPENR_TIM13LPEN             ((uint32_t) 0x00000080)
#define  RCC_APB1LPENR_TIM14LPEN             ((uint32_t) 0x00000100)
#define  RCC_APB1LPENR_WWDGLPEN              ((uint32_t) 0x00000800)
#define  RCC_APB1LPENR_SPI2LPEN              ((uint32_t) 0x00004000)
#define  RCC_APB1LPENR_SPI3LPEN              ((uint32_t) 0x00008000)
#define  RCC_APB1LPENR_USART2LPEN            ((uint32_t) 0x00020000)
#define  RCC_APB1LPENR_USART3LPEN            ((uint32_t) 0x00040000)
#define  RCC_APB1LPENR_UART4LPEN             ((uint32_t) 0x00080000)
#define  RCC_APB1LPENR_UART5LPEN             ((uint32_t) 0x00100000)
#define  RCC_APB1LPENR_I2C1LPEN              ((uint32_t) 0x00200000)
#define  RCC_APB1LPENR_I2C2LPEN              ((uint32_t) 0x00400000)
#define  RCC_APB1LPENR_I2C3LPEN              ((uint32_t) 0x00800000)
#define  RCC_APB1LPENR_CAN1LPEN              ((uint32_t) 0x02000000)
#define  RCC_APB1LPENR_CAN2LPEN              ((uint32_t) 0x04000000)
#define  RCC_APB1LPENR_PWRLPEN               ((uint32_t) 0x10000000)
#define  RCC_APB1LPENR_DACLPEN               ((uint32_t) 0x20000000)

/* RCC APB2 peripheral clock enabled in low power mode register (RCC_APB2LPENR) */
#define  RCC_APB2LPENR_TIM1LPEN              ((uint32_t) 0x00000001)
#define  RCC_APB2LPENR_TIM8LPEN              ((uint32_t) 0x00000002)
#define  RCC_APB2LPENR_USART1LPEN            ((uint32_t) 0x00000010)
#define  RCC_APB2LPENR_USART6LPEN            ((uint32_t) 0x00000020)
#define  RCC_APB2LPENR_ADC1LPEN              ((uint32_t) 0x00000100)
#define  RCC_APB2LPENR_ADC2PEN               ((uint32_t) 0x00000200)
#define  RCC_APB2LPENR_ADC3LPEN              ((uint32_t) 0x00000400)
#define  RCC_APB2LPENR_SDIOLPEN              ((uint32_t) 0x00000800)
#define  RCC_APB2LPENR_SPI1LPEN              ((uint32_t) 0x00001000)
#define  RCC_APB2LPENR_SYSCFGLPEN            ((uint32_t) 0x00004000)
#define  RCC_APB2LPENR_TIM9LPEN              ((uint32_t) 0x00010000)
#define  RCC_APB2LPENR_TIM10LPEN             ((uint32_t) 0x00020000)
#define  RCC_APB2LPENR_TIM11LPEN             ((uint32_t) 0x00040000)

/* RCC APB2 peripheral reset register (RCC_APB2RSTR) */
#define  RCC_APB2RSTR_TIM1RST                ((uint32_t)0x00000001)
#define  RCC_APB2RSTR_TIM8RST                ((uint32_t)0x00000002)
#define  RCC_APB2RSTR_USART1RST              ((uint32_t)0x00000010)
#define  RCC_APB2RSTR_USART6RST              ((uint32_t)0x00000020)
#define  RCC_APB2RSTR_ADCRST                 ((uint32_t)0x00000100)
#define  RCC_APB2RSTR_SDIORST                ((uint32_t)0x00000800)
#define  RCC_APB2RSTR_SPI1RST                ((uint32_t)0x00001000)
#define  RCC_APB2RSTR_SYSCFGRST              ((uint32_t)0x00004000)
#define  RCC_APB2RSTR_TIM9RST                ((uint32_t)0x00010000)
#define  RCC_APB2RSTR_TIM10RST               ((uint32_t)0x00020000)
#define  RCC_APB2RSTR_TIM11RST               ((uint32_t)0x00040000)

/* RCC Backup domain control register (RCC_BDCR) */
#define  RCC_BDCR_LSEON                      ((uint32_t) 0x00000001)
#define  RCC_BDCR_LSERDY                     ((uint32_t) 0x00000002)
#define  RCC_BDCR_LSEBYP                     ((uint32_t) 0x00000004)

#define  RCC_BDCR_RTCSEL                    ((uint32_t) 0x00000300)
#define  RCC_BDCR_RTCSEL_0                  ((uint32_t) 0x00000100)
#define  RCC_BDCR_RTCSEL_1                  ((uint32_t) 0x00000200)

#define  RCC_BDCR_RTCEN                      ((uint32_t) 0x00008000)
#define  RCC_BDCR_BDRST                      ((uint32_t) 0x00010000)

/* RCC clock control & status register */
#define  RCC_CSR_LSION                       ((uint32_t) 0x00000001)
#define  RCC_CSR_LSIRDY                      ((uint32_t) 0x00000002)
#define  RCC_CSR_RMVF                        ((uint32_t) 0x01000000)
#define  RCC_CSR_BORRSTF                     ((uint32_t) 0x02000000)
#define  RCC_CSR_PADRSTF                     ((uint32_t) 0x04000000)
#define  RCC_CSR_PORRSTF                     ((uint32_t) 0x08000000)
#define  RCC_CSR_SFTRSTF                     ((uint32_t) 0x10000000)
#define  RCC_CSR_WDGRSTF                     ((uint32_t) 0x20000000)
#define  RCC_CSR_WWDGRSTF                    ((uint32_t) 0x40000000)
#define  RCC_CSR_LPWRRSTF                    ((uint32_t) 0x80000000)

/* RCC spread spectrum clock generation register (RCC_SSCGR) */
#define  RCC_SSCGR_MODPER                    ((uint32_t) 0x00001FFF)
#define  RCC_SSCGR_INCSTEP                   ((uint32_t) 0x0FFFE000)
#define  RCC_SSCGR_SPREADSEL                 ((uint32_t) 0x40000000)
#define  RCC_SSCGR_SSCGEN                    ((uint32_t) 0x80000000)

/* RCC PLLI2S configuration register (RCC_PLLI2SCFGR) */
#define  RCC_PLLI2SCFGR_PLLI2SN              ((uint32_t) 0x00007FC0)
#define  RCC_PLLI2SCFGR_PLLI2SR              ((uint32_t) 0x70000000)

/* Exported Constants */
#define RCC_HSE_OFF                      ((uint8_t) 0x00)
#define RCC_HSE_ON                       ((uint8_t) 0x01)
#define RCC_HSE_Bypass                   ((uint8_t) 0x05)
#define IS_RCC_HSE(HSE) (((HSE) == RCC_HSE_OFF) || ((HSE) == RCC_HSE_ON) || \
                     ((HSE) == RCC_HSE_Bypass))

/* RCC_PLL_Clock_Source */
#define RCC_PLLSource_HSI                ((uint32_t) 0x00000000)
#define RCC_PLLSource_HSE                ((uint32_t) 0x00400000)
#define IS_RCC_PLL_SOURCE(SOURCE) (((SOURCE) == RCC_PLLSource_HSI) || \
                               ((SOURCE) == RCC_PLLSource_HSE))
#define IS_RCC_PLLM_VALUE(VALUE) ((VALUE) <= 63)
#define IS_RCC_PLLN_VALUE(VALUE) ((192 <= (VALUE)) && ((VALUE) <= 432))
#define IS_RCC_PLLP_VALUE(VALUE) (((VALUE) == 2) || ((VALUE) == 4) || ((VALUE) == 6) || ((VALUE) == 8))
#define IS_RCC_PLLQ_VALUE(VALUE) ((4 <= (VALUE)) && ((VALUE) <= 15))

#define IS_RCC_PLLI2SN_VALUE(VALUE) ((192 <= (VALUE)) && ((VALUE) <= 432))
#define IS_RCC_PLLI2SR_VALUE(VALUE) ((2 <= (VALUE)) && ((VALUE) <= 7))

/* RCC_System_Clock_Source */
#define RCC_SYSCLKSource_HSI             ((uint32_t) 0x00000000)
#define RCC_SYSCLKSource_HSE             ((uint32_t) 0x00000001)
#define RCC_SYSCLKSource_PLLCLK          ((uint32_t) 0x00000002)
#define IS_RCC_SYSCLK_SOURCE(SOURCE) (((SOURCE) == RCC_SYSCLKSource_HSI) || \
                                  ((SOURCE) == RCC_SYSCLKSource_HSE) || \
                                  ((SOURCE) == RCC_SYSCLKSource_PLLCLK))

/* RCC_AHB_Clock_Source */
#define RCC_SYSCLK_Div1                  ((uint32_t) 0x00000000)
#define RCC_SYSCLK_Div2                  ((uint32_t) 0x00000080)
#define RCC_SYSCLK_Div4                  ((uint32_t) 0x00000090)
#define RCC_SYSCLK_Div8                  ((uint32_t) 0x000000A0)
#define RCC_SYSCLK_Div16                 ((uint32_t) 0x000000B0)
#define RCC_SYSCLK_Div64                 ((uint32_t) 0x000000C0)
#define RCC_SYSCLK_Div128                ((uint32_t) 0x000000D0)
#define RCC_SYSCLK_Div256                ((uint32_t) 0x000000E0)
#define RCC_SYSCLK_Div512                ((uint32_t) 0x000000F0)
#define IS_RCC_HCLK(HCLK) (((HCLK) == RCC_SYSCLK_Div1) || ((HCLK) == RCC_SYSCLK_Div2) || \
                       ((HCLK) == RCC_SYSCLK_Div4) || ((HCLK) == RCC_SYSCLK_Div8) || \
                       ((HCLK) == RCC_SYSCLK_Div16) || ((HCLK) == RCC_SYSCLK_Div64) || \
                       ((HCLK) == RCC_SYSCLK_Div128) || ((HCLK) == RCC_SYSCLK_Div256) || \
                       ((HCLK) == RCC_SYSCLK_Div512))

/* RCC_APB1_APB2_Clock_Source */
#define RCC_HCLK_Div1                    ((uint32_t) 0x00000000)
#define RCC_HCLK_Div2                    ((uint32_t) 0x00001000)
#define RCC_HCLK_Div4                    ((uint32_t) 0x00001400)
#define RCC_HCLK_Div8                    ((uint32_t) 0x00001800)
#define RCC_HCLK_Div16                   ((uint32_t) 0x00001C00)
#define IS_RCC_PCLK(PCLK) (((PCLK) == RCC_HCLK_Div1) || ((PCLK) == RCC_HCLK_Div2) || \
                       ((PCLK) == RCC_HCLK_Div4) || ((PCLK) == RCC_HCLK_Div8) || \
                       ((PCLK) == RCC_HCLK_Div16))

/* RCC_Interrupt_Source */
#define RCC_IT_LSIRDY                    ((uint8_t) 0x01)
#define RCC_IT_LSERDY                    ((uint8_t) 0x02)
#define RCC_IT_HSIRDY                    ((uint8_t) 0x04)
#define RCC_IT_HSERDY                    ((uint8_t) 0x08)
#define RCC_IT_PLLRDY                    ((uint8_t) 0x10)
#define RCC_IT_PLLI2SRDY                 ((uint8_t) 0x20)
#define RCC_IT_CSS                       ((uint8_t) 0x80)
#define IS_RCC_IT(IT) ((((IT) & (uint8_t) 0xC0) == 0x00) && ((IT) != 0x00))
#define IS_RCC_GET_IT(IT) (((IT) == RCC_IT_LSIRDY) || ((IT) == RCC_IT_LSERDY) || \
                       ((IT) == RCC_IT_HSIRDY) || ((IT) == RCC_IT_HSERDY) || \
                       ((IT) == RCC_IT_PLLRDY) || ((IT) == RCC_IT_CSS) || \
                       ((IT) == RCC_IT_PLLI2SRDY))
#define IS_RCC_CLEAR_IT(IT) ((((IT) & (uint8_t) 0x40) == 0x00) && ((IT) != 0x00))

/* RCC_LSE_Configuration */
#define RCC_LSE_OFF                      ((uint8_t) 0x00)
#define RCC_LSE_ON                       ((uint8_t) 0x01)
#define RCC_LSE_Bypass                   ((uint8_t) 0x04)
#define IS_RCC_LSE(LSE) (((LSE) == RCC_LSE_OFF) || ((LSE) == RCC_LSE_ON) || \
                     ((LSE) == RCC_LSE_Bypass))

/* RCC_RTC_Clock_Source */
#define RCC_RTCCLKSource_LSE             ((uint32_t) 0x00000100)
#define RCC_RTCCLKSource_LSI             ((uint32_t) 0x00000200)
#define RCC_RTCCLKSource_HSE_Div2        ((uint32_t) 0x00020300)
#define RCC_RTCCLKSource_HSE_Div3        ((uint32_t) 0x00030300)
#define RCC_RTCCLKSource_HSE_Div4        ((uint32_t) 0x00040300)
#define RCC_RTCCLKSource_HSE_Div5        ((uint32_t) 0x00050300)
#define RCC_RTCCLKSource_HSE_Div6        ((uint32_t) 0x00060300)
#define RCC_RTCCLKSource_HSE_Div7        ((uint32_t) 0x00070300)
#define RCC_RTCCLKSource_HSE_Div8        ((uint32_t) 0x00080300)
#define RCC_RTCCLKSource_HSE_Div9        ((uint32_t) 0x00090300)
#define RCC_RTCCLKSource_HSE_Div10       ((uint32_t) 0x000A0300)
#define RCC_RTCCLKSource_HSE_Div11       ((uint32_t) 0x000B0300)
#define RCC_RTCCLKSource_HSE_Div12       ((uint32_t) 0x000C0300)
#define RCC_RTCCLKSource_HSE_Div13       ((uint32_t) 0x000D0300)
#define RCC_RTCCLKSource_HSE_Div14       ((uint32_t) 0x000E0300)
#define RCC_RTCCLKSource_HSE_Div15       ((uint32_t) 0x000F0300)
#define RCC_RTCCLKSource_HSE_Div16       ((uint32_t) 0x00100300)
#define RCC_RTCCLKSource_HSE_Div17       ((uint32_t) 0x00110300)
#define RCC_RTCCLKSource_HSE_Div18       ((uint32_t) 0x00120300)
#define RCC_RTCCLKSource_HSE_Div19       ((uint32_t) 0x00130300)
#define RCC_RTCCLKSource_HSE_Div20       ((uint32_t) 0x00140300)
#define RCC_RTCCLKSource_HSE_Div21       ((uint32_t) 0x00150300)
#define RCC_RTCCLKSource_HSE_Div22       ((uint32_t) 0x00160300)
#define RCC_RTCCLKSource_HSE_Div23       ((uint32_t) 0x00170300)
#define RCC_RTCCLKSource_HSE_Div24       ((uint32_t) 0x00180300)
#define RCC_RTCCLKSource_HSE_Div25       ((uint32_t) 0x00190300)
#define RCC_RTCCLKSource_HSE_Div26       ((uint32_t) 0x001A0300)
#define RCC_RTCCLKSource_HSE_Div27       ((uint32_t) 0x001B0300)
#define RCC_RTCCLKSource_HSE_Div28       ((uint32_t) 0x001C0300)
#define RCC_RTCCLKSource_HSE_Div29       ((uint32_t) 0x001D0300)
#define RCC_RTCCLKSource_HSE_Div30       ((uint32_t) 0x001E0300)
#define RCC_RTCCLKSource_HSE_Div31       ((uint32_t) 0x001F0300)
#define IS_RCC_RTCCLK_SOURCE(SOURCE) (((SOURCE) == RCC_RTCCLKSource_LSE) || \
                                      ((SOURCE) == RCC_RTCCLKSource_LSI) || \
                                      ((SOURCE) == RCC_RTCCLKSource_HSE_Div2) || \
                                      ((SOURCE) == RCC_RTCCLKSource_HSE_Div3) || \
                                      ((SOURCE) == RCC_RTCCLKSource_HSE_Div4) || \
                                      ((SOURCE) == RCC_RTCCLKSource_HSE_Div5) || \
                                      ((SOURCE) == RCC_RTCCLKSource_HSE_Div6) || \
                                      ((SOURCE) == RCC_RTCCLKSource_HSE_Div7) || \
                                      ((SOURCE) == RCC_RTCCLKSource_HSE_Div8) || \
                                      ((SOURCE) == RCC_RTCCLKSource_HSE_Div9) || \
                                      ((SOURCE) == RCC_RTCCLKSource_HSE_Div10) || \
                                      ((SOURCE) == RCC_RTCCLKSource_HSE_Div11) || \
                                      ((SOURCE) == RCC_RTCCLKSource_HSE_Div12) || \
                                      ((SOURCE) == RCC_RTCCLKSource_HSE_Div13) || \
                                      ((SOURCE) == RCC_RTCCLKSource_HSE_Div14) || \
                                      ((SOURCE) == RCC_RTCCLKSource_HSE_Div15) || \
                                      ((SOURCE) == RCC_RTCCLKSource_HSE_Div16) || \
                                      ((SOURCE) == RCC_RTCCLKSource_HSE_Div17) || \
                                      ((SOURCE) == RCC_RTCCLKSource_HSE_Div18) || \
                                      ((SOURCE) == RCC_RTCCLKSource_HSE_Div19) || \
                                      ((SOURCE) == RCC_RTCCLKSource_HSE_Div20) || \
                                      ((SOURCE) == RCC_RTCCLKSource_HSE_Div21) || \
                                      ((SOURCE) == RCC_RTCCLKSource_HSE_Div22) || \
                                      ((SOURCE) == RCC_RTCCLKSource_HSE_Div23) || \
                                      ((SOURCE) == RCC_RTCCLKSource_HSE_Div24) || \
                                      ((SOURCE) == RCC_RTCCLKSource_HSE_Div25) || \
                                      ((SOURCE) == RCC_RTCCLKSource_HSE_Div26) || \
                                      ((SOURCE) == RCC_RTCCLKSource_HSE_Div27) || \
                                      ((SOURCE) == RCC_RTCCLKSource_HSE_Div28) || \
                                      ((SOURCE) == RCC_RTCCLKSource_HSE_Div29) || \
                                      ((SOURCE) == RCC_RTCCLKSource_HSE_Div30) || \
                                      ((SOURCE) == RCC_RTCCLKSource_HSE_Div31))
/* RCC_I2S_Clock_Source */
#define RCC_I2S2CLKSource_PLLI2S             ((uint8_t) 0x00)
#define RCC_I2S2CLKSource_Ext                ((uint8_t) 0x01)
#define IS_RCC_I2SCLK_SOURCE(SOURCE) (((SOURCE) == RCC_I2S2CLKSource_PLLI2S) || ((SOURCE) == RCC_I2S2CLKSource_Ext))

/* RCC_AHB1_Peripherals */
#define RCC_AHB1Periph_GPIOA             ((uint32_t) 0x00000001)
#define RCC_AHB1Periph_GPIOB             ((uint32_t) 0x00000002)
#define RCC_AHB1Periph_GPIOC             ((uint32_t) 0x00000004)
#define RCC_AHB1Periph_GPIOD             ((uint32_t) 0x00000008)
#define RCC_AHB1Periph_GPIOE             ((uint32_t) 0x00000010)
#define RCC_AHB1Periph_GPIOF             ((uint32_t) 0x00000020)
#define RCC_AHB1Periph_GPIOG             ((uint32_t) 0x00000040)
#define RCC_AHB1Periph_GPIOH             ((uint32_t) 0x00000080)
#define RCC_AHB1Periph_GPIOI             ((uint32_t) 0x00000100)
#define RCC_AHB1Periph_CRC               ((uint32_t) 0x00001000)
#define RCC_AHB1Periph_FLITF             ((uint32_t) 0x00008000)
#define RCC_AHB1Periph_SRAM1             ((uint32_t) 0x00010000)
#define RCC_AHB1Periph_SRAM2             ((uint32_t) 0x00020000)
#define RCC_AHB1Periph_BKPSRAM           ((uint32_t) 0x00040000)
#define RCC_AHB1Periph_CCMDATARAMEN      ((uint32_t) 0x00100000)
#define RCC_AHB1Periph_DMA1              ((uint32_t) 0x00200000)
#define RCC_AHB1Periph_DMA2              ((uint32_t) 0x00400000)
#define RCC_AHB1Periph_ETH_MAC           ((uint32_t) 0x02000000)
#define RCC_AHB1Periph_ETH_MAC_Tx        ((uint32_t) 0x04000000)
#define RCC_AHB1Periph_ETH_MAC_Rx        ((uint32_t) 0x08000000)
#define RCC_AHB1Periph_ETH_MAC_PTP       ((uint32_t) 0x10000000)
#define RCC_AHB1Periph_OTG_HS            ((uint32_t) 0x20000000)
#define RCC_AHB1Periph_OTG_HS_ULPI       ((uint32_t) 0x40000000)
#define IS_RCC_AHB1_CLOCK_PERIPH(PERIPH) ((((PERIPH) & 0x818BEE00) == 0x00) && ((PERIPH) != 0x00))
#define IS_RCC_AHB1_RESET_PERIPH(PERIPH) ((((PERIPH) & 0xDD9FEE00) == 0x00) && ((PERIPH) != 0x00))
#define IS_RCC_AHB1_LPMODE_PERIPH(PERIPH) ((((PERIPH) & 0x81986E00) == 0x00) && ((PERIPH) != 0x00))

/* RCC_AHB2_Peripherals */
#define RCC_AHB2Periph_DCMI              ((uint32_t) 0x00000001)
#define RCC_AHB2Periph_CRYP              ((uint32_t) 0x00000010)
#define RCC_AHB2Periph_HASH              ((uint32_t) 0x00000020)
#define RCC_AHB2Periph_RNG               ((uint32_t) 0x00000040)
#define RCC_AHB2Periph_OTG_FS            ((uint32_t) 0x00000080)
#define IS_RCC_AHB2_PERIPH(PERIPH) ((((PERIPH) & 0xFFFFFF0E) == 0x00) && ((PERIPH) != 0x00))

/* RCC_AHB3_Peripherals */
#define RCC_AHB3Periph_FSMC               ((uint32_t) 0x00000001)
#define IS_RCC_AHB3_PERIPH(PERIPH) ((((PERIPH) & 0xFFFFFFFE) == 0x00) && ((PERIPH) != 0x00))

/* RCC_APB1_Peripherals */
#define RCC_APB1Periph_TIM2              ((uint32_t) 0x00000001)
#define RCC_APB1Periph_TIM3              ((uint32_t) 0x00000002)
#define RCC_APB1Periph_TIM4              ((uint32_t) 0x00000004)
#define RCC_APB1Periph_TIM5              ((uint32_t) 0x00000008)
#define RCC_APB1Periph_TIM6              ((uint32_t) 0x00000010)
#define RCC_APB1Periph_TIM7              ((uint32_t) 0x00000020)
#define RCC_APB1Periph_TIM12             ((uint32_t) 0x00000040)
#define RCC_APB1Periph_TIM13             ((uint32_t) 0x00000080)
#define RCC_APB1Periph_TIM14             ((uint32_t) 0x00000100)
#define RCC_APB1Periph_WWDG              ((uint32_t) 0x00000800)
#define RCC_APB1Periph_SPI2              ((uint32_t) 0x00004000)
#define RCC_APB1Periph_SPI3              ((uint32_t) 0x00008000)
#define RCC_APB1Periph_USART2            ((uint32_t) 0x00020000)
#define RCC_APB1Periph_USART3            ((uint32_t) 0x00040000)
#define RCC_APB1Periph_UART4             ((uint32_t) 0x00080000)
#define RCC_APB1Periph_UART5             ((uint32_t) 0x00100000)
#define RCC_APB1Periph_I2C1              ((uint32_t) 0x00200000)
#define RCC_APB1Periph_I2C2              ((uint32_t) 0x00400000)
#define RCC_APB1Periph_I2C3              ((uint32_t) 0x00800000)
#define RCC_APB1Periph_CAN1              ((uint32_t) 0x02000000)
#define RCC_APB1Periph_CAN2              ((uint32_t) 0x04000000)
#define RCC_APB1Periph_PWR               ((uint32_t) 0x10000000)
#define RCC_APB1Periph_DAC               ((uint32_t) 0x20000000)
#define IS_RCC_APB1_PERIPH(PERIPH) ((((PERIPH) & 0xC9013600) == 0x00) && ((PERIPH) != 0x00))

/* RCC_APB2_Peripherals */
#define RCC_APB2Periph_TIM1              ((uint32_t) 0x00000001)
#define RCC_APB2Periph_TIM8              ((uint32_t) 0x00000002)
#define RCC_APB2Periph_USART1            ((uint32_t) 0x00000010)
#define RCC_APB2Periph_USART6            ((uint32_t) 0x00000020)
#define RCC_APB2Periph_ADC               ((uint32_t) 0x00000100)
#define RCC_APB2Periph_ADC1              ((uint32_t) 0x00000100)
#define RCC_APB2Periph_ADC2              ((uint32_t) 0x00000200)
#define RCC_APB2Periph_ADC3              ((uint32_t) 0x00000400)
#define RCC_APB2Periph_SDIO              ((uint32_t) 0x00000800)
#define RCC_APB2Periph_SPI1              ((uint32_t) 0x00001000)
#define RCC_APB2Periph_SYSCFG            ((uint32_t) 0x00004000)
#define RCC_APB2Periph_TIM9              ((uint32_t) 0x00010000)
#define RCC_APB2Periph_TIM10             ((uint32_t) 0x00020000)
#define RCC_APB2Periph_TIM11             ((uint32_t) 0x00040000)
#define IS_RCC_APB2_PERIPH(PERIPH) ((((PERIPH) & 0xFFF8A0CC) == 0x00) && ((PERIPH) != 0x00))
#define IS_RCC_APB2_RESET_PERIPH(PERIPH) ((((PERIPH) & 0xFFF8A6CC) == 0x00) && ((PERIPH) != 0x00))

/* RCC_MCO1_Clock_Source_Prescaler */
#define RCC_MCO1Source_HSI               ((uint32_t) 0x00000000)
#define RCC_MCO1Source_LSE               ((uint32_t) 0x00200000)
#define RCC_MCO1Source_HSE               ((uint32_t) 0x00400000)
#define RCC_MCO1Source_PLLCLK            ((uint32_t) 0x00600000)
#define RCC_MCO1Div_1                    ((uint32_t) 0x00000000)
#define RCC_MCO1Div_2                    ((uint32_t) 0x04000000)
#define RCC_MCO1Div_3                    ((uint32_t) 0x05000000)
#define RCC_MCO1Div_4                    ((uint32_t) 0x06000000)
#define RCC_MCO1Div_5                    ((uint32_t) 0x07000000)
#define IS_RCC_MCO1SOURCE(SOURCE) (((SOURCE) == RCC_MCO1Source_HSI) || ((SOURCE) == RCC_MCO1Source_LSE) || \
                               ((SOURCE) == RCC_MCO1Source_HSE) || ((SOURCE) == RCC_MCO1Source_PLLCLK))

#define IS_RCC_MCO1DIV(DIV) (((DIV) == RCC_MCO1Div_1) || ((DIV) == RCC_MCO1Div_2) || \
                         ((DIV) == RCC_MCO1Div_3) || ((DIV) == RCC_MCO1Div_4) || \
                         ((DIV) == RCC_MCO1Div_5))

/* RCC_MCO2_Clock_Source_Prescaler */
#define RCC_MCO2Source_SYSCLK            ((uint32_t) 0x00000000)
#define RCC_MCO2Source_PLLI2SCLK         ((uint32_t) 0x40000000)
#define RCC_MCO2Source_HSE               ((uint32_t) 0x80000000)
#define RCC_MCO2Source_PLLCLK            ((uint32_t) 0xC0000000)
#define RCC_MCO2Div_1                    ((uint32_t) 0x00000000)
#define RCC_MCO2Div_2                    ((uint32_t) 0x20000000)
#define RCC_MCO2Div_3                    ((uint32_t) 0x28000000)
#define RCC_MCO2Div_4                    ((uint32_t) 0x30000000)
#define RCC_MCO2Div_5                    ((uint32_t) 0x38000000)
#define IS_RCC_MCO2SOURCE(SOURCE) (((SOURCE) == RCC_MCO2Source_SYSCLK) || ((SOURCE) == RCC_MCO2Source_PLLI2SCLK)|| \
                               ((SOURCE) == RCC_MCO2Source_HSE) || ((SOURCE) == RCC_MCO2Source_PLLCLK))

#define IS_RCC_MCO2DIV(DIV) (((DIV) == RCC_MCO2Div_1) || ((DIV) == RCC_MCO2Div_2) || \
                         ((DIV) == RCC_MCO2Div_3) || ((DIV) == RCC_MCO2Div_4) || \
                         ((DIV) == RCC_MCO2Div_5))

/* RCC_Flag */
#define RCC_FLAG_HSIRDY                  ((uint8_t) 0x21)
#define RCC_FLAG_HSERDY                  ((uint8_t) 0x31)
#define RCC_FLAG_PLLRDY                  ((uint8_t) 0x39)
#define RCC_FLAG_PLLI2SRDY               ((uint8_t) 0x3B)
#define RCC_FLAG_LSERDY                  ((uint8_t) 0x41)
#define RCC_FLAG_LSIRDY                  ((uint8_t) 0x61)
#define RCC_FLAG_BORRST                  ((uint8_t) 0x79)
#define RCC_FLAG_PINRST                  ((uint8_t) 0x7A)
#define RCC_FLAG_PORRST                  ((uint8_t) 0x7B)
#define RCC_FLAG_SFTRST                  ((uint8_t) 0x7C)
#define RCC_FLAG_IWDGRST                 ((uint8_t) 0x7D)
#define RCC_FLAG_WWDGRST                 ((uint8_t) 0x7E)
#define RCC_FLAG_LPWRRST                 ((uint8_t) 0x7F)
#define IS_RCC_FLAG(FLAG) (((FLAG) == RCC_FLAG_HSIRDY) || ((FLAG) == RCC_FLAG_HSERDY) || \
                       ((FLAG) == RCC_FLAG_PLLRDY) || ((FLAG) == RCC_FLAG_LSERDY) || \
                       ((FLAG) == RCC_FLAG_LSIRDY) || ((FLAG) == RCC_FLAG_BORRST) || \
                       ((FLAG) == RCC_FLAG_PINRST) || ((FLAG) == RCC_FLAG_PORRST) || \
                       ((FLAG) == RCC_FLAG_SFTRST) || ((FLAG) == RCC_FLAG_IWDGRST)|| \
                       ((FLAG) == RCC_FLAG_WWDGRST)|| ((FLAG) == RCC_FLAG_LPWRRST)|| \
                       ((FLAG) == RCC_FLAG_PLLI2SRDY))
#define IS_RCC_CALIBRATION_VALUE(VALUE) ((VALUE) <= 0x1F)

/**
 * \brief Reset the RCC clock configuration
 */
void soc_rcc_reset(void);

/*
 * \brief Configures the System clock source, PLL Multiplier and Divider factors,
 * AHB/APBx prescalers and Flash settings
 *
 *
 * This function should be called only once the RCC clock configuration
 * is reset to the default reset state (done in SystemInit() function).
 *
 */
void soc_rcc_setsysclock(bool enable_hse, bool enable_pll);

#endif /*!SOC_RCC_H */
