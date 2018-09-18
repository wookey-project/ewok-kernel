/* isr.c
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

#include "soc-nvic.h"
#include "soc-interrupts.h"
#include "soc-dma.h"
#include "dma.h"
#include "softirq.h"
#include "posthook.h"
#include "tasks.h"
#include "debug.h"
#include "sched.h"

/*
** Replace the weak implementation of libbsp
** this function postpone the ISR execution in softirq context
*/
stack_frame_t *postpone_isr
    (uint8_t irq, s_irq *cell, stack_frame_t * stack_frame)
{
    /* Status and data register to push to ISR as argument, if needed */
    uint32_t regs[2] = { 0 };

    task_t*  caller;

    caller = task_get_task (cell->task_id);
    if (caller == NULL) {
        panic("postpone_isr(): invalid task id %d\n", cell->task_id);
    }

    /*
     * If current ISR is handled by kernel, just execute it
     * and go back to work without requesting schedule
     */
    if (caller->type == TASK_TYPE_KERNEL) {
        cell->irq_handler(stack_frame);
        return stack_frame;
    }

    /*
     * Acknowledge interrupt:
     * - Timer and DMA are managed by the kernel
     * - Devices managed by user tasks should use the posthook mechanism
     *   to acknowledge interrupt in order to avoid bursts.
     */
#if defined(CONFIG_KERNEL_DMA_ENABLE)
    else if (soc_is_dma_irq(irq)) {
        regs[0] = dma_get_status(cell->task_id, irq);
        dma_clean_int(cell->task_id, irq);  // clear SR register
    }
#endif
    else {
        /* Post-hook */
        int_posthook_exec(irq, regs);
    }

    /*
     * All user ISR have their Pending IRQ bit clean here
     * SR is cleaned by softirq user ISR handler
     */
    NVIC_ClearPendingIRQ((uint32_t)(irq - 0x10));

    softirq_query(SFQ_USR_ISR, cell->task_id, cell->irq,
        (physaddr_t) cell->irq_handler, regs);

    return stack_frame;
}

