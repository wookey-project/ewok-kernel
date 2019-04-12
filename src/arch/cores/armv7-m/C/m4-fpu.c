/* \file m4-fpu.c
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

#include "soc-core.h"
#include "soc-irq.h"
#include "autoconf.h"

#ifdef CONFIG_FPU_ENABLE_ALL
#define FPU_ACCESS_MODE 0xF
#elif defined CONFIG_FPU_ENABLE_PRIVILEGIED
#define FPU_ACCESS_MODE 0x5
#endif

#if (__FPU_PRESENT == 1)

/**
  \brief   Get FPSCR
  \details Returns the current value of the Floating Point Status/Control register
  \return the current register value
 */
static inline uint32_t get_fpscr(void)
{
    register uint32_t regfpscr = 0;
    asm volatile ("vmrs %0, fpscr ":"=r" (regfpscr));
    return (regfpscr);
}

/**
  \brief   Set FPSCR
  \details Assigns the parameter to the Floating Point Status/Control register
  \param Floating Point Status/Control value to set
 */
static inline void set_fpscr(uint32_t fpscr)
{
    asm volatile ("vmsr fpscr, %0 "::"r" (fpscr));
}

/*
 * This fpu Exception flag handler doesn't support FPU context save/restore, which means
 * that an ISR (or a preemptive task) can't use the FPU.
 * TODO: A support for save/restore mode need to be added here. Only Lazy (FIXME: to test) is
 * written here
 */

#ifdef CONFIG_FPU_NOSAVE
static inline void fpu_handler(void)
{
    uint32_t fpscr_val = get_fpscr();

    //{ check exception flags... something to check? }
    // Clear all exception flags... just clearning by now
    fpscr_val &= (uint32_t) ~ 0x8F;
    set_fpscr(fpscr_val);
}
#endif

#ifdef CONFIG_FPU_LAZY
static inline void fpu_handler(void)
{
    register uint32_t reg_val = 0;
    register uint32_t fpscr_val = get_fpscr();  // dummy
    struct FPU *fpuregs = FPU_SYSREG_BASE;

    // update the location of the unpopulated fp register space in the exception stack
    reg_val = *(volatile uint32_t *)(FPU->FPCAR + 0x40);
    //{ check exception flags }
    fpscr_val &= (uint32_t) ~ 0x8F;
    *(__IO uint32_t *) (FPU->FPCAR + 0x40) = reg_val;
    full_memory_barrier();
}
#endif

/*
  Case of full FPU context saving:

  TODO: for scheduling time: the scheduler must check if the FPSCR flags is set. If yes,
  the FPU context (reg S0-S32 + SCR or S16-S32 + SCR in case of lazy) must be pushed in
  the caller stack. Before scheduling the next task, the scheduler must check if there is
  an FPU context in the stack. If yes, this context must be restored.
*/

void fpu_enable(void)
{
#if CONFIG_FPU_ENABLE
    uint32_t r_cpacr = CPACR_BASE;
    uint32_t value = read_reg_value(&r_cpacr);

#if CONFIG_FPU_LAZY
    struct FPU *fpuregs = FPU_SYSREG_BASE;

    /* activate LSPEN for Lazy auto saving */
    fpuregs->FPCCR |= FPU_FPCCR_LSPEN_Msk;
#endif
    /* register FPU IRQ handler */
    irq_handler_set(FPU_IRQ, fpu_handler, 0, ID_DEV_UNUSED);
    /* Enable CP10 & CP 11 */
    value |= (FPU_ACCESS_MODE << 20);

    write_reg_value(&r_cpacr, value);
    full_memory_barrier();
#endif
}


#endif
