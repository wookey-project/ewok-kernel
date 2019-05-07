/* exti-handler.c
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

#include "exti-handler.h"
#include "exti.h"
#include "soc-exti.h"
#include "soc-nvic.h"
#include "tasks.h"
#include "tasks-shared.h"
#include "sched.h"
#include "isr.h"
#include "devices.h"
#include "debug.h"

/**********************************************
 * EXTI kernel handler
 *********************************************/

/*
 * This procedure is executed for each active EXTI line.
 * To avoid code duplication, an inlined function is used. This
 * procedure is called by the handler only for pending EXTI lines.
 */
static inline void exti_handle_line(uint8_t        exti_line,
                                    uint8_t        irq,
                                    stack_frame_t *stack_frame)
{
    gpioref_t   kref;

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wconversion"
    /* No possible typecasting from uint8_t to :4 */
    kref.pin = exti_line;
#pragma GCC diagnostic pop

    /* Clear the EXTI pending bit for this line */
    soc_exti_clear_pending(kref.pin);

    /* Get back the configured GPIO port for this line */
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wconversion"
    /* No possible typecasting from uint8_t to :4 */
    kref.port = soc_exti_get_syscfg_exticr_port(kref.pin);
#pragma GCC diagnostic pop

    /* Get back from kernel devices list the corresponding GPIO structure
     * and create a 'fake' IRQ cell as if the user ISR is directly manage the
     * EXTI IRQ, in order to use the postpone ISR function. */
    dev_gpio_info_t *gpio = dev_get_gpio_from_gpio_kref(kref);

    if (!gpio) {
        /* No registered GPIO found ! The EXTI IP is not properly configured. */
        NVIC_ClearPendingIRQ((uint32_t)(irq - 0x10));
        KERNLOG(DBG_ERR, "Unable to find GPIO port associated with EXTI line %d\n");
    } else {
        s_irq cell = {
            .irq = irq,
            .handler.postponed_handler = gpio->exti_handler,
            .task_id = dev_get_task_from_gpio_kref(gpio->kref),
            .count = 0 };
        /* We keep the task_frame transmission from postpone_isr...
         * Remember that for IRQ lines 5 to 15, postpone_isr may be called more
         * that one time in the same handler
         */
        stack_frame = postpone_isr(irq, &cell, stack_frame);
        if (gpio->exti_lock == GPIO_EXTI_LOCKED) {
            exti_disable(kref);
        }
    }
}

/*
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
stack_frame_t *exti_handler(stack_frame_t * stack_frame)
{
    uint8_t  int_num;
    uint32_t pending_lines = 0;

    /*
     * It's sad to get back again the IRQ here, but as a generic kernel
     * IRQ handler, the IRQ number is not passed as first argument
     * Only postpone_isr get it back.
     * TODO: give irq as first argument of *all* handler ?
     */
    interrupt_get_num(int_num);
    int_num &= 0x1ff;

    switch (int_num) {
        /* EXTI0: pin 0 */
        case EXTI0_IRQ: {
            exti_handle_line(0, int_num, stack_frame);
            break;
        }
        /* EXTI0: pin 1 */
        case EXTI1_IRQ: {
            exti_handle_line(1, int_num, stack_frame);
            break;
        }
        /* EXTI0: pin 2 */
        case EXTI2_IRQ: {
            exti_handle_line(2, int_num, stack_frame);
            break;
        }
        /* EXTI0: pin 3 */
        case EXTI3_IRQ: {
            exti_handle_line(3, int_num, stack_frame);
            break;
        }
        /* EXTI0: pin 4 */
        case EXTI4_IRQ: {
            exti_handle_line(4, int_num, stack_frame);
            break;
        }
        /* EXTI0: pin 5 to 9 */
        case EXTI9_5_IRQ: {
            pending_lines = soc_exti_get_pending_lines(int_num);
            for (uint8_t i = 0; i < 5; ++i) {
                if (pending_lines & (uint32_t)(0x1 << i)) {
                     exti_handle_line((uint8_t)(5 + i), int_num, stack_frame);
                }
            }
            break;
        }
        /* EXTI0: pin 10 to 15 */
        case EXTI15_10_IRQ:
            pending_lines = soc_exti_get_pending_lines(int_num);
            for (uint8_t i = 0; i < 6; ++i) {
                if (pending_lines & (uint32_t)(0x1 << i)) {
                     exti_handle_line((uint8_t)(10 + i), int_num, stack_frame);
                }
            }
            break;
	default:
	    /* should not happen... */
	    break;
    }
    return stack_frame;
}

