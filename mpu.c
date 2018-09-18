/* \file mpu.c
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

#include "m4-mpu.h"
#include "soc-layout.h"
#include "layout.h"
#include "shared.h"
#include "autoconf.h"
#include "debug.h"
#include "tasks.h"
#include "kernel.h"
#include "mpu.h"
#include "sched.h"
#include "generated/apps_layout.h"

extern const shr_vars_t shared_vars;
extern void MemManage_Handler(void);

uint8_t mpu_regions_schedule(uint8_t region_number,
                             physaddr_t addr,
                             uint16_t size, e_region_type type, uint8_t mask)
{
    region_config my_region;

    my_region.size = size;
    my_region.region_number = region_number;
    my_region.addr = (uint32_t) addr;

    switch (type) {
    case MPU_REGION_USER_DEV:
        my_region.access_perm = MPU_REGION_RW_RW;
        my_region.xn = MPU_PERMISSION_YES;
        my_region.b = MPU_PERMISSION_YES;
        my_region.s = MPU_PERMISSION_YES;
        my_region.mask = mask;
        if (core_mpu_region_config(&my_region)) {
            return 1;
        }
        break;
    case MPU_REGION_RO_USER_DEV:
        my_region.access_perm = MPU_REGION_RW_RO;
        my_region.xn = MPU_PERMISSION_YES;
        my_region.b = MPU_PERMISSION_YES;
        my_region.s = MPU_PERMISSION_YES;
        my_region.mask = mask;
        if (core_mpu_region_config(&my_region)) {
            return 1;
        }
        break;

    case MPU_REGION_USER_TXT:
        my_region.access_perm = MPU_REGION_RO_RO;
        my_region.xn = MPU_PERMISSION_NO;
        my_region.b = MPU_PERMISSION_NO;
        my_region.s = MPU_PERMISSION_NO;
        my_region.mask = mask;
        if (core_mpu_update_subregion_mask(&my_region)) {
            return 1;
        }
        break;
    case MPU_REGION_USER_RAM:
        my_region.access_perm = MPU_REGION_RW_RW;
        my_region.xn = MPU_PERMISSION_YES;
        my_region.b = MPU_PERMISSION_NO;
        my_region.s = MPU_PERMISSION_YES;
        my_region.mask = mask;
        if (core_mpu_update_subregion_mask(&my_region)) {
            return 1;
        }
        break;
    case MPU_REGION_BOOTROM:
        my_region.access_perm = MPU_REGION_NO_NO;
        my_region.xn = MPU_PERMISSION_YES;
        my_region.b = MPU_PERMISSION_NO;
        my_region.s = MPU_PERMISSION_NO;
        my_region.mask = 0;
        if (core_mpu_region_config(&my_region)) {
            return 1;
        }
        break;
    case MPU_REGION_ISR_RAM:
        my_region.access_perm = MPU_REGION_RW_RW;
        my_region.xn = MPU_PERMISSION_YES;
        my_region.b = MPU_PERMISSION_NO;
        my_region.s = MPU_PERMISSION_YES;
        my_region.mask = 0;
        if (core_mpu_region_config(&my_region)) {
            return 1;
        }
        break;
    }
    return 0;
}

uint8_t mpu_kernel_init(void)
{
    region_config my_region;

    /* registering kernel memory fault handler */
    set_interrupt_handler(MEMMANAGE_IRQ, MemManage_Handler, 0, ID_DEV_UNUSED);

    core_mpu_init(1, NULL);
    KERNLOG(DBG_NOTICE, "MPU Initialized\n");
    dbg_flush();

    /* SHR */
    my_region.region_number = 0;
    my_region.addr = SHR_BASE;
    my_region.size = MPU_REGION_SIZE_32Kb;
    my_region.access_perm = MPU_REGION_RO_RO;
    my_region.xn = MPU_PERMISSION_YES;
    my_region.b = MPU_PERMISSION_NO;
    my_region.s = MPU_PERMISSION_NO;
    my_region.mask = 0;

    if (core_mpu_region_config(&my_region)) {
        ERROR("Unable to map SHR !\n");
        return 1;
    }

    /* Current kernel code */
    my_region.region_number = 1;
    my_region.addr = TXT_KERN_REGION_BASE;
    my_region.size = TXT_KERN_REGION_SIZE;
    my_region.access_perm = MPU_REGION_RO_NO;
    my_region.xn = MPU_PERMISSION_NO;
    my_region.b = MPU_PERMISSION_NO;
    my_region.s = MPU_PERMISSION_NO;
    my_region.mask = 0;

    if (core_mpu_region_config(&my_region)) {
        ERROR("Unable to map kernel !\n");
        return 1;
    }

    /* Devices: TODO 512Kb should be abstracted in soc-layout */
    my_region.region_number = 2;
    my_region.addr = PERIPH_BASE;
    my_region.size = MPU_REGION_SIZE_512Kb;
    my_region.access_perm = MPU_REGION_RW_NO;
    my_region.xn = MPU_PERMISSION_YES;
    my_region.b = MPU_PERMISSION_YES;
    my_region.s = MPU_PERMISSION_YES;
    my_region.mask = 0;

    if (core_mpu_region_config(&my_region)) {
        ERROR("Unable to map devices !\n");
        return 1;
    }

    /* kernel data + stacks */
    my_region.region_number = 3;
    my_region.addr = RAM_KERN_BASE;
    my_region.size = RAM_KERN_REGION_SIZE;
    my_region.access_perm = MPU_REGION_RW_NO;
    my_region.xn = MPU_PERMISSION_YES;
    my_region.b = MPU_PERMISSION_NO;
    my_region.s = MPU_PERMISSION_YES;
    my_region.mask = 0;

    if (core_mpu_region_config(&my_region)) {
        ERROR("Unable to map kernel RAM !\n");
        return 1;
    }

    /* SRAM_USER area */
    my_region.region_number = 4;
    my_region.addr = RAM_USER_BASE;
    my_region.size = RAM_USER_REGION_SIZE;
    my_region.access_perm = MPU_REGION_RW_RW;
    my_region.xn = MPU_PERMISSION_YES;
    my_region.b = MPU_PERMISSION_NO;
    my_region.s = MPU_PERMISSION_YES;
    my_region.mask = 0;

    if (core_mpu_region_config(&my_region)) {
        ERROR("Unable to map kernel RAM !\n");
        return 1;
    }

    /* USER txt area */
    my_region.region_number = 5;
    my_region.addr = TXT_USER_REGION_BASE;
    my_region.size = TXT_USER_REGION_SIZE;
    my_region.access_perm = MPU_REGION_RO_RO;
    my_region.xn = MPU_PERMISSION_NO;
    my_region.b = MPU_PERMISSION_NO;
    my_region.s = MPU_PERMISSION_NO;
    my_region.mask = 0;

    if (core_mpu_region_config(&my_region)) {
        ERROR("Unable to map user text !\n");
        return 1;
    }


    /* 
     * User ISR stack 
     * Note: STM32F4 MPU does not properly handle overlapping memory regions.
     * We may need to disable the MPU during sub-region reconfiguration
     * to avoid some hardware (?) bug.
     */

    my_region.region_number = 6;
    my_region.addr = (uint32_t) STACK_TOP_ISR - STACK_SIZE_ISR;
    my_region.size = MPU_REGION_SIZE_4Kb;
    my_region.access_perm = MPU_REGION_RW_RW;
    my_region.xn = MPU_PERMISSION_YES;
    my_region.b = MPU_PERMISSION_NO;
    my_region.s = MPU_PERMISSION_YES;
    my_region.mask = 0;
    if (core_mpu_region_config(&my_region)) {
        ERROR("Unable to lock isr ram !\n");
        return 1;
    }

    KERNLOG(DBG_NOTICE, "MPU Configured\n");
    dbg_flush();

    core_mpu_enable(1);
    KERNLOG(DBG_NOTICE, "MPU Enabled\n");
    dbg_flush();
    return 0;
}
