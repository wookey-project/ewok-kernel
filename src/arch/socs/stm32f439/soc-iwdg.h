/* \file soc-iwdg.h
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
#ifndef SOC_IWDG_H
#define SOC_IWDG_H

#include "soc-core.h"

#define r_CORTEX_M_IWDG_KR	REG_ADDR(IWDG_BASE + 0x0)
#define r_CORTEX_M_IWDG_PR	REG_ADDR(IWDG_BASE + 0x4)
#define r_CORTEX_M_IWDG_RLR	REG_ADDR(IWDG_BASE + 0x8)
#define r_CORTEX_M_IWDG_SR	REG_ADDR(IWDG_BASE + 0xc)

/* Key register */
#define IWDG_KR_KEY_Pos	0
#define IWDG_KR_KEY_Msk	((uint32_t)0xffff << IWDG_KR_KEY_Pos)
#	define IWDG_KR_KEY_FEED		0xaaaa
#	define IWDG_KR_KEY_WRITE_ACCESS	0x5555
#	define IWDG_KR_KEY_START	0xcccc

/* Prescaler register */
#define IWDG_PR_PR_Pos		0
#define IWDG_PR_PR_Msk		((uint32_t)0x7 << IWDG_PR_PR_Pos)

/* Reload register */
#define IWDG_RLR_RL_Pos	0
#define IWDG_RLR_RL_Msk	((uint32_t)0xfff << IWDG_RLR_RL_Pos)

/* Status register */
#define IWDG_SR_RVU_Pos	0
#define IWDG_SR_RVU_Msk	((uint32_t)1 << IWDG_SR_RVU_Pos)
#define IWDG_SR_PVU_Pos	1
#define IWDG_SR_PVU_Msk	((uint32_t)1 << IWDG_SR_PVU_Pos)

void soc_iwdg_start(void);
void soc_iwdg_feed(void);
void soc_iwdg_set_prescaler(uint32_t prescaler);
void soc_iwdg_set_reload_value(uint32_t value);

#endif                          /* !STM32F4XX_IWDG_H */
