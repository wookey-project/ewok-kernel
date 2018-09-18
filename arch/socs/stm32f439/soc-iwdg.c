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

#include "debug.h"
#include "soc-iwdg.h"

void soc_iwdg_start(void)
{
    set_reg(r_CORTEX_M_IWDG_KR, IWDG_KR_KEY_START, IWDG_KR_KEY);
    LOG("Watchdog started");
}

void soc_iwdg_feed(void)
{
    set_reg(r_CORTEX_M_IWDG_KR, IWDG_KR_KEY_FEED, IWDG_KR_KEY);
}

void soc_iwdg_set_prescaler(uint32_t prescaler)
{
    assert(prescaler >= 4 && prescaler <= 256);
    uint32_t first_power_of_two = 0;

    set_reg(r_CORTEX_M_IWDG_KR, IWDG_KR_KEY_WRITE_ACCESS, IWDG_KR_KEY);
    while (get_reg(r_CORTEX_M_IWDG_SR, IWDG_SR_PVU))
        continue;

    while (first_power_of_two <= 8 && !(prescaler & 1)) {
        prescaler >>= 1;
        first_power_of_two++;
    }

    prescaler = first_power_of_two - 2;
    set_reg(r_CORTEX_M_IWDG_PR, prescaler, IWDG_PR_PR);
    LOG("New prescaler is %x", prescaler);
}

void soc_iwdg_set_reload_value(uint32_t value)
{
    set_reg(r_CORTEX_M_IWDG_KR, IWDG_KR_KEY_WRITE_ACCESS, IWDG_KR_KEY);
    while (get_reg(r_CORTEX_M_IWDG_SR, IWDG_SR_RVU))
        continue;
    set_reg(r_CORTEX_M_IWDG_RLR, value, IWDG_RLR_RL);
    LOG("New reload value is %x", value);
}
