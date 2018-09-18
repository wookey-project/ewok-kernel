/* \file m4-systick-regs.h
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
#ifndef CORTEX_M4_SYSTICK_REGS_H
#define CORTEX_M4_SYSTICK_REGS_H

#include "soc-core.h"

/* The processor has a 24-bit system timer, SysTick, that counts down from the reload value to
 * zero, reloads (wraps to) the value in the STK_LOAD register on the next clock edge, then
 * counts down on subsequent clocks.
 * When the processor is halted for debugging the counter does not decrement.
 *
 * The SysTick counter runs on the processor clock. If this clock signal is stopped for low
 * power mode, the SysTick counter stops.
 * Ensure software uses aligned word accesses to access the SysTick registers.
 *
 * The SysTick counter reload and current value are undefined at reset,
 * the correct initialization sequence for the SysTick counter is:
 *  1. Program reload value.
 *  2. Clear current value.
 *  3. Program Control and Status register.
 */

/*** System timer registers ***/
/* (RW Privileged)  SysTick control and status register (STK_CTRL) */
#define r_CORTEX_M_STK_CTRL	REG_ADDR(SysTick_BASE + (uint32_t)0x00)
/* (RW Privileged)  SysTick reload value register (STK_LOAD) */
#define r_CORTEX_M_STK_LOAD	REG_ADDR(SysTick_BASE + (uint32_t)0x04)
/* (RW Privileged)  SysTick current value register (STK_VAL) */
#define r_CORTEX_M_STK_VAL	REG_ADDR(SysTick_BASE + (uint32_t)0x08)
/* (RO Privileged)  SysTick calibration value register (STK_CALIB) */
#define r_CORTEX_M_STK_CALIB	REG_ADDR(SysTick_BASE + (uint32_t)0x0C)

/*** SysTick control and status register (STK_CTRL) ***/
/* Bit 16 COUNTFLAG: Returns 1 if timer counted to 0 since last time this was
 * read.
 */
#define STK_COUNTFLAG_Pos	16
#define STK_COUNTFLAG_Msk	((uint32_t)0x01 << STK_COUNTFLAG_Pos)
/* Bit 2 CLKSOURCE: Clock source selection*/
#define STK_CLKSOURCE_Pos	2
#define STK_CLKSOURCE_Msk	((uint32_t)0x01 << STK_CLKSOURCE_Pos)
/* Bit 1 TICKINT: SysTick exception request enable*/
#define STK_TICKINT_Pos	1
#define STK_TICKINT_Msk	((uint32_t)0x01 << STK_TICKINT_Pos)
/* Bit 0 ENABLE: Counter enable*/
#define STK_ENABLE_Pos		0
#define STK_ENABLE_Msk		((uint32_t)0x01 << STK_ENABLE_Pos)

/*** SysTick reload value register (STK_LOAD) ***/
/* Bits 23:0 RELOAD: RELOAD value The LOAD register specifies the start value
 * to load into the STK_VAL register when the counter is enabled and when it
 * reaches 0.
 */
#define STK_RELOAD_Pos		0
#define STK_RELOAD_Msk		((uint32_t)0xffffff << STK_RELOAD_Pos)

/*** SysTick current value register (STK_VAL) ***/
/*  Bits 23:0 CURRENT: Current counter value. The VAL register contains the
 *  current value of the SysTick counter. Reads return the current value of the
 *  SysTick counter. A write of any value clears the field to 0, and also
 *  clears the COUNTFLAG bit in the STK_CTRL register to 0.
 */
#define STK_CURRENT_Pos	0
#define STK_CURRENT_Msk	((uint32_t)0xffffff << STK_CURRENT_Pos)

/*** SysTick calibration value register (STK_CALIB) ***/
/* Bit 31 NOREF: NOREF flag. Reads as zero. Indicates that a separate reference
 * clock is provided. The frequency of this clock is HCLK/8.
 */
#define STK_NOREF_Pos		31
#define STK_NOREF_Msk		((uint32_t)0x01 << STK_NOREF_Pos)
/* Bit 30 SKEW: SKEW flag: Indicates whether the TENMS value is exact. Reads as
 * one. Calibration value for the 1 ms inexact timing is not known because
 * TENMS is not known. This can affect the suitability of SysTick as a software
 * real time clock.
 */
#define STK_SKEW_Pos		30
#define STK_SKEW_Msk		((uint32_t)0x01 << STK_SKEW_Pos)
/* Bits 23:0 TENMS[23:0]: Calibration value. Indicates the calibration value
 * when the SysTick counter runs on HCLK max/8 as external clock. The value is
 * product dependent, please refer to the Product Reference Manual, SysTick
 * Calibration Value section. When HCLK is programmed at the maximum frequency,
 * the SysTick period is 1ms. If calibration information is not known,
 * calculate the calibration value required from the frequency of the processor
 * clock or external clock.
 */
#define STK_TENMS_Pos		0
#define STK_TENMS_Msk		((uint32_t)0xffffff << STK_TENMS_Pos)

#endif                          /* CORTEX_M4_SYSTICK_REGS_H */
