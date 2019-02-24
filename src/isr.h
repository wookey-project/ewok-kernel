/* isr.h
 *
 * Copyright (C) 2018 ANSSI
 * All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the BSD license.  See the LICENSE file for details.
 */

#ifndef SOC_ISR_
#define SOC_ISR_

__ISR_HANDLER stack_frame_t *postpone_isr
    (uint8_t irq, s_irq *cell, stack_frame_t * stack_frame);

#endif
