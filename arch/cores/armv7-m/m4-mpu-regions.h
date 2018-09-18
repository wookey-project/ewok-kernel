/* \file m4-mpu-regions.h
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
#ifndef M4_MPU_REGIONS
# define M4_MPU_REGIONS

/* MPU access permission attributes */

/* This section describes the MPU access permission attributes. The access permission bits
* TEX C B S AP and XN of the MPU_RASR register control access to the corresponding
* memory region. If an access is made to an area of memory without the required
* permissions then the MPU generates a permission fault.
*/
#define MPU_REGION_XN    	((uint32_t) 0x01)   /* Instruction access disable bit */
#define MPU_REGION_NO_NO  	((uint32_t) 0x00)   /* All access => permissions fault */
#define MPU_REGION_RW_NO  	((uint32_t) 0x01)   /* Access from privileged soft only */
#define MPU_REGION_RW_RO  	((uint32_t) 0x02)   /* Write by user mode app => permissions fault */
#define MPU_REGION_RW_RW  	((uint32_t) 0x03)   /* Full access for every one */
#define MPU_REGION_UK_UK  	((uint32_t) 0x04)   /* Reserved */
#define MPU_REGION_RO_NO  	((uint32_t) 0x05)   /* Read by privileged soft only */
#define MPU_REGION_RO_RO  	((uint32_t) 0x06)   /* Read only for every one */
//#define #define    MPU_REGION_RO_RO = ((uint32_t) 0x07) /* Read only for every one */
/* SIZE field values */

#define MPU_PERMISSION_NO	((uint32_t) 0x00)
#define MPU_PERMISSION_YES	((uint32_t) 0x01)

/* The SIZE field defines the size of the MPU memory region specified by the MPU_RNR register as follows:
* (Region size in bytes) = 2(SIZE+1)
* The smallest permitted region size is 32B corresponding to a SIZE value of 4
*/
#define MPU_REGION_SIZE_32b    4
#define MPU_REGION_SIZE_64b    5
#define MPU_REGION_SIZE_128b   6
#define MPU_REGION_SIZE_256b   7
#define MPU_REGION_SIZE_512b   8
#define MPU_REGION_SIZE_1Kb    9
#define MPU_REGION_SIZE_2Kb    10
#define MPU_REGION_SIZE_4Kb    11
#define MPU_REGION_SIZE_8Kb    12
#define MPU_REGION_SIZE_16Kb   13
#define MPU_REGION_SIZE_32Kb   14
#define MPU_REGION_SIZE_64Kb   15
#define MPU_REGION_SIZE_128Kb  16
#define MPU_REGION_SIZE_256Kb  17
#define MPU_REGION_SIZE_512Kb  18
#define MPU_REGION_SIZE_1Mb    19
#define MPU_REGION_SIZE_2Mb    20
#define MPU_REGION_SIZE_4Mb    21
#define MPU_REGION_SIZE_8Mb    22
#define MPU_REGION_SIZE_16Mb   23
#define MPU_REGION_SIZE_32Mb   24
#define MPU_REGION_SIZE_64Mb   25
#define MPU_REGION_SIZE_128Mb  26
#define MPU_REGION_SIZE_256Mb  27
#define MPU_REGION_SIZE_512Mb  28
#define MPU_REGION_SIZE_1Gb    29
#define MPU_REGION_SIZE_2Gb    30
#define MPU_REGION_SIZE_4Gb    31

#endif/*!M4_MPU_REGIONS*/
