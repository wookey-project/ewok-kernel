/* soc-layout.h
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
#ifndef SOC_LAYOUT_H
#define SOC_LAYOUT_H

#include "autoconf.h"

/*
** About the mapping: here is the flash layout described below
** This mapping is feasable for mono-bank, mono-bank with DFU.
**
**     +----------------+0x0800 0000
**     |  LDR (64k)     |
**     +----------------+0x0801 0000
**     |  SHR (64k)     |
**     +----------------+0x0802 0000
**     |   FW_k  (64k)  |
**     +----------------+0x0803 0000
**     |  DFU_k  (64k)  |
**     + - - - - - - - -+0x0804 0000
**     |                |
**     |  DFU_u (256k)  |
**     |                |
**     +----------------+0x0808 0000
**     |                |
**     |  FW_u  (512k)  |
**     |                |
**     |                |
**     +----------------+0x0810 0000
**
*/

#define NB_MEM_BANK     1


#define KBYTE           1024
#define FLASH_SIZE      1024*KBYTE
#define VTORS_SIZE     0x188

/*
 * Mapping
 */
#define LDR_BASE        0x08000000  /* loader */
#define SHR_BASE        0x08008000  /* shared memory */

#define RAM2_BASE       0x10000000
#define RAM_KERN_BASE   0x10000000  /* 96k user RAM (div by 8 subregions, 12*8, 24*4), starting at RAM size + 32k */

/* User tasks */
#define RAM_BASE        0x20000000  /* 24k kernel RAM + 8k empty */
#define RAM_USER_BASE   RAM_BASE    /* 96k user RAM (div by 8 subregions, 12*8, 24*4), starting at RAM size + 32k */
#define RAM_USER_REGION_SIZE   MPU_REGION_SIZE_128Kb    /* 96k user RAM (div by 8 subregions, 12*8, 24*4), starting at RAM size + 32k */

#define RAM_USER_APPS_BASE          RAM_BASE
#define RAM_USER_SIZE         16*KBYTE
#define RAM_USER_APP1_BASE    RAM_USER_APPS_BASE
#define RAM_USER_APP2_BASE    RAM_USER_APP1_BASE + RAM_USER_SIZE
#define RAM_USER_APP3_BASE    RAM_USER_APP2_BASE + RAM_USER_SIZE
#define RAM_USER_APP4_BASE    RAM_USER_APP3_BASE + RAM_USER_SIZE
#define RAM_USER_APP5_BASE    RAM_USER_APP4_BASE + RAM_USER_SIZE
#define RAM_USER_APP6_BASE    RAM_USER_APP5_BASE + RAM_USER_SIZE
#define RAM_USER_APP7_BASE    RAM_USER_APP6_BASE + RAM_USER_SIZE
#define RAM_USER_APP8_BASE    RAM_USER_APP7_BASE + RAM_USER_SIZE

#define FW1_APP1_BASE    0x08080000
#define FW1_APP2_BASE    0x08090000
#define FW1_APP3_BASE    0x080a0000
#define FW1_APP4_BASE    0x080b0000
#define FW1_APP5_BASE    0x080c0000
#define FW1_APP6_BASE    0x080d0000
#define FW1_APP7_BASE    0x080e0000
#define FW1_APP8_BASE    0x080f0000

#define DFU1_APP1_BASE    0x08040000
#define DFU1_APP2_BASE    0x08048000
#define DFU1_APP3_BASE    0x08050000
#define DFU1_APP4_BASE    0x08058000
#define DFU1_APP5_BASE    0x08060000
#define DFU1_APP6_BASE    0x08068000
#define DFU1_APP7_BASE    0x08070000
#define DFU1_APP8_BASE    0x08078000

/* LDR is in the last sub-region (slot 8) */
#define RAM_LDR_BASE    0x2001c000
#define RAM_LDR_SIZE    20*KBYTE

/*
 * STM32F4
 */


#define RAM2_SIZE       64*KBYTE
#define RAM_KERN_SIZE   RAM2_SIZE
#define LDR_SIZE        128*KBYTE

/* Flip bank */

#define FW1_SIZE        576*KBYTE

#define FW1_KERN_BASE   0x08020000
#define FW1_KERN_SIZE   64*KBYTE
#define FW1_KERN_REGION_SIZE   MPU_REGION_SIZE_64Kb

#define FW1_USER_BASE   0x08080000
#define FW1_USER_SIZE   512*KBYTE
#define FW1_USER_REGION_SIZE   MPU_REGION_SIZE_512Kb

/**** DFU 1 ****/

#define DFU1_SIZE       320*KBYTE

#define DFU1_KERN_BASE  0x08030000
#define DFU1_USER_BASE  0x08040000

#define DFU1_KERN_SIZE  64*KBYTE
#define DFU1_KERN_REGION_SIZE   MPU_REGION_SIZE_64Kb
#define DFU1_USER_SIZE  256*KBYTE
#define DFU1_USER_REGION_SIZE  MPU_REGION_SIZE_256Kb


/* No Flop bank feasable on this SoC, as there is only 1MB flash */


#define RAM2_SIZE       64*KBYTE
#define RAM_KERN_SIZE   RAM2_SIZE
#define RAM_KERN_REGION_SIZE   MPU_REGION_SIZE_64Kb
#define LDR_SIZE        128*KBYTE


#define MB1_BASE        0x60000000
#define MB2_BASE        0x60000000
#define MB1_SIZE        0
#define MB2_SIZE        0


#define FW1_START       FW1_KERN_BASE + VTORS_SIZE + 1
#define DFU1_START      DFU1_BASE + VTORS_SIZE + 1


#define FW_MAX_USER_SIZE 64*KBYTE
#define DFU_MAX_USER_SIZE 32*KBYTE

/**** Shared mem ****/
#define SHR_SIZE        32*KBYTE

/**** SRAM ****/
#define RAM_SIZE        128*KBYTE



#endif /*!SOC_LAYOUT_H*/
