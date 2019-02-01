/* \file soc-rcc.c
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
#include "regutils.h"
#include "autoconf.h"
#include "soc-rcc.h"
#include "soc-pwr.h"
#include "soc-flash.h"
#include "m4-cpu.h"

/*
 * TODO: some of the bellowing code should be M4 generic. Yet, check if all
 * these registers are M4 generic or STM32F4 core specific
 */
void soc_rcc_reset(void)
{
    /* Reset the RCC clock configuration to the default reset state */
    /* Set HSION bit */
    set_reg_bits(r_CORTEX_M_RCC_CR, RCC_CR_HSION);

    /* Reset CFGR register */
    write_reg_value(r_CORTEX_M_RCC_CFGR, 0x00000000);

    /* Reset HSEON, CSSON and PLLON bits */
    clear_reg_bits(r_CORTEX_M_RCC_CR,
                   RCC_CR_HSEON | RCC_CR_CSSON | RCC_CR_PLLON);

    /* Reset PLLCFGR register */
    write_reg_value(r_CORTEX_M_RCC_PLLCFGR, 0x24003010);

    /* Reset HSEBYP bit */
    clear_reg_bits(r_CORTEX_M_RCC_CR, RCC_CR_HSEBYP);

    /* Reset all interrupts */
    write_reg_value(r_CORTEX_M_RCC_CIR, 0x00000000);

    full_memory_barrier();
}

void soc_rcc_setsysclock(bool enable_hse, bool enable_pll)
{
    uint32_t StartUpCounter = 0, status = 0;

    /*
     * PLL (clocked by HSE/HSI) used as System clock source
     */

    if (enable_hse) {
        /* Enable HSE */
        set_reg_bits(r_CORTEX_M_RCC_CR, RCC_CR_HSEON);
        do {
            status = read_reg_value(r_CORTEX_M_RCC_CR) & RCC_CR_HSERDY;
            StartUpCounter++;
        } while ((status == 0) && (StartUpCounter != HSE_STARTUP_TIMEOUT));
    } else {
        /* Enable HSI */
        set_reg_bits(r_CORTEX_M_RCC_CR, RCC_CR_HSION);
        do {
            status = read_reg_value(r_CORTEX_M_RCC_CR) & RCC_CR_HSIRDY;
            StartUpCounter++;
        } while ((status == 0) && (StartUpCounter != HSI_STARTUP_TIMEOUT));
    }

    if (status != RESET) {
        /* Enable high performance mode, System frequency up to 168 MHz */
        set_reg_bits(r_CORTEX_M_RCC_APB1ENR, RCC_APB1ENR_PWREN);
        /*
         * This bit controls the main internal voltage regulator output
         * voltage to achieve a trade-off between performance and power
         * consumption when the device does not operate at the maximum
         * frequency. (DocID018909 Rev 15 - page 141)
         * PWR_CR_VOS = 1 => Scale 1 mode (default value at reset)
         */
        set_reg_bits(r_CORTEX_M_PWR_CR, PWR_CR_VOS_Msk);

        /* Set clock dividers */
        set_reg_bits(r_CORTEX_M_RCC_CFGR, PROD_HCLK);
        set_reg_bits(r_CORTEX_M_RCC_CFGR, PROD_PCLK2);
        set_reg_bits(r_CORTEX_M_RCC_CFGR, PROD_PCLK1);

        if (enable_pll) {
            /* Configure the main PLL */
            if (enable_hse) {
                write_reg_value(r_CORTEX_M_RCC_PLLCFGR, PROD_PLL_M | (PROD_PLL_N << 6)
                    | (((PROD_PLL_P >> 1) - 1) << 16)
                    | (RCC_PLLCFGR_PLLSRC_HSE) | (PROD_PLL_Q << 24));
            } else {
                write_reg_value(r_CORTEX_M_RCC_PLLCFGR, PROD_PLL_M | (PROD_PLL_N << 6)
                    | (((PROD_PLL_P >> 1) - 1) << 16)
                    | (RCC_PLLCFGR_PLLSRC_HSI) | (PROD_PLL_Q << 24));
            }

            /* Enable the main PLL */
            set_reg_bits(r_CORTEX_M_RCC_CR, RCC_CR_PLLON);

            /* Wait till the main PLL is ready */
            while ((read_reg_value(r_CORTEX_M_RCC_CR) & RCC_CR_PLLRDY) == 0)
                continue;
        }

        /* Configure Flash prefetch, Instruction cache, Data cache and wait state */
        write_reg_value(r_CORTEX_M_FLASH_ACR, FLASH_ACR_ICEN
                        | FLASH_ACR_DCEN | FLASH_ACR_LATENCY_5WS);

        if (enable_pll) {
            /* Select the main PLL as system clock source */
            clear_reg_bits(r_CORTEX_M_RCC_CFGR, RCC_CFGR_SW);
            set_reg_bits(r_CORTEX_M_RCC_CFGR, RCC_CFGR_SW_PLL);

            /* Wait till the main PLL is used as system clock source */
            while ((read_reg_value(r_CORTEX_M_RCC_CFGR) & (uint32_t) RCC_CFGR_SWS)
                    != RCC_CFGR_SWS_PLL)
                continue;
        }

    } else {
        /* If HSE/I fails to start-up, the application will have wrong
         * clock configuration. User can add here some code to deal
         * with this error.
         */
    }
}
