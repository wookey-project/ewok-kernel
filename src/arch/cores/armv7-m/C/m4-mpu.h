/* \file m4-mpu.h
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
#ifndef _M4_MPU_H
#define _M4_MPU_H
#include "product.h"

#include "soc-core.h"
#include "soc-layout.h"

/* MPU region fields are based on values defined in m4-mpu-regions.h header */
#include "m4-mpu-regions.h"

#define MPU_LAST_REGION         7

/* The MPU divides the memory map into a number of regions and defines the location size
 * access permissions and memory attributes of each region. It supports:
 * • Independent attribute settings for each region
 * • Overlapping regions
 * • Export of memory attributes to the system.
 *
 * The memory attributes affect the behavior of memory accesses to the region. The CortexM4
 * MPU defines:
 * • Eight separate memory regions 0-7
 * • A background region.
 * When memory regions overlap a memory access is affected by the attributes of the region
 * with the highest number. For example the attributes for region 7 take precedence over the
 * attributes of any region that overlaps region 7.
 * The background region has the same memory access attributes as the default memory
 * map but is accessible from privileged software only.
 *
 * The Cortex-M4 MPU memory map is unified. This means instruction accesses and data
 * accesses have same region settings.
 *
 * If a program accesses a memory location that is prohibited by the MPU the processor
 * generates a memory management fault. This causes a fault exception and might cause
 * termination of the process in an OS environment.
 *
 * In an OS environment the kernel can update the MPU region setting dynamically based on
 * the process to be executed. Typically an embedded OS uses the MPU for memory
 * protection.
 */

// FIXME Where should this flag be declared ?
#define __MPU_PRESENT 1

/* Following definitions are valid only for Cortex-M4 */
#if (__MPU_PRESENT == 1)
#define r_CORTEX_M_MPU_TYPER                REG_ADDR(MPU_BASE + 0x00)
#define r_CORTEX_M_MPU_CTRL                 REG_ADDR(MPU_BASE + 0x04)
#define r_CORTEX_M_MPU_RNR                  REG_ADDR(MPU_BASE + 0x08)
#define r_CORTEX_M_MPU_RBAR                 REG_ADDR(MPU_BASE + 0x0C)
#define r_CORTEX_M_MPU_RASR                 REG_ADDR(MPU_BASE + 0x10)
#define r_CORTEX_M_MPU_RBAR_A1              REG_ADDR(MPU_BASE + 0x14)   /* Alias of MPU_RBAR register */
#define r_CORTEX_M_MPU_RASR_A1              REG_ADDR(MPU_BASE + 0x18)   /* Alias of MPU_RASR register */
#define r_CORTEX_M_MPU_RBAR_A2              REG_ADDR(MPU_BASE + 0x1C)   /* Alias of MPU_RBAR register */
#define r_CORTEX_M_MPU_RASR_A2              REG_ADDR(MPU_BASE + 0x20)   /* Alias of MPU_RASR register */
#define r_CORTEX_M_MPU_RBAR_A3              REG_ADDR(MPU_BASE + 0x1C)   /* Alias of MPU_RBAR register */
#define r_CORTEX_M_MPU_RASR_A3              REG_ADDR(MPU_BASE + 0x20)   /* Alias of MPU_RASR register */

/* MPU type register (MPU_TYPER) */
#define MPU_TYPER_IREGION_Pos               16
#define MPU_TYPER_IREGION_Msk               ((uint32_t) 0xFF << MPU_TYPE_IREGION_Pos)

#define MPU_TYPER_DREGION_Pos                8
#define MPU_TYPER_DREGION_Msk               ((uint32_t) 0xFF << MPU_TYPE_DREGION_Pos)

#define MPU_TYPER_SEPARATE_Pos               0
#define MPU_TYPER_SEPARATE_Msk              ((uint32_t) 0x01 << MPU_TYPE_SEPARATE_Pos)

/* MPU control register (MPU_CTRL) */
#define MPU_CTRL_PRIVDEFENA_Pos             2
#define MPU_CTRL_PRIVDEFENA_Msk            ((uint32_t) 0x01 << MPU_CTRL_PRIVDEFENA_Pos)

#define MPU_CTRL_HFNMIENA_Pos               1
#define MPU_CTRL_HFNMIENA_Msk              ((uint32_t) 0x01 << MPU_CTRL_HFNMIENA_Pos)

#define MPU_CTRL_ENABLE_Pos                 0
#define MPU_CTRL_ENABLE_Msk                ((uint32_t) 0x01 << MPU_CTRL_ENABLE_Pos)

/* MPU region number register (MPU_RNR) */
#define MPU_RNBR_REGION_Pos                  0
#define MPU_RNBR_REGION_Msk                 ((uint32_t) 0xFF << MPU_RNBR_REGION_Pos)

/* MPU region base address register (MPU_RBAR) */
#define MPU_RBAR_ADDR_Pos                   5
#define MPU_RBAR_ADDR_Msk                  ((uint32_t) 0x7FFFFFF << MPU_RBAR_ADDR_Pos)

#define MPU_RBAR_VALID_Pos                  4
#define MPU_RBAR_VALID_Msk                 ((uint32_t) 0x01 << MPU_RBAR_VALID_Pos)

#define MPU_RBAR_REGION_Pos                 0
#define MPU_RBAR_REGION_Msk                ((uint32_t) 0xF << MPU_RBAR_REGION_Pos)

/* MPU region attribute and size register (MPU_RASR) */
#define MPU_RASR_XN_Pos                     28
#define MPU_RASR_XN_Msk                     ((uint32_t) 0x1 << MPU_RASR_XN_Pos)

#define MPU_RASR_AP_Pos                     24
#define MPU_RASR_AP_Msk                     ((uint32_t) 0x07 << MPU_RASR_AP_Pos)

#define MPU_RASR_TEX_Pos                    19
#define MPU_RASR_TEX_Msk                    ((uint32_t) 0x07 << MPU_RASR_TEX_Pos)

#define MPU_RASR_S_Pos	                    18
#define MPU_RASR_S_Msk                      ((uint32_t) 0x01 << MPU_RASR_S_Pos)

#define MPU_RASR_C_Pos	                    17
#define MPU_RASR_C_Msk                      ((uint32_t) 0x01 << MPU_RASR_C_Pos)

#define MPU_RASR_B_Pos	                    16
#define MPU_RASR_B_Msk                      ((uint32_t) 0x01 << MPU_RASR_B_Pos)

#define MPU_RASR_SRD_Pos                    8
#define MPU_RASR_SRD_Msk                    ((uint32_t) 0xFF << MPU_RASR_SRD_Pos)

#define MPU_RASR_SIZE_Pos                   1
#define MPU_RASR_SIZE_Msk                   ((uint32_t) 0x3F << MPU_RASR_SIZE_Pos)

#define MPU_RASR_EN_Pos                     0
#define MPU_RASR_EN_Msk                     ((uint32_t) 0x01 << MPU_RASR_EN_Pos)

#define MPU_RASR_PERM_ATTRS(AP, TEX, C, B, S) \
    ((AP << MPU_RASR_AP_Pos)  |\
    (TEX << MPU_RASR_TEX_Pos) |\
    (C   << MPU_RASR_C_Pos)   |\
    (B   << MPU_RASR_B_Pos)   |\
    (S   << MPU_RASR_S_Pos))

typedef struct region_config_t {
    unsigned int region_number;
    unsigned long int addr;
    unsigned int size;
    unsigned long int access_perm;
    unsigned int xn;
    unsigned int b;
    unsigned int s;
    uint8_t mask;
} region_config;

void core_mpu_init(uint8_t privdefenable, void *mpu_Handler);

void core_mpu_enable(uint8_t enable);

uint8_t core_mpu_region_disable(uint8_t region_number);

uint8_t core_mpu_region_config(region_config * region);

uint8_t core_mpu_update_subregion_mask(region_config * region);

uint8_t core_mpu_bytes_to_region_size (uint32_t bytes);

#endif
#endif                          /* _STM32F4XX_MPU_H */
