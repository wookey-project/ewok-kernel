/* gpio.c
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

#include "gpio.h"
#include "tasks.h"
#include "debug.h"

/*
 * Table of current GPIO state, set to 0x1 when the GPIO is used by a driver
 * Its position in the table define its number (port/pin)
 * GPIO pin number and naming is generic. The number of ports varies, which makes
 * only gpios_max_num differs depending on the SoC.
 */
uint8_t gpio_state[] = {
    0x0,                        /* GPIOA pin 0 */
    0x0,                        /* GPIOA pin 1 */
    0x0,                        /* GPIOA pin 2, USART2 */
    0x0,                        /* GPIOA pin 3, USART2 */
    0x0,                        /* GPIOA pin 4 */
    0x0,                        /* GPIOA pin 5 */
    0x0,                        /* GPIOA pin 6 */
    0x0,                        /* GPIOA pin 7 */
    0x0,                        /* GPIOA pin 8 */
    0x0,                        /* GPIOA pin 9 */
    0x0,                        /* GPIOA pin a */
    0x0,                        /* GPIOA pin b */
    0x0,                        /* GPIOA pin c */
    0x0,                        /* GPIOA pin d */
    0x0,                        /* GPIOA pin e */
    0x0,                        /* GPIOA pin f */
     /**/
    0x0,                        /* GPIOB pin 0 */
    0x0,                        /* GPIOB pin 1 */
    0x0,                        /* GPIOB pin 2 */
    0x0,                        /* GPIOB pin 3 */
    0x0,                        /* GPIOB pin 4 */
    0x0,                        /* GPIOB pin 5 */
    0x0,                        /* GPIOB pin 6, USART1*/
    0x0,                        /* GPIOB pin 7, USART1 */
    0x0,                        /* GPIOB pin 8 */
    0x0,                        /* GPIOB pin 9 */
    0x0,                        /* GPIOB pin a, USART3 */
    0x0,                        /* GPIOB pin b, USART3 */
    0x0,                        /* GPIOB pin c */
    0x0,                        /* GPIOB pin d */
    0x0,                        /* GPIOB pin e */
    0x0,                        /* GPIOB pin f */
     /**/
    0x0,                        /* GPIOC pin 0 */
    0x0,                        /* GPIOC pin 1 */
    0x0,                        /* GPIOC pin 2, USART5 */
    0x0,                        /* GPIOC pin 3 */
    0x0,                        /* GPIOC pin 4 */
    0x0,                        /* GPIOC pin 5 */
    0x0,                        /* GPIOC pin 6, USART6 */
    0x0,                        /* GPIOC pin 7, USART6 */
    0x0,                        /* GPIOC pin 8 */
    0x0,                        /* GPIOC pin 9 */
    0x0,                        /* GPIOC pin a, USART4 */
    0x0,                        /* GPIOC pin b, USART4 */
    0x0,                        /* GPIOC pin c, USART5 */
    0x0,                        /* GPIOC pin d */
    0x0,                        /* GPIOC pin e */
    0x0,                        /* GPIOC pin f */
     /**/
    0x0,                        /* GPIOD pin 0 */
    0x0,                        /* GPIOD pin 1 */
    0x0,                        /* GPIOD pin 2 */
    0x0,                        /* GPIOD pin 3 */
    0x0,                        /* GPIOD pin 4 */
    0x0,                        /* GPIOD pin 5 */
    0x0,                        /* GPIOD pin 6 */
    0x0,                        /* GPIOD pin 7 */
    0x0,                        /* GPIOD pin 8 */
    0x0,                        /* GPIOD pin 9 */
    0x0,                        /* GPIOD pin a */
    0x0,                        /* GPIOD pin b */
    0x0,                        /* GPIOD pin c */
    0x0,                        /* GPIOD pin d */
    0x0,                        /* GPIOD pin e */
    0x0,                        /* GPIOD pin f */
     /**/
    0x0,                        /* GPIOE pin 0 */
    0x0,                        /* GPIOE pin 1 */
    0x0,                        /* GPIOE pin 2 */
    0x0,                        /* GPIOE pin 3 */
    0x0,                        /* GPIOE pin 4 */
    0x0,                        /* GPIOE pin 5 */
    0x0,                        /* GPIOE pin 6 */
    0x0,                        /* GPIOE pin 7 */
    0x0,                        /* GPIOE pin 8 */
    0x0,                        /* GPIOE pin 9 */
    0x0,                        /* GPIOE pin a */
    0x0,                        /* GPIOE pin b */
    0x0,                        /* GPIOE pin c */
    0x0,                        /* GPIOE pin d */
    0x0,                        /* GPIOE pin e */
    0x0,                        /* GPIOE pin f */
     /**/
    0x0,                        /* GPIOF pin 0 */
    0x0,                        /* GPIOF pin 1 */
    0x0,                        /* GPIOF pin 2 */
    0x0,                        /* GPIOF pin 3 */
    0x0,                        /* GPIOF pin 4 */
    0x0,                        /* GPIOF pin 5 */
    0x0,                        /* GPIOF pin 6 */
    0x0,                        /* GPIOF pin 7 */
    0x0,                        /* GPIOF pin 8 */
    0x0,                        /* GPIOF pin 9 */
    0x0,                        /* GPIOF pin a */
    0x0,                        /* GPIOF pin b */
    0x0,                        /* GPIOF pin c */
    0x0,                        /* GPIOF pin d */
    0x0,                        /* GPIOF pin e */
    0x0,                        /* GPIOF pin f */
     /**/
    0x0,                        /* GPIOG pin 0 */
    0x0,                        /* GPIOG pin 1 */
    0x0,                        /* GPIOG pin 2 */
    0x0,                        /* GPIOG pin 3 */
    0x0,                        /* GPIOG pin 4 */
    0x0,                        /* GPIOG pin 5 */
    0x0,                        /* GPIOG pin 6 */
    0x0,                        /* GPIOG pin 7 */
    0x0,                        /* GPIOG pin 8 */
    0x0,                        /* GPIOG pin 9 */
    0x0,                        /* GPIOG pin a */
    0x0,                        /* GPIOG pin b */
    0x0,                        /* GPIOG pin c */
    0x0,                        /* GPIOG pin d */
    0x0,                        /* GPIOG pin e */
    0x0,                        /* GPIOG pin f */
     /**/
    0x0,                        /* GPIOH pin 0 */
    0x0,                        /* GPIOH pin 1 */
    0x0,                        /* GPIOH pin 2 */
    0x0,                        /* GPIOH pin 3 */
    0x0,                        /* GPIOH pin 4 */
    0x0,                        /* GPIOH pin 5 */
    0x0,                        /* GPIOH pin 6 */
    0x0,                        /* GPIOH pin 7 */
    0x0,                        /* GPIOH pin 8 */
    0x0,                        /* GPIOH pin 9 */
    0x0,                        /* GPIOH pin a */
    0x0,                        /* GPIOH pin b */
    0x0,                        /* GPIOH pin c */
    0x0,                        /* GPIOH pin d */
    0x0,                        /* GPIOH pin e */
    0x0,                        /* GPIOH pin f */
     /**/
    0x0,                        /* GPIOI pin 0 */
    0x0,                        /* GPIOI pin 1 */
    0x0,                        /* GPIOI pin 2 */
    0x0,                        /* GPIOI pin 3 */
    0x0,                        /* GPIOI pin 4 */
    0x0,                        /* GPIOI pin 5 */
    0x0,                        /* GPIOI pin 6 */
    0x0,                        /* GPIOI pin 7 */
    0x0,                        /* GPIOI pin 8 */
    0x0,                        /* GPIOI pin 9 */
    0x0,                        /* GPIOI pin a */
    0x0,                        /* GPIOI pin b */
    0x0,                        /* GPIOI pin c */
    0x0,                        /* GPIOI pin d */
    0x0,                        /* GPIOI pin e */
    0x0,                        /* GPIOI pin f */
};

uint8_t gpio_max_num = sizeof(gpio_state) / sizeof(uint8_t);


/**
 * \brief Check if the GPIO is already used or not
 *
 * \param[in] gpio GPIO identifier, corresponding to the gpio structure
 *            kref field
 * \return true if the GPIO is free to use, false if the GPIO is already used.
 */
static bool gpio_is_free(gpioref_t kref)
{
    if (kref.val < gpio_max_num && gpio_state[kref.val] == 0x0) {
        return true;
    }
    return false;
}

/**
 * \brief register the GPIO identified by the gpio param
 * This function only set the given GPIO as used, making future
 * call to gpio_is_free() returning false.
 *
 * \param[in] gpio GPIO identifier, corresponding to the gpio structure
 *            kref field
 *
 * \return nothing, the gpio is reserved. This function doesn't check
 */
uint8_t gpio_register_gpio
    (e_task_id task_id, e_device_id dev_id, const dev_gpio_info_t * gpio)
{
    task_id = task_id;
    dev_id  = dev_id;

    if (!gpio_is_free(gpio->kref)) {
        KERNLOG(DBG_ERR, "Given gpio %x is already used!\n", gpio->kref.val);
        return 1;
    }

    gpio_state[gpio->kref.val] = 1;
    return 0;
}

uint8_t
gpio_release_gpio(const dev_gpio_info_t * gpio)
{
    if (gpio_is_free(gpio->kref)) {
        KERNLOG(DBG_ERR, "Given gpio %x already freed!\n", gpio->kref.val);
        return 1;
    }

    soc_gpio_release(gpio);

    gpio_state[gpio->kref.val] = 0;
    return 0;
}

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
uint8_t gpio_enable_gpio(const dev_gpio_info_t * gpio)
{
#if CONFIG_DEBUG > 2
    KERNLOG("enabled GPIO port %c, pin %x\n", gpio->kref.port,
            gpio->kref.pin);
#endif
    return soc_gpio_set_config(gpio);
}

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
void gpio_set_value(gpioref_t kref, uint8_t val)
{
    soc_gpio_set_value(kref, val);
}

/**
 * \brief get the value of the GPIO identified by the first argument
 *
 * The GPIO must be in input mode. The value is normalized in this function.
 *
 * \param[in] gpio the gpio structure identifying the GPIO
 *
 * \return the value read in the GPIO input value register.
 */
uint8_t gpio_get_value(gpioref_t kref)
{
    return soc_gpio_get(kref);
}

