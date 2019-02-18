/* \file soc-pwr.h
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
#ifndef SOC_PWR_H
#define SOC_PWR_H

#include "soc-core.h"

/*
 * These registers are defined for STM32F405xx/407xx and STM32F415xx/417xx
 * only. Please refer to the programming manual section 5.5 for STM32F42xxx and
 * STM32F43xxx).
 */
#define r_CORTEX_M_PWR_CR	REG_ADDR(PWR_BASE + 0x00)
#define r_CORTEX_M_PWR_CSR	REG_ADDR(PWR_BASE + 0x04)

/* Power control register */
#define PWR_CR_LPDS_Pos		0
#define PWR_CR_LPDS_Msk		((uint32_t)1 << PWR_CR_LPDS_Pos)
#define PWR_CR_PDDS_Pos		1
#define PWR_CR_PDDS_Msk		((uint32_t)1 << PWR_CR_PDDS_Pos)
#define PWR_CR_CWUF_Pos		2
#define PWR_CR_CWUF_Msk		((uint32_t)1 << PWR_CR_CWUF_Pos)
#define PWR_CR_CSBF_Pos		3
#define PWR_CR_CSBF_Msk		((uint32_t)1 << PWR_CR_CSBF_Pos)
#define PWR_CR_PVDE_Pos		4
#define PWR_CR_PVDE_Msk		((uint32_t)1 << PWR_CR_PVDE_Pos)
#define PWR_CR_PLS_Pos			5
#define PWR_CR_PLS_Msk			((uint32_t)7 << PWR_CR_PLS_Pos)
#	define PWR_CR_PLS_2_0V			0
#	define PWR_CR_PLS_2_1V			1
#	define PWR_CR_PLS_2_3V			2
#	define PWR_CR_PLS_2_5V			3
#	define PWR_CR_PLS_2_6V			4
#	define PWR_CR_PLS_2_7V			5
#	define PWR_CR_PLS_2_8V			6
#	define PWR_CR_PLS_2_9V			7
#define PWR_CR_DBP_Pos			8
#define PWR_CR_DBP_Msk			((uint32_t)1 << PWR_CR_DBP_Pos)
#define PWR_CR_FPDS_Pos		9
#define PWR_CR_FPDS_Msk		((uint32_t)1 << PWR_CR_FPDS_Pos)
#define PWR_CR_VOS_Pos			14
#define PWR_CR_VOS_Msk			((uint32_t)1 << PWR_CR_VOS_Pos)

/* Power control/status register */
#define PWR_CSR_WUF_Pos		0
#define PWR_CSR_WUF_Msk		((uint32_t)1 << PWR_CSR_WUF_Pos)
#define PWR_CSR_SBF_Pos		1
#define PWR_CSR_SBF_Msk		((uint32_t)1 << PWR_CSR_SBF_Pos)
#define PWR_CSR_PVDO_Pos		2
#define PWR_CSR_PVDO_Msk		((uint32_t)1 << PWR_CSR_PVDO_Pos)
#define PWR_CSR_BRR_Pos		3
#define PWR_CSR_BRR_Msk		((uint32_t)1 << PWR_CSR_BRR_Pos)
#define PWR_CSR_EWUP_Pos		8
#define PWR_CSR_EWUP_Msk		((uint32_t)1 << PWR_CSR_EWUP_Pos)
#define PWR_CSR_BRE_Pos		9
#define PWR_CSR_BRE_Msk		((uint32_t)1 << PWR_CSR_BRE_Pos)
#define PWR_CSR_VOSRDY_Pos		14
#define PWR_CSR_VOSRDY_Msk		((uint32_t)1 << PWR_CSR_VOSRDY_Pos)

#endif /*!SOC_PWR_H */
