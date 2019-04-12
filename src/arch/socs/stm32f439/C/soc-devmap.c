/* \file soc-devmap.c
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
#include "types.h"
#include "C/generated/devmap.h"
#include "m4-cpu.h"
#include "C/regutils.h"

struct device_soc_infos* soc_devmap_find_device
    (physaddr_t addr, uint32_t size)
{
    for (uint8_t i = 0; i < soc_devices_list_size; ++i) {
        if (addr == soc_devices_list[i].addr &&
            size == soc_devices_list[i].size)
        {
            return &soc_devices_list[i];
        }
    }
    return NULL;
}

#ifdef CONFIG_KERNEL_DMA_ENABLE
/* return the DMA info line based on the DMA controller id and the stream id (starting with 0) */
struct device_soc_infos *soc_devices_get_dma // FIXME rename
    (enum dma_controller id, uint8_t stream)
{
    return &(soc_devices_list[((id - 1) * 9) + stream +1]); // FIXME 5 + 1 + 1... = 7 ?
}
#endif


void soc_devmap_enable_clock (const struct device_soc_infos *device)
{
    set_reg_bits (device->rcc_enr, device->rcc_enb);
    full_memory_barrier();
}
