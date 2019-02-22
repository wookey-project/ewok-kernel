/* \file postpone.c
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
#include "soc-interrupts.h"

/*
 * This is a *weak* function that is used in the libbsp while the effective
 * kernel postponing function is registered.
 */
static void empty_postpone(void)
{
    for (;;)
        ;
}

/* Will be replaced by official postpone_isr function */
stack_frame_t *postpone_isr(uint8_t, s_irq *, stack_frame_t *)
    __attribute__ ((weak, alias("empty_postpone")));

