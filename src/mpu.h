/* \file mpu.h
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

#ifndef KERNEL_MPU
#define KERNEL_MPU

#ifdef CONFIG_ARCH_ARMV7M
#include "m4-mpu.h"
#else
#error "no MPU arch-specific backend found!"
#endif

#ifdef CONFIG_SHM
/* last slot is always mapped for SHM */
static const uint8_t mpu_region_mask[] =
    { 0x7e, 0x7d, 0x7b, 0x77, 0x6f, 0x5f, 0x3f };
#else
static const uint8_t mpu_region_mask[] =
    { 0xfe, 0xfd, 0xfb, 0xf7, 0xef, 0xdf, 0xbf };
#endif

typedef enum {
        MPU_REGION_USER_RAM = 0,
        MPU_REGION_USER_TXT,
        MPU_REGION_USER_DEV,
        MPU_REGION_RO_USER_DEV,
        MPU_REGION_BOOTROM,
        MPU_REGION_ISR_RAM,
} e_region_type;

/*
** Define the max number of independent MPU region usable by userspace to map their device
** This depends on the MPU permissions and the kernel usage of the MPU.
** [PTH]: TODO: Should be a consquence of the configuration (Kconfig set)
*/
#define MPU_MAX_EMPTY_REGIONS   2
#define MPU_BOOT_ROM_REGION     3
#define MPU_USER_RAM_REGION     4
#define MPU_USER_TXT_REGION     5
#define MPU_USER_ISR_RAM_REGION 6

uint8_t mpu_kernel_init(void);

uint8_t mpu_regions_schedule(uint8_t region_number,
                             physaddr_t addr,
                             uint16_t size, e_region_type type, uint8_t mask);

#endif                          /*!KERNEL_MPU */
