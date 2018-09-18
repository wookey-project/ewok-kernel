/* \file default_handlers.c
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
#include "m4-systick.h"
#include "m4-core.h"
#include "soc-interrupts.h"
#include "soc-dwt.h"
#include "soc-nvic.h"
#include "soc-scb.h"
#include "devices-shared.h"
#include "debug.h"
#include "kernel.h"
#include "isr.h"

#ifdef KERNEL
#include "tasks.h"
#include "tasks-shared.h"
#include "sched.h"
#include "layout.h"
#endif

#define HANDLERLOG(fmt, ...) \
    dbg_log(ANSI_COLOR_RED fmt ANSI_COLOR_RESET, ##__VA_ARGS__)

/*
** Generic handlers. This handlers can be overloaded later if needed.
*/

stack_frame_t *WWDG_IRQ_Handler(stack_frame_t * stack_frame)
{
    while (1) ;
    return stack_frame;         /* never joined! */
}

stack_frame_t *HardFault_Handler(stack_frame_t * frame)
{
    uint32_t    cfsr = *((uint32_t *) r_CORTEX_M_SCB_CFSR);
    uint32_t    hfsr = *((uint32_t *) r_CORTEX_M_SCB_HFSR);
    uint32_t   *p;
    int         i;
#ifdef KERNEL
    task_t     *current_task = sched_get_current();
    if (!current_task) {
        /* This happend when hardfaulting before sched module initialization */
        HANDLERLOG("\nEarly kernel hard fault\n  scb.hfsr %x  scb.cfsr %x\n", hfsr, cfsr);
    } else {
        HANDLERLOG("\nHard fault from %s\n  scb.hfsr %x  scb.cfsr %x\n", current_task->name, hfsr, cfsr);
    }
#else
    HANDLERLOG("\nHard fault\n  scb.hfsr %x  scb.cfsr %x\n", hfsr, cfsr);
#endif
    dbg_flush();

    HANDLERLOG("-- registers (frame at %x, EXC_RETURN  %x)\n", frame, frame->lr);
    HANDLERLOG("  r0  %x\t r1  %x\t r2  %x\t r3  %x\n",
        frame->r0, frame->r1, frame->r2, frame->r3);
    HANDLERLOG("  r4  %x\t r5  %x\t r6  %x\t r7  %x\n",
        frame->r4, frame->r5, frame->r6, frame->r7);
    HANDLERLOG("  r8  %x\t r9  %x\t r10 %x\t r11 %x\n",
        frame->r8, frame->r9, frame->r10, frame->r11);
    HANDLERLOG("  r12 %x\t pc  %x\t lr %x\n",
        frame->r12, frame->pc, frame->prev_lr);
    dbg_flush();

    p = (uint32_t*) ((uint32_t) frame & 0xfffffff0);
    dbg_log("-- stack trace\n");
    for (i=0;i<8;i++) {
        HANDLERLOG("  %x: %x  %x  %x  %x\n", p, p[0], p[1], p[2], p[3]);
        dbg_flush();
        p = p + 4;
    }
#ifdef KERNEL
    if (frame_is_kernel((physaddr_t)frame)) {
        HANDLERLOG("Oops! Kernel panic!\n");
    }
    /*
     * here current_task can't be null as the frame is user
     * (i.e. the sched module is already started)
     */
    current_task->state[current_task->mode] = TASK_STATE_FAULT;
    request_schedule();
#else
    /* Non kernel mode (e.g. loader mode) */
    HANDLERLOG("Oops! Kernel panic!\n");
#endif
    return frame;
}

/* FIXME - Should be moved in the kernel*/

/*
 * To avoid purging the Default_Handler stack (making irq_enter/irq_return
 * fail), all the default handler algorithmic MUST be done in a subframe (i.e.
 * in a child function)
 */
__ISR_HANDLER stack_frame_t *Default_SubHandler(stack_frame_t * stack_frame)
{
    uint8_t         int_num;
    s_irq          *cell;
    stack_frame_t  *new_frame;
#ifdef KERNEL
    e_task_type     current_type;
    task_t         *current;
#else
    uint8_t         current_type;
#endif

    /* Getting the IRQ number */
    interrupt_get_num(int_num);
    int_num &= 0x1ff;

    /*
     * The 'cell' in the IRQ table contains, for each IRQ, the related task
     * and a pointer to it's IRQ handler
     */
    cell = get_cell_from_interrupt(int_num);
    cell->count++;

    /*
     * External interrupts don't switch tasks
     */
    if (int_num > 15) {

        if (cell->task_id != ID_UNUSED) {
            /* User or kernel ISR */
            postpone_isr(int_num, cell, stack_frame);
        }
        else {
            /* Kernel ISR w/o associated device (SCB ISR) */
            if (cell->irq_handler == 0) {
                panic("Unhandled IRQ number %x\n", int_num);
            } else {
                cell->irq_handler(stack_frame);
            }
        }
        new_frame = stack_frame;
    }
    /*
     * System exceptions might switch tasks
     */
    else {
        if (cell->irq_handler == 0) {
            panic("Unhandled exception %x\n", int_num);
        }
        new_frame = cell->irq_handler(stack_frame);
    }

#ifdef KERNEL
    current = sched_get_current();
    if (current->id != ID_UNUSED) {
        current_type = current->type;
    } else {
        current_type = TASK_TYPE_KERNEL;
    }
#else
    current_type = 0;
#endif

    asm volatile
       ("mov r1, %0" :: "r" (current_type) : "r1");

    return new_frame;

}

