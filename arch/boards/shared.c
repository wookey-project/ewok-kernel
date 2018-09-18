/* \file shared.c
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

/*!
 * \file shared.c
 *
 * This file handle the SHR section structure. This content is out of
 * the basic layout and is shared beetween the kernel and the loader
 * for bootloading information such as flip/flop state
 */
#include "debug.h"
#include "soc-init.h"
#include "soc-layout.h"
#include "shared.h"
//#include "keys.h"

__attribute__((section(".shared")))
    const shr_vars_t shared_vars = {
                    .default_app_index = 0,             /* default boot to FW1 */
                    .apps = {
                       { .entry_point = (app_entry_t)FW1_START,  .version = 0x00000001, .boot_status = BOOT_OK },
#ifdef CONFIG_FIRMWARE_DFU
                       { .entry_point = (app_entry_t)DFU1_START,  .version = 0x00000001, .boot_status = BOOT_OK },
#endif
#ifdef CONFIG_FIRMWARE_DUALBANK
                       { .entry_point = (app_entry_t)FW2_START,  .version = 0x00000001, .boot_status = BOOT_OK },
#endif
                    },
                    //.siglen = DFU_SIGLEN,               /* default siglen      */
                    .siglen = 0x0,               /* default siglen      */
                    //.sig = DFU_SIG,
                    .sig = { 0x0 },
                    } ;

