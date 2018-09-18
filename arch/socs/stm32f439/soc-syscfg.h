/* \file soc-syscfg.h
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
#ifndef SOC_SYSCFG_H
#define SOC_SYSCFG_H

#include "soc-core.h"

#define SYSCFG_MEMRMP  ((uint32_t*)(SYSCFG_BASE+0x0))
#define SYSCFG_PMC     ((uint32_t*)(SYSCFG_BASE+0x4))
#define SYSCFG_EXTICR1 ((uint32_t*)(SYSCFG_BASE+0x8))
#define SYSCFG_EXTICR2 ((uint32_t*)(SYSCFG_BASE+0x0C))
#define SYSCFG_EXTICR3 ((uint32_t*)(SYSCFG_BASE+0x10))
#define SYSCFG_EXTICR4 ((uint32_t*)(SYSCFG_BASE+0x14))
#define SYSCFG_CMPCR   ((uint32_t*)(SYSCFG_BASE+0x20))

#define SYSCFG_EXTICR_FIELD_MASK 0xf


#endif /*!SOC_SYSCFG_H */
