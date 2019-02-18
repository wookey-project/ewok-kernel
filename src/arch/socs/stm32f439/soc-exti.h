/* \file soc-exti.h
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

#ifndef SOC_EXTI_H
#define SOC_EXTI_H

#include "soc-core.h"
#include "soc-syscfg.h"
#include "exported/gpio.h"

/*
 * Return the bit (or the bitfield) of the pending IT lines of the
 * EXTI for the corresponding IRQ
 */
uint32_t soc_exti_get_pending_lines(uint8_t irq);

/* Return true if there's an interrupt pending on the line */
bool soc_exti_is_line_pending (uint8_t line);

/*
 * From the pin number, return the corresponding EXTI line configured GPIO
 * port that has been configured.
 * CAUTION: this function doesn't check that the EXTI line has been previously
 * configured
 */
uint8_t soc_exti_get_syscfg_exticr_port(uint8_t pin);

/*
 * Configure an EXTI line for a given GPIO
 * if the EXTI line for this pin is already set, return 1, otherwhise
 * set it and return 0.
 * This function does not enable the corresponding NVIC line neither the
 * EXTI IMR bit (this is done using soc_exti_enable() function)
 *
 */
uint8_t soc_exti_config(dev_gpio_info_t *gpio);

/**
 * return true if the EXTI line associated to the GPIO pin is not
 * already set
 */
bool soc_exti_is_free(gpioref_t kref);

/*
 * Enable the EXTI line. This means:
 * 1) Activate the EXTI_IMR bit of the corresponding pin
 * 2) Enable the corresponding IRQ line in the NVIC(may be already done for
 * multiplexed EXTI IRQs)
 */
uint8_t soc_exti_enable(gpioref_t kref);

/*
 * Disable the EXTI line. This only clear the IMR EXTI register bit (NVIC
 * stays untouched as some EXTI lines are shared in a signe IRQ
 */
void soc_exti_disable(gpioref_t kref);

/*
 * Clean EXTI line pending bit
 */
void soc_exti_clear_pending(uint8_t pin);


/*
 * Initialize EXTI, enable APB2 Syscfg RCC clock
 */
void soc_exti_init(void);

#endif /*!SOC_EXTI_H */
