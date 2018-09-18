/* \file exti.c
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

#include "exti.h"
#include "exti-handler.h"
#include "tasks.h"
#include "sched.h"
#include "devices.h"
#include "soc-exti.h"
#include "tasks-shared.h"
#include "debug.h"


/**********************************************
 * EXTI kernel utility functions
 *********************************************/

/*
 * Register a new EXTI line. This checks that the EXTI line is not
 * already registered.
 */
uint8_t exti_register_exti(dev_gpio_info_t *gpio)
{
    return soc_exti_config(gpio);
}

/*
 * Enable (i.e. activate at EXTI and NVIC level) the EXTI line.
 * This is done by calling soc_exti_enable() only. No generic call here.
 */
uint8_t exti_enable(gpioref_t kref)
{
    soc_exti_enable(kref);
    return 0;
}


/**
 * \brief disable a given line
 *
 * \returns 0 of EXTI line has been properly disabled, or non-null value
 */
uint8_t exti_disable(gpioref_t kref)
{
    soc_exti_disable(kref);
    return 0;
}

void exti_init(void)
{
    /*
     * Registering kernel handler for EXTI
     */
    set_interrupt_handler(EXTI0_IRQ, exti_handler, 0, ID_DEV_UNUSED);
    set_interrupt_handler(EXTI1_IRQ, exti_handler, 0, ID_DEV_UNUSED);
    set_interrupt_handler(EXTI2_IRQ, exti_handler, 0, ID_DEV_UNUSED);
    set_interrupt_handler(EXTI3_IRQ, exti_handler, 0, ID_DEV_UNUSED);
    set_interrupt_handler(EXTI4_IRQ, exti_handler, 0, ID_DEV_UNUSED);
    set_interrupt_handler(EXTI9_5_IRQ, exti_handler, 0, ID_DEV_UNUSED);
    set_interrupt_handler(EXTI15_10_IRQ, exti_handler, 0, ID_DEV_UNUSED);
    soc_exti_init();
}
