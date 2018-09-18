/* m4-systick.h
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
#ifndef CORTEX_M4_SYSTICK_H
#define CORTEX_M4_SYSTICK_H

#include "types.h"
#include "soc-interrupts.h"

/* FIXME */
#define TICKS_PER_SECOND    1000

/**
 * systick_init - Initialize the systick module
 */
void core_systick_init(void);

/**
 * delay
 * @ms: Number of milliseconds to wait
 */
void core_systick_delay(uint32_t delay);

/**
 * get_ticks - Get the number of ticks elapsed since the card boot
 * Return: Number of ticks.
 */
unsigned long long core_systick_get_ticks(void);

unsigned long long core_ms_to_ticks(unsigned long long ms);

/* ticks counter function, to be called by systick IRQ handler */
stack_frame_t *core_systick_handler(stack_frame_t * stack_frame);

#endif                          /* CORTEX_M4_SYSTICK_H */
