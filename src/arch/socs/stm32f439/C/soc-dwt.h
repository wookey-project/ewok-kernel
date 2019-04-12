/* \file soc-dwt.h
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
#ifndef SOC_DWT_H
#define SOC_DWT_H

#include "types.h"

void soc_dwt_init(void);

void soc_dwt_reset_timer(void);

void soc_dwt_start_timer(void);

void soc_dwt_stop_timer(void);

uint32_t soc_dwt_getcycles(void);

uint64_t soc_dwt_getcycles_64(void);

void soc_dwt_ovf_manage(void);

#endif /*!SOC_DWT_H */
