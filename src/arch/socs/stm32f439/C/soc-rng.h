/* \file soc-rng.h
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
#ifndef _SOC_RNG_H
#define _SOC_RNG_H

#include "types.h"

#define r_CORTEX_M_RNG_BASE		REG_ADDR(0x50060800)

#define r_CORTEX_M_RNG_CR		(r_CORTEX_M_RNG_BASE + (uint32_t)0x00)
#define r_CORTEX_M_RNG_SR		(r_CORTEX_M_RNG_BASE + (uint32_t)0x01)
#define r_CORTEX_M_RNG_DR		(r_CORTEX_M_RNG_BASE + (uint32_t)0x02)

/* RNG control register */
#define RNG_CR_RNGEN_Pos		2
#define RNG_CR_RNGEN_Msk		((uint32_t)1 << RNG_CR_RNGEN_Pos)
#define RNG_CR_IE_Pos			3
#define RNG_CR_IE_Msk			((uint32_t)1 << RNG_CR_IE_Pos)

/* RNG status register */
#define RNG_SR_DRDY_Pos			0
#define RNG_SR_DRDY_Msk			((uint32_t)1 << RNG_SR_DRDY_Pos)
#define RNG_SR_CECS_Pos			1
#define RNG_SR_CECS_Msk			((uint32_t)1 << RNG_SR_CECS_Pos)
#define RNG_SR_SECS_Pos			2
#define RNG_SR_SECS_Msk			((uint32_t)1 << RNG_SR_SECS_Pos)
#define RNG_SR_CEIS_Pos			5
#define RNG_SR_CEIS_Msk			((uint32_t)1 << RNG_SR_CEIS_Pos)
#define RNG_SR_SEIS_Pos			6
#define RNG_SR_SEIS_Msk			((uint32_t)1 << RNG_SR_SEIS_Pos)

/* RNG data register */
#define RNG_DR_RNDATA_Pos		0
#define RNG_DR_RNDATA_Msk		((uint32_t)0xFFFF << RNG_DR_RNDATA_Pos)

int soc_rng_manager(uint32_t * random);

#endif                          /* _SOC_RNG_H */
