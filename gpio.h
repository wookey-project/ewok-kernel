/* \file gpio.h
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

#ifndef KERN_GPIO_
#define KERN_GPIO_

#include "types.h"
#include "kernel.h"
#include "exported/devices.h"
#include "soc-gpio.h"

/***********************************************
 * Prototypes for initialization phase
 **********************************************/

/**
 * \brief register the GPIO identified by the gpio param
 * This function only set the given GPIO as used, making future
 * call to gpio_is_free() returning false.
 *
 * \param[in] gpio GPIO identifier, corresponding to the gpio structure
 *            kref field
 *
 * \return 0 on success
 */
uint8_t gpio_register_gpio
    (e_task_id task_id, e_device_id dev_id, const dev_gpio_info_t * gpio);

/**
 * \brief Enable (configure) the GPIO
 *
 * This function also activate the RCC line of the GPIO before its
 * configuration.
 *
 * \param[in] the gpio structure associated to the GPIO
 *
 * \return 0 if configuration has finished successfully, or non-zero value
 */
uint8_t gpio_enable_gpio(const dev_gpio_info_t * gpio);

/**************************************************
 * Prototypes for nominal phase
 *************************************************/

/**
 * \brief set the value val in the GPIO identified by the first argument
 *
 * The GPIO must be in output mode. The value is normalized in this function.
 *
 * \param[in] gpio the gpio structure identifying the GPIO
 * \param[in] val the value used to set the GPIO
 */
void gpio_set_value(gpioref_t kref, uint8_t val);

/**
 * \brief get the value of the GPIO identified by the first argument
 *
 * The GPIO must be in input mode. The value is normalized in this function.
 *
 * \param[in] gpio the gpio structure identifying the GPIO
 *
 * \return the value read in the GPIO input value register.
 */
uint8_t gpio_get_value(gpioref_t kref);

#endif                          /*!KERN_GPIO_ */
