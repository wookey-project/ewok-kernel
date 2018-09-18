/* \file m4-core.h
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
#ifndef M4_CORE_
#define M4_CORE_

#define MAIN_CLOCK_FREQUENCY 168000000
#define MAIN_CLOCK_FREQUENCY_MS 168000
#define MAIN_CLOCK_FREQUENCY_US 168

#define INITIAL_STACK 0x1000b000

#define INT_STACK_BASE KERN_STACK_BASE - 8192   /* same for FIQ & IRQ by now */
#define ABT_STACK_BASE INT_STACK_BASE - 4096
#define SYS_STACK_BASE ABT_STACK_BASE - 4096
#define UDF_STACK_BASE SYS_STACK_BASE - 4096

#define MODE_CLEAR 0xffffffe0

static inline void core_processor_init_modes(void)
{
    /*
     * init msp for kernel, this is needed in order to make IT return to SVC mode
     * in thread mode (LR=0xFFFFFFF9) working (loading the good msp value from the SPSR)
     */
    asm volatile ("msr msp, %0\n\t"::"r" (INITIAL_STACK):);
}

#endif                          /*!M4_CORE_ */
