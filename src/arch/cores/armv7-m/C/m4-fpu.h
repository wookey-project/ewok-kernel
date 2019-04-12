/* \file m4-fpu.h
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
#ifndef M4_FPU_H_
#define M4_FPU_H_

#define FPU_SYSREG_BASE 0xE000EF30

/* Floating-Point Context Control Register */
#define FPU_FPCCR_ASPEN_Pos  31 /*!< FPCCR: ASPEN bit Position */
#define FPU_FPCCR_ASPEN_Msk  (1UL << FPU_FPCCR_ASPEN_Pos)   /*!< FPCCR: ASPEN bit Mask */

#define FPU_FPCCR_LSPEN_Pos  30 /*!< FPCCR: LSPEN Position */
#define FPU_FPCCR_LSPEN_Msk  (1UL << FPU_FPCCR_LSPEN_Pos)   /*!< FPCCR: LSPEN bit Mask */

#define FPU_FPCCR_MONRDY_Pos  8 /*!< FPCCR: MONRDY Position */
#define FPU_FPCCR_MONRDY_Msk  (1UL << FPU_FPCCR_MONRDY_Pos) /*!< FPCCR: MONRDY bit Mask */

#define FPU_FPCCR_BFRDY_Pos   6 /*!< FPCCR: BFRDY Position */
#define FPU_FPCCR_BFRDY_Msk   (1UL << FPU_FPCCR_BFRDY_Pos)  /*!< FPCCR: BFRDY bit Mask */

#define FPU_FPCCR_MMRDY_Pos   5 /*!< FPCCR: MMRDY Position */
#define FPU_FPCCR_MMRDY_Msk   (1UL << FPU_FPCCR_MMRDY_Pos)  /*!< FPCCR: MMRDY bit Mask */

#define FPU_FPCCR_HFRDY_Pos   4 /*!< FPCCR: HFRDY Position */
#define FPU_FPCCR_HFRDY_Msk   (1UL << FPU_FPCCR_HFRDY_Pos)  /*!< FPCCR: HFRDY bit Mask */

#define FPU_FPCCR_THREAD_Pos  3 /*!< FPCCR: processor mode bit Position */
#define FPU_FPCCR_THREAD_Msk  (1UL << FPU_FPCCR_THREAD_Pos) /*!< FPCCR: processor mode active bit Mask */

#define FPU_FPCCR_USER_Pos    1 /*!< FPCCR: privilege level bit Position */
#define FPU_FPCCR_USER_Msk    (1UL << FPU_FPCCR_USER_Pos)   /*!< FPCCR: privilege level bit Mask */

#define FPU_FPCCR_LSPACT_Pos  0 /*!< FPCCR: Lazy state preservation active bit Position */
#define FPU_FPCCR_LSPACT_Msk  (1UL << FPU_FPCCR_LSPACT_Pos) /*!< FPCCR: Lazy state preservation active bit Mask */

/* Floating-Point Context Address Register */
#define FPU_FPCAR_ADDRESS_Pos  3    /*!< FPCAR: ADDRESS bit Position */
#define FPU_FPCAR_ADDRESS_Msk  (0x1FFFFFFFUL << FPU_FPCAR_ADDRESS_Pos)  /*!< FPCAR: ADDRESS bit Mask */

/* Floating-Point Default Status Control Register */
#define FPU_FPDSCR_AHP_Pos     26   /*!< FPDSCR: AHP bit Position */
#define FPU_FPDSCR_AHP_Msk     (1UL << FPU_FPDSCR_AHP_Pos)  /*!< FPDSCR: AHP bit Mask */

#define FPU_FPDSCR_DN_Pos      25   /*!< FPDSCR: DN bit Position */
#define FPU_FPDSCR_DN_Msk      (1UL << FPU_FPDSCR_DN_Pos)   /*!< FPDSCR: DN bit Mask */

#define FPU_FPDSCR_FZ_Pos      24   /*!< FPDSCR: FZ bit Position */
#define FPU_FPDSCR_FZ_Msk      (1UL << FPU_FPDSCR_FZ_Pos)   /*!< FPDSCR: FZ bit Mask */

#define FPU_FPDSCR_RMode_Pos   22   /*!< FPDSCR: RMode bit Position */
#define FPU_FPDSCR_RMode_Msk   (3UL << FPU_FPDSCR_RMode_Pos)    /*!< FPDSCR: RMode bit Mask */

/* FPU sysregs structure */
struct FPU {
    uint32_t reserved[1];
    volatile uint32_t FPCCR;
    volatile uint32_t FPCAR;
    volatile uint32_t FPDSCR;
} __attribute__ ((packed));

void fpu_enable(void);

#endif                          /*!M4_FPU_H_ */
