/* \file exti-handler.h
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

#ifndef EXTI_HANDLER_H_
#define EXTI_HANDLER_H_

#include "tasks.h"

/*!
 * Why a specific handler for EXTI ?
 * This is required to get back the GPIO pin/port couple from the EXTI
 * line. This may be complex when the EXTI line is multiplexed
 * (case if lines 5->15).
 * This handler:
 * 1) get back the IRQ number
 * 2) If this is a multiplexed IRQ, get back the effective
 *    associated EXTI line(s) (more than one can be pending in the same time)
 * 3) For each of theses lines, get back the corresponding registered GPIO
 *    and associated task
 * 4) We call postpone_isr directly, creating a custom IRQ cell, as final ISR
 *    are effective user ISRs.
 *
 * We do not use postpone_isr here because there is no bijection between
 * IRQ and ISR handlers (due to EXTI lines multiplexing). As a consequence,
 * a signe IRQ may lead to multiple GPIO lines for multiple tasks.
 */
stack_frame_t *exti_handler(stack_frame_t * stack_frame);

#endif/*!EXTI_HANDLER_H_*/
