/* \file m4-systick.c
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
#include "m4-systick.h"
#include "m4-systick-regs.h"
#include "regutils.h"
#include "product.h"

volatile unsigned long long ticks;

void core_systick_init(void)
{
    set_reg(r_CORTEX_M_STK_LOAD, PROD_CORE_FREQUENCY, STK_RELOAD);
    set_reg(r_CORTEX_M_STK_VAL, 0, STK_CURRENT);
    set_reg_bits(r_CORTEX_M_STK_CTRL,
                 STK_CLKSOURCE_Msk | STK_TICKINT_Msk | STK_ENABLE_Msk);
}

void core_systick_delay(uint32_t delay)
{
    unsigned long long start = ticks;
    while (start + delay > ticks)
        continue;
}

unsigned long long core_systick_get_ticks(void)
{
    return ticks;
}

unsigned long long core_ms_to_ticks(unsigned long long ms)
{
    return ms * TICKS_PER_SECOND / 1000;
}

stack_frame_t *core_systick_handler(stack_frame_t * stack_frame)
{
    ticks++;
    return stack_frame;
}
