/* m4-mpu.c
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

/** @file m4-mpu.c
 * Handles MPU utilization.
 *
 * See PM0214 (DocID022708 Rev 5)
 * and AN4838 (DocID029037 Rev 1)
 */

#include "autoconf.h"
#include "product.h"
#include "debug.h"

/*
 * TODO: maybe we should rename "soc_scb.h", as the Kconfig system only include the correct SoC path.
 * the 'stm32f4xx_ prefix should be kept only for IP drivers hosted in SoC dir, not for SoC global
 * description headers.
 */
#include "soc-scb.h"
#include "m4-mpu.h"

uint8_t core_mpu_update_subregion_mask(region_config * region)
{
    uint32_t reg = 0;

    /* Configure region */
    set_reg_value(r_CORTEX_M_MPU_RNR, region->region_number,
                  MPU_RNBR_REGION_Msk, MPU_RNBR_REGION_Pos);
    // and update its subregion here (reconfigure RASR)
    // the least mask bit mask the first subregion (8 bits for 8 subregions)
    set_reg_value(&reg, region->access_perm, MPU_RASR_AP_Msk, MPU_RASR_AP_Pos);
    set_reg_value(&reg, region->xn, MPU_RASR_XN_Msk, MPU_RASR_XN_Pos);
    set_reg_value(&reg, region->b, MPU_RASR_B_Msk, MPU_RASR_B_Pos);
    set_reg_value(&reg, region->s, MPU_RASR_S_Msk, MPU_RASR_S_Pos);
    set_reg_value(&reg, region->mask, MPU_RASR_SRD_Msk, MPU_RASR_SRD_Pos);

    set_reg_value(&reg, region->size, MPU_RASR_SIZE_Msk, MPU_RASR_SIZE_Pos);

    set_reg_value(&reg, 1, MPU_RASR_EN_Msk, MPU_RASR_EN_Pos);
    write_reg_value(r_CORTEX_M_MPU_RASR, reg);

    return 0;
}

/* Disable/Enable MPU */
void core_mpu_enable(uint8_t enable)
{
    set_reg_value(r_CORTEX_M_MPU_CTRL, enable, MPU_CTRL_ENABLE_Msk,
                  MPU_CTRL_ENABLE_Pos);
}

void core_mpu_init(uint8_t privdefenable, void *mpu_Handler
                   __attribute__ ((unused)))
{
    /* Disable MPU */
    core_mpu_enable(0);

    /* Disable/Enable privileged software access to default memory map */
    set_reg_value(r_CORTEX_M_MPU_CTRL, privdefenable,
                  MPU_CTRL_PRIVDEFENA_Msk, MPU_CTRL_PRIVDEFENA_Pos);

    /* Enable the memory fault exception */
    set_reg_value(r_CORTEX_M_SCB_SHCSR, 1, SCB_SHCSR_MEMFAULTENA_Msk,
                  SCB_SHCSR_MEMFAULTENA_Pos);
}

/*
 * disable a given region
 */
uint8_t core_mpu_region_disable(uint8_t region_number)
{
    uint32_t reg = 0;

    if (region_number > MPU_LAST_REGION) {
        return 1;
    }
    /* select the region number */
    set_reg_value(r_CORTEX_M_MPU_RNR, region_number,
                  MPU_RNBR_REGION_Msk, MPU_RNBR_REGION_Pos);

    /* disable the region */
    set_reg_value(&reg, 0, MPU_RASR_EN_Msk, MPU_RASR_EN_Pos);
    write_reg_value(r_CORTEX_M_MPU_RASR, reg);

    return 0;
}

/*
 * Configure the access and execution rights using Cortex-M3 MPU regions.
 */
uint8_t core_mpu_region_config(region_config * region)
{
    uint32_t reg = 0;

    /*
     * If the region size is configured to 4 GB, in the MPU_RASR register,
     * there is no valid ADDR field. In this case, the region occupies the
     * complete memory map, and the base address is 0x00000000.
     * ADDR[31:N]: Region base address field with the value of N depends on the
     * region size.
     * N = Log2(Region size in bytes)
     * The base address is aligned to the size of the region.
     *
        if (region->size == MPU_REGION_SIZE_4Gb) {
            if (region->addr != 0)
                return -1;
            }
        }
        else if (region->addr % (1 << (region->size+1))) {
            return -1;
        }
     */

    /* Configure region */
    set_reg_value(r_CORTEX_M_MPU_RNR, region->region_number,
                  MPU_RNBR_REGION_Msk, MPU_RNBR_REGION_Pos);

    /*
     * In case of valid = 0, MPU_RNR register not changed,
     * Updates the base address for the region specified in the MPU_RNR
     * then the value of the REGION field is ignored.
     */
    set_reg_value(&reg, ((region->addr) >> MPU_RBAR_ADDR_Pos),
                  MPU_RBAR_ADDR_Msk, MPU_RBAR_ADDR_Pos);
    set_reg_value(&reg, 0, MPU_RBAR_VALID_Msk, MPU_RBAR_VALID_Pos);
    write_reg_value(r_CORTEX_M_MPU_RBAR, reg);

    reg = 0;

    /*
     * Only Access permissions for privileged and unprivileged software are defined.
     * Others attributs (TEX, C, B, and S) will be defined later.
     */
    set_reg_value(&reg, region->access_perm, MPU_RASR_AP_Msk, MPU_RASR_AP_Pos);
    set_reg_value(&reg, region->xn, MPU_RASR_XN_Msk, MPU_RASR_XN_Pos);
    set_reg_value(&reg, region->b, MPU_RASR_B_Msk, MPU_RASR_B_Pos);
    set_reg_value(&reg, region->s, MPU_RASR_S_Msk, MPU_RASR_S_Pos);
    //set_reg_value( &reg, region->mask, MPU_RASR_SRD_Msk, MPU_RASR_SRD_Pos);
    set_reg_value(&reg, 0, MPU_RASR_SRD_Msk, MPU_RASR_SRD_Pos);

    set_reg_value(&reg, region->size, MPU_RASR_SIZE_Msk, MPU_RASR_SIZE_Pos);

    set_reg_value(&reg, 1, MPU_RASR_EN_Msk, MPU_RASR_EN_Pos);
    write_reg_value(r_CORTEX_M_MPU_RASR, reg);

    return 0;
}

uint8_t core_mpu_bytes_to_region_size (uint32_t bytes)
{
    switch (bytes) {
        case 32:    return MPU_REGION_SIZE_32b;
        case 64:	return MPU_REGION_SIZE_64b;
        case 128:	return MPU_REGION_SIZE_128b;
        case 256:	return MPU_REGION_SIZE_256b;
        case 512:	return MPU_REGION_SIZE_512b;
        case 1*KBYTE:	return MPU_REGION_SIZE_1Kb;
        case 2*KBYTE:	return MPU_REGION_SIZE_2Kb;
        case 4*KBYTE:	return MPU_REGION_SIZE_4Kb;
        case 8*KBYTE:	return MPU_REGION_SIZE_8Kb;
        case 16*KBYTE:	return MPU_REGION_SIZE_16Kb;
        case 32*KBYTE:	return MPU_REGION_SIZE_32Kb;
        case 64*KBYTE:	return MPU_REGION_SIZE_64Kb;
        case 128*KBYTE:	return MPU_REGION_SIZE_128Kb;
        case 256*KBYTE:	return MPU_REGION_SIZE_256Kb;
        case 512*KBYTE:	return MPU_REGION_SIZE_512Kb;
        case 1*MBYTE:	return MPU_REGION_SIZE_1Mb;
        case 2*MBYTE:	return MPU_REGION_SIZE_2Mb;
        case 4*MBYTE:	return MPU_REGION_SIZE_4Mb;
        case 8*MBYTE:	return MPU_REGION_SIZE_8Mb;
        case 16*MBYTE:	return MPU_REGION_SIZE_16Mb;
        case 32*MBYTE:	return MPU_REGION_SIZE_32Mb;
        case 64*MBYTE:	return MPU_REGION_SIZE_64Mb;
        case 128*MBYTE:	return MPU_REGION_SIZE_128Mb;
        case 256*MBYTE:	return MPU_REGION_SIZE_256Mb;
        case 512*MBYTE:	return MPU_REGION_SIZE_512Mb;
        case 1*GBYTE:	return MPU_REGION_SIZE_1Gb;
        case 2147483648UL:	return MPU_REGION_SIZE_2Gb;
        //FIXME
        //  case 4294967296UL:	return MPU_REGION_SIZE_4Gb;
        default:
            panic("core_mpu_bytes_to_region_size(): invalid size (%d)", bytes);
            return 0;
    }
}
