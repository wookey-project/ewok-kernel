/* \file soc-init.c
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
#include "autoconf.h"
#include "m4-cpu.h"
#include "soc-init.h"
#include "soc-flash.h"
#include "soc-pwr.h"
#include "soc-scb.h"
#include "soc-rcc.h"
#include "product.h"
#include "debug.h"

/*
 * \brief Configure the Vector Table location and offset address
 *
 * WARNING : No interrupts here => IRQs disabled
 *				=> No LOGs here
 */
void set_vtor(uint32_t addr)
{

    __DMB();                    /* Data Memory Barrier */
#ifdef CONFIG_STM32F4
    write_reg_value(r_CORTEX_M_SCB_VTOR, addr);
#endif
    __DSB();                    /*
                                 * Data Synchronization Barrier to ensure all
                                 * subsequent instructions use the new configuration
                                 */
}

/* void system_init(void)
 * \brief  Setup the microcontroller system
 *
 *         Initialize the Embedded Flash Interface, the PLL and update the
 *         SystemFrequency variable.
 */
void system_init(uint32_t addr)
{
#ifdef PROD_ENABLE_HSE
    bool enable_hse = true;
#else
    bool enable_hse = false;
#endif

#ifdef PROD_ENABLE_PLL
    bool enable_pll = true;
#else
    bool enable_pll = false;
#endif

#ifdef CONFIG_STM32F4
    soc_rcc_reset();
    /*
     * Configure the System clock source, PLL Multiplier and Divider factors,
     * AHB/APBx prescalers and Flash settings
     */
    soc_rcc_setsysclock(enable_hse, enable_pll);
#endif

    //set_vtor(FLASH_BASE|VECT_TAB_OFFSET);
    set_vtor(addr);
}
