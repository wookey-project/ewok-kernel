/* \file soc-dwt.c
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

#include "soc-dwt.h"
#include "m4-cpu.h"

static uint32_t last_dwt = 0;

static volatile uint64_t cyccnt_loop = 0;

static volatile uint32_t* DWT_CONTROL = (volatile uint32_t*) 0xE0001000;
static volatile uint32_t* SCB_DEMCR = (volatile uint32_t*) 0xE000EDFC;
static volatile uint32_t* LAR = (volatile uint32_t*) 0xE0001FB0;
static volatile uint32_t *DWT_CYCCNT = (volatile uint32_t *) 0xE0001004;

void soc_dwt_reset_timer(void)
{
    *SCB_DEMCR = *(uint32_t *) SCB_DEMCR | 0x01000000;
    *LAR = 0xC5ACCE55;
    *DWT_CYCCNT = 0;   // reset the counter
    *DWT_CONTROL = 0;
   full_memory_barrier();
}

void soc_dwt_start_timer(void)
{
    *DWT_CONTROL = *DWT_CONTROL | 1;  // enable the counter
   full_memory_barrier();
}

uint32_t soc_dwt_getcycles(void)
{
    return *DWT_CYCCNT;
}

uint64_t soc_dwt_getcycles_64(void)
{
    uint64_t val = *DWT_CYCCNT;
    val += cyccnt_loop << 32;
    return val;
}


void soc_dwt_ovf_manage(void)
{
    uint32_t dwt = soc_dwt_getcycles();

    /*
     * DWT cycle count overflow: we increment cyccnt_loop counter.
     */
    if (dwt < last_dwt) {
        cyccnt_loop++;
    }

    last_dwt = dwt;
}

void soc_dwt_init(void)
{
    soc_dwt_reset_timer();
    soc_dwt_start_timer();
}
