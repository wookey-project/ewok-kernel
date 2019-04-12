/* \file soc-init.h
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
#ifndef SOC_INIT_H
#define SOC_INIT_H

#include "types.h"
#include "product.h"
#include "soc-rcc.h"
#include "soc-rcc.h"

#define RESET	0
#define SET	1

#if !defined (HSE_STARTUP_TIMEOUT)
#define HSE_STARTUP_TIMEOUT	((uint16_t)0x0500)
#endif                          /* !HSE_STARTUP_TIMEOUT */

#if !defined (HSI_STARTUP_TIMEOUT)
#define HSI_STARTUP_TIMEOUT	((uint16_t)0x0500)
#endif                          /* !HSI_STARTUP_TIMEOUT */

void set_vtor(uint32_t);
void system_init(uint32_t);

#endif/*!SOC_INIT_H*/
