/* \file layout.h
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
#ifndef LAYOUT_H_
#define LAYOUT_H_

#include "soc-layout.h"
#include "types.h"


#define STACK_TOP_IDLE      RAM_KERN_BASE + RAM_KERN_SIZE 
#define STACK_SIZE_IDLE     4*KBYTE

#define STACK_TOP_SOFTIRQ   RAM_KERN_BASE + RAM_KERN_SIZE - (4*KBYTE)
#define STACK_SIZE_SOFTIRQ  4*KBYTE

#define STACK_TOP_ISR       RAM_KERN_BASE + RAM_KERN_SIZE - (8*KBYTE)
#define STACK_SIZE_ISR      4*KBYTE

static inline bool frame_is_kernel(physaddr_t frame) {
    if (frame < STACK_TOP_IDLE && frame > STACK_TOP_ISR) {
        return true;
    }
    return false;
}

#endif /*!LAYOUT_H_*/
