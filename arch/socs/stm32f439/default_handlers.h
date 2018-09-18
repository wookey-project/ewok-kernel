/* \file default_handlers.h
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

#ifndef DEFAULT_HANDLERS_H_
# define DEFAULT_HANDLERS_H_

stack_frame_t *WWDG_IRQ_Handler(stack_frame_t * stack_frame);

stack_frame_t *HardFault_Handler(stack_frame_t * frame);

__ISR_HANDLER stack_frame_t *Default_SubHandler(stack_frame_t * stack_frame);

#endif /*!DEFAULT_HANDLERS_H_*/
