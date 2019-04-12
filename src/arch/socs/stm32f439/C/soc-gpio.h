/* \file soc-gpio.h
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
#ifndef SOC_GPIO_H
#define SOC_GPIO_H

#include "C/regutils.h"
#include "soc-core.h"
#include "soc-rcc.h"
#include "C/exported/devices.h"
#include "C/exported/gpio.h"

#define GPIO_MODER(g)         REG_ADDR(g + 0x00)    /*!< GPIO port mode register                      */
#define GPIO_OTYPER(g)        REG_ADDR(g + 0x04)    /*!< GPIO port output type register               */
#define GPIO_OSPEEDR(g)       REG_ADDR(g + 0x08)    /*!< GPIO port output speed register              */
#define GPIO_PUPDR(g)         REG_ADDR(g + 0x0C)    /*!< GPIO port pull-up/pull-down register         */
#define GPIO_IDR(g)           REG_ADDR(g + 0x10)    /*!< GPIO port input data register                */
#define GPIO_ODR(g)           REG_ADDR(g + 0x14)    /*!< GPIO port output data register               */
#define GPIO_BSRR_R(g)        REG_ADDR(g + 0x18)    /*!< GPIO port bit set/reset reset register       */
#define GPIO_BSRR_S(g)        REG_ADDR(g + 0x1A)    /*!< GPIO port bit set/reset set register         */
#define GPIO_LCKR(g)          REG_ADDR(g + 0x1C)    /*!< GPIO port configuration lock register        */
#define GPIO_AFR_L(g)         REG_ADDR(g + 0x20)    /*!< GPIO alternate function registers, low part */
#define GPIO_AFR_H(g)         REG_ADDR(g + 0x24)    /*!< GPIO alternate function registers, high part  */

#define GPIOA                 REG_ADDR(GPIOA_BASE)
#define GPIOA_MODER           GPIO_MODER(GPIOA_BASE)
#define GPIOA_OTYPER          GPIO_OTYPER(GPIOA_BASE)
#define GPIOA_OSPEEDR         GPIO_OSPEEDR(GPIOA_BASE)
#define GPIOA_PUPDR           GPIO_PUPDR(GPIOA_BASE)
#define GPIOA_IDR             GPIO_IDR(GPIOA_BASE)
#define GPIOA_ODR             GPIO_ODR(GPIOA_BASE)
#define GPIOA_BSRR_R          GPIO_BSRR_R(GPIOA_BASE)
#define GPIOA_BSRR_S          GPIO_BSRR_S(GPIOA_BASE)
#define GPIOA_LCKR            GPIO_LCKR(GPIOA_BASE)
#define GPIOA_AFR_L           GPIO_AFR_L(GPIOA_BASE)
#define GPIOA_AFR_H           GPIO_AFR_H(GPIOA_BASE)

#define GPIOB                 REG_ADDR(GPIOB_BASE)
#define GPIOB_MODER           GPIO_MODER(GPIOB_BASE)
#define GPIOB_OTYPER          GPIO_OTYPER(GPIOB_BASE)
#define GPIOB_OSPEEDR         GPIO_OSPEEDR(GPIOB_BASE)
#define GPIOB_PUPDR           GPIO_PUPDR(GPIOB_BASE)
#define GPIOB_IDR             GPIO_IDR(GPIOB_BASE)
#define GPIOB_ODR             GPIO_ODR(GPIOB_BASE)
#define GPIOB_BSRR_R          GPIO_BSRR_R(GPIOB_BASE)
#define GPIOB_BSRR_S          GPIO_BSRR_S(GPIOB_BASE)
#define GPIOB_LCKR            GPIO_LCKR(GPIOB_BASE)
#define GPIOB_AFR_L           GPIO_AFR_L(GPIOB_BASE)
#define GPIOB_AFR_H           GPIO_AFR_H(GPIOB_BASE)

#define GPIOC                 REG_ADDR(GPIOC_BASE)
#define GPIOC_MODER           GPIO_MODER(GPIOC_BASE)
#define GPIOC_OTYPER          GPIO_OTYPER(GPIOC_BASE)
#define GPIOC_OSPEEDR         GPIO_OSPEEDR(GPIOC_BASE)
#define GPIOC_PUPDR           GPIO_PUPDR(GPIOC_BASE)
#define GPIOC_IDR             GPIO_IDR(GPIOC_BASE)
#define GPIOC_ODR             GPIO_ODR(GPIOC_BASE)
#define GPIOC_BSRR_R          GPIO_BSRR_R(GPIOC_BASE)
#define GPIOC_BSRR_S          GPIO_BSRR_S(GPIOC_BASE)
#define GPIOC_LCKR            GPIO_LCKR(GPIOC_BASE)
#define GPIOC_AFR_L           GPIO_AFR_L(GPIOC_BASE)
#define GPIOC_AFR_H           GPIO_AFR_H(GPIOC_BASE)

#define GPIOD                 REG_ADDR(GPIOD_BASE)
#define GPIOD_MODER           GPIO_MODER(GPIOD_BASE)
#define GPIOD_OTYPER          GPIO_OTYPER(GPIOD_BASE)
#define GPIOD_OSPEEDR         GPIO_OSPEEDR(GPIOD_BASE)
#define GPIOD_PUPDR           GPIO_PUPDR(GPIOD_BASE)
#define GPIOD_IDR             GPIO_IDR(GPIOD_BASE)
#define GPIOD_ODR             GPIO_ODR(GPIOD_BASE)
#define GPIOD_BSRR_R          GPIO_BSRR_R(GPIOD_BASE)
#define GPIOD_BSRR_S          GPIO_BSRR_S(GPIOD_BASE)
#define GPIOD_LCKR            GPIO_LCKR(GPIOD_BASE)
#define GPIOD_AFR_L           GPIO_AFR_L(GPIOD_BASE)
#define GPIOD_AFR_H           GPIO_AFR_H(GPIOD_BASE)

#define GPIOE                 REG_ADDR(GPIOE_BASE)
#define GPIOE_MODER           GPIO_MODER(GPIOE_BASE)
#define GPIOE_OTYPER          GPIO_OTYPER(GPIOE_BASE)
#define GPIOE_OSPEEDR         GPIO_OSPEEDR(GPIOE_BASE)
#define GPIOE_PUPDR           GPIO_PUPDR(GPIOE_BASE)
#define GPIOE_IDR             GPIO_IDR(GPIOE_BASE)
#define GPIOE_ODR             GPIO_ODR(GPIOE_BASE)
#define GPIOE_BSRR_R          GPIO_BSRR_R(GPIOE_BASE)
#define GPIOE_BSRR_S          GPIO_BSRR_S(GPIOE_BASE)
#define GPIOE_LCKR            GPIO_LCKR(GPIOE_BASE)
#define GPIOE_AFR_L           GPIO_AFR_L(GPIOE_BASE)
#define GPIOE_AFR_H           GPIO_AFR_H(GPIOE_BASE)

#define GPIOF                 REG_ADDR(GPIOF_BASE)
#define GPIOF_MODER           GPIO_MODER(GPIOF_BASE)
#define GPIOF_OTYPER          GPIO_OTYPER(GPIOF_BASE)
#define GPIOF_OSPEEDR         GPIO_OSPEEDR(GPIOF_BASE)
#define GPIOF_PUPDR           GPIO_PUPDR(GPIOF_BASE)
#define GPIOF_IDR             GPIO_IDR(GPIOF_BASE)
#define GPIOF_ODR             GPIO_ODR(GPIOF_BASE)
#define GPIOF_BSRR_R          GPIO_BSRR_R(GPIOF_BASE)
#define GPIOF_BSRR_S          GPIO_BSRR_S(GPIOF_BASE)
#define GPIOF_LCKR            GPIO_LCKR(GPIOF_BASE)
#define GPIOF_AFR_L           GPIO_AFR_L(GPIOF_BASE)
#define GPIOF_AFR_H           GPIO_AFR_H(GPIOF_BASE)

#define GPIOG                 REG_ADDR(GPIOG_BASE)
#define GPIOG_MODER           GPIO_MODER(GPIOG_BASE)
#define GPIOG_OTYPER          GPIO_OTYPER(GPIOG_BASE)
#define GPIOG_OSPEEDR         GPIO_OSPEEDR(GPIOG_BASE)
#define GPIOG_PUPDR           GPIO_PUPDR(GPIOG_BASE)
#define GPIOG_IDR             GPIO_IDR(GPIOG_BASE)
#define GPIOG_ODR             GPIO_ODR(GPIOG_BASE)
#define GPIOG_BSRR_R          GPIO_BSRR_R(GPIOG_BASE)
#define GPIOG_BSRR_S          GPIO_BSRR_S(GPIOG_BASE)
#define GPIOG_LCKR            GPIO_LCKR(GPIOG_BASE)
#define GPIOG_AFR_L           GPIO_AFR_L(GPIOG_BASE)
#define GPIOG_AFR_H           GPIO_AFR_H(GPIOG_BASE)

#define GPIOH                 REG_ADDR(GPIOH_BASE)
#define GPIOH_MODER           GPIO_MODER(GPIOH_BASE)
#define GPIOH_OTYPER          GPIO_OTYPER(GPIOH_BASE)
#define GPIOH_OSPEEDR         GPIO_OSPEEDR(GPIOH_BASE)
#define GPIOH_PUPDR           GPIO_PUPDR(GPIOH_BASE)
#define GPIOH_IDR             GPIO_IDR(GPIOH_BASE)
#define GPIOH_ODR             GPIO_ODR(GPIOH_BASE)
#define GPIOH_BSRR_R          GPIO_BSRR_R(GPIOH_BASE)
#define GPIOH_BSRR_S          GPIO_BSRR_S(GPIOH_BASE)
#define GPIOH_LCKR            GPIO_LCKR(GPIOH_BASE)
#define GPIOH_AFR_L           GPIO_AFR_L(GPIOH_BASE)
#define GPIOH_AFR_H           GPIO_AFR_H(GPIOH_BASE)

#define GPIOI                 REG_ADDR(GPIOI_BASE)
#define GPIOI_MODER           GPIO_MODER(GPIOI_BASE)
#define GPIOI_OTYPER          GPIO_OTYPER(GPIOI_BASE)
#define GPIOI_OSPEEDR         GPIO_OSPEEDR(GPIOI_BASE)
#define GPIOI_PUPDR           GPIO_PUPDR(GPIOI_BASE)
#define GPIOI_IDR             GPIO_IDR(GPIOI_BASE)
#define GPIOI_ODR             GPIO_ODR(GPIOI_BASE)
#define GPIOI_BSRR_R          GPIO_BSRR_R(GPIOI_BASE)
#define GPIOI_BSRR_S          GPIO_BSRR_S(GPIOI_BASE)
#define GPIOI_LCKR            GPIO_LCKR(GPIOI_BASE)
#define GPIOI_AFR_L           GPIO_AFR_L(GPIOI_BASE)
#define GPIOI_AFR_H           GPIO_AFR_H(GPIOI_BASE)

#define GPIO_PIN_0            ((uint16_t)0x0001)
#define GPIO_PIN_1            ((uint16_t)0x0002)
#define GPIO_PIN_2            ((uint16_t)0x0004)
#define GPIO_PIN_3            ((uint16_t)0x0008)
#define GPIO_PIN_4            ((uint16_t)0x0010)
#define GPIO_PIN_5            ((uint16_t)0x0020)
#define GPIO_PIN_6            ((uint16_t)0x0040)
#define GPIO_PIN_7            ((uint16_t)0x0080)
#define GPIO_PIN_8            ((uint16_t)0x0100)
#define GPIO_PIN_9            ((uint16_t)0x0200)
#define GPIO_PIN_10           ((uint16_t)0x0400)
#define GPIO_PIN_11           ((uint16_t)0x0800)
#define GPIO_PIN_12           ((uint16_t)0x1000)
#define GPIO_PIN_13           ((uint16_t)0x2000)
#define GPIO_PIN_14           ((uint16_t)0x4000)
#define GPIO_PIN_15           ((uint16_t)0x8000)
#define GPIO_PIN_ALL          ((uint16_t)0xFFFF)

/* RESET VALUES REGISTERS */
#define GPIOA_MODER_RESET     ((uint32_t)0xA8000000)
#define GPIOB_MODER_RESET     ((uint32_t)0x00000280)
#define GPIOC_MODER_RESET     ((uint32_t)0x00000000)
#define GPIOD_MODER_RESET     ((uint32_t)0x00000000)
#define GPIOE_MODER_RESET     ((uint32_t)0x00000000)
#define GPIOF_MODER_RESET     ((uint32_t)0x00000000)
#define GPIOG_MODER_RESET     ((uint32_t)0x00000000)
#define GPIOH_MODER_RESET     ((uint32_t)0x00000000)
#define GPIOI_MODER_RESET     ((uint32_t)0x00000000)

#define GPIOA_OTYPER_RESET    ((uint32_t)0x00000000)
#define GPIOB_OTYPER_RESET    ((uint32_t)0x00000000)
#define GPIOC_OTYPER_RESET    ((uint32_t)0x00000000)
#define GPIOD_OTYPER_RESET    ((uint32_t)0x00000000)
#define GPIOE_OTYPER_RESET    ((uint32_t)0x00000000)
#define GPIOF_OTYPER_RESET    ((uint32_t)0x00000000)
#define GPIOG_OTYPER_RESET    ((uint32_t)0x00000000)
#define GPIOH_OTYPER_RESET    ((uint32_t)0x00000000)
#define GPIOI_OTYPER_RESET    ((uint32_t)0x00000000)

#define GPIOA_OSPEEDER_RESET  ((uint32_t)0x0C000000)
#define GPIOB_OSPEEDER_RESET  ((uint32_t)0x000000C0)
#define GPIOC_OSPEEDER_RESET  ((uint32_t)0x00000000)
#define GPIOD_OSPEEDER_RESET  ((uint32_t)0x00000000)
#define GPIOE_OSPEEDER_RESET  ((uint32_t)0x00000000)
#define GPIOF_OSPEEDER_RESET  ((uint32_t)0x00000000)
#define GPIOG_OSPEEDER_RESET  ((uint32_t)0x00000000)
#define GPIOH_OSPEEDER_RESET  ((uint32_t)0x00000000)
#define GPIOI_OSPEEDER_RESET  ((uint32_t)0x00000000)

#define GPIOA_PUPDR_RESET     ((uint32_t)0x64000000)
#define GPIOB_PUPDR_RESET     ((uint32_t)0x00000100)
#define GPIOC_PUPDR_RESET     ((uint32_t)0x00000000)
#define GPIOD_PUPDR_RESET     ((uint32_t)0x00000000)
#define GPIOE_PUPDR_RESET     ((uint32_t)0x00000000)
#define GPIOF_PUPDR_RESET     ((uint32_t)0x00000000)
#define GPIOG_PUPDR_RESET     ((uint32_t)0x00000000)
#define GPIOH_PUPDR_RESET     ((uint32_t)0x00000000)
#define GPIOI_PUPDR_RESET     ((uint32_t)0x00000000)

#define GPIOA_ODR_RESET       ((uint32_t)0x00000000)
#define GPIOB_ODR_RESET       ((uint32_t)0x00000000)
#define GPIOC_ODR_RESET       ((uint32_t)0x00000000)
#define GPIOD_ODR_RESET       ((uint32_t)0x00000000)
#define GPIOE_ODR_RESET       ((uint32_t)0x00000000)
#define GPIOF_ODR_RESET       ((uint32_t)0x00000000)
#define GPIOG_ODR_RESET       ((uint32_t)0x00000000)
#define GPIOH_ODR_RESET       ((uint32_t)0x00000000)
#define GPIOI_ODR_RESET       ((uint32_t)0x00000000)

#define GPIOA_BSRR_RESET      ((uint32_t)0x00000000)
#define GPIOB_BSRR_RESET      ((uint32_t)0x00000000)
#define GPIOC_BSRR_RESET      ((uint32_t)0x00000000)
#define GPIOD_BSRR_RESET      ((uint32_t)0x00000000)
#define GPIOE_BSRR_RESET      ((uint32_t)0x00000000)
#define GPIOF_BSRR_RESET      ((uint32_t)0x00000000)
#define GPIOG_BSRR_RESET      ((uint32_t)0x00000000)
#define GPIOH_BSRR_RESET      ((uint32_t)0x00000000)
#define GPIOI_BSSR_RESET      ((uint32_t)0x00000000)

#define GPIOA_LCKR_RESET      ((uint32_t)0x00000000)
#define GPIOB_LCKR_RESET      ((uint32_t)0x00000000)
#define GPIOC_LCKR_RESET      ((uint32_t)0x00000000)
#define GPIOD_LCKR_RESET      ((uint32_t)0x00000000)
#define GPIOE_LCKR_RESET      ((uint32_t)0x00000000)
#define GPIOF_LCKR_RESET      ((uint32_t)0x00000000)
#define GPIOG_LCKR_RESET      ((uint32_t)0x00000000)
#define GPIOH_LCKR_RESET      ((uint32_t)0x00000000)
#define GPIOI_LCKR_RESET      ((uint32_t)0x00000000)

#define GPIOA_AFRL_RESET      ((uint32_t)0x00000000)
#define GPIOB_AFRL_RESET      ((uint32_t)0x00000000)
#define GPIOC_AFRL_RESET      ((uint32_t)0x00000000)
#define GPIOD_AFRL_RESET      ((uint32_t)0x00000000)
#define GPIOE_AFRL_RESET      ((uint32_t)0x00000000)
#define GPIOF_AFRL_RESET      ((uint32_t)0x00000000)
#define GPIOG_AFRL_RESET      ((uint32_t)0x00000000)
#define GPIOH_AFRL_RESET      ((uint32_t)0x00000000)
#define GPIOI_AFRL_RESET      ((uint32_t)0x00000000)

#define GPIOA_AFRH_RESET      ((uint32_t)0x00000000)
#define GPIOB_AFRH_RESET      ((uint32_t)0x00000000)
#define GPIOC_AFRH_RESET      ((uint32_t)0x00000000)
#define GPIOD_AFRH_RESET      ((uint32_t)0x00000000)
#define GPIOE_AFRH_RESET      ((uint32_t)0x00000000)
#define GPIOF_AFRH_RESET      ((uint32_t)0x00000000)
#define GPIOG_AFRH_RESET      ((uint32_t)0x00000000)
#define GPIOH_AFRH_RESET      ((uint32_t)0x00000000)
#define GPIOI_AFRH_RESET      ((uint32_t)0x00000000)

/* Definition of the alternate functions used
 * for GPIOs. See Figure 14 "Selecting an alternate function"
 * in the datasheet.
 */
/* AF0 (system) */
#define GPIO_AF_AF0            0x0
#define GPIO_AF_SYSTEM         GPIO_AF_AF0
/* AF1 (TIM1/TIM2) */
#define GPIO_AF_AF1            0x1
#define GPIO_AF_TIM1           GPIO_AF_AF1
#define GPIO_AF_TIM2           GPIO_AF_AF1
/* AF2 (TIM3..5) */
#define GPIO_AF_AF2            0x2
#define GPIO_AF_TIM3           GPIO_AF_AF2
#define GPIO_AF_TIM4           GPIO_AF_AF2
#define GPIO_AF_TIM5           GPIO_AF_AF2
/* AF3 (TIM8..11) */
#define GPIO_AF_AF3            0x3
#define GPIO_AF_TIM8           GPIO_AF_AF3
#define GPIO_AF_TIM9           GPIO_AF_AF3
#define GPIO_AF_TIM10          GPIO_AF_AF3
#define GPIO_AF_TIM11          GPIO_AF_AF3
/* AF4 (I2C1..3) */
#define GPIO_AF_AF4            0x4
#define GPIO_AF_I2C1           GPIO_AF_AF4
#define GPIO_AF_I2C2           GPIO_AF_AF4
#define GPIO_AF_I2C3           GPIO_AF_AF4
/* AF5 (SPI1/SPI2) */
#define GPIO_AF_AF5            0x5
#define GPIO_AF_SPI1           GPIO_AF_AF5
#define GPIO_AF_SPI2           GPIO_AF_AF5
/* AF6 (SPI3) */
#define GPIO_AF_AF6            0x6
#define GPIO_AF_SPI3           GPIO_AF_AF6
/* AF7 (USART1..3) */
#define GPIO_AF_AF7            0x7
#define GPIO_AF_USART1         GPIO_AF_AF7
#define GPIO_AF_USART2         GPIO_AF_AF7
#define GPIO_AF_USART3         GPIO_AF_AF7
/* AF8 (USART4..6) */
#define GPIO_AF_AF8            0x8
#define GPIO_AF_USART4         GPIO_AF_AF8
#define GPIO_AF_UART4          GPIO_AF_AF8
#define GPIO_AF_USART5         GPIO_AF_AF8
#define GPIO_AF_UART5          GPIO_AF_AF8
#define GPIO_AF_USART6         GPIO_AF_AF8
/* AF9 (CAN1/CAN2, TIM12..14) */
#define GPIO_AF_AF9            0x9
#define GPIO_AF_CAN1           GPIO_AF_AF9
#define GPIO_AF_CAN2           GPIO_AF_AF9
#define GPIO_AF_TIM12          GPIO_AF_AF9
#define GPIO_AF_TIM13          GPIO_AF_AF9
#define GPIO_AF_TIM14          GPIO_AF_AF9
/* AF10 (OTG_FS, OTG_HS) */
#define GPIO_AF_AF10           0xa
#define GPIO_AF_OTG_FS         GPIO_AF_AF10
#define GPIO_AF_OTG_HS         GPIO_AF_AF10
/* AF11 (ETH) */
#define GPIO_AF_AF11           0xb
#define GPIO_AF_ETH            GPIO_AF_AF11
/* AF12 (FSMC, SDIO, OTG_HS_FS) */
#define GPIO_AF_AF12           0xc
#define GPIO_AF_FSMC           GPIO_AF_AF12
#define GPIO_AF_SDIO           GPIO_AF_AF12
#define GPIO_AF_OTG_HS_FS      GPIO_AF_AF12
/* AF13 (DCMI) */
#define GPIO_AF_AF13           0xd
#define GPIO_AF_DCMI           GPIO_AF_AF13
/* AF14 */
#define GPIO_AF_AF14           0xe
/* AF15 (EVENTOUT) */
#define GPIO_AF_AF15           0xf
#define GPIO_AF_EVENTOUT       GPIO_AF_AF15

/*
 * Configure a GPIO given an associated structure, including
 * a configuration mask
 */
uint8_t soc_gpio_set_config(const dev_gpio_info_t * gpio);

/*
 * Relaese the GPIO, including deactivating the RCC clock
 */
uint8_t soc_gpio_release(const dev_gpio_info_t * gpio);

uint8_t soc_gpio_configure
    (uint8_t port, uint8_t pin,
     gpio_mode_t mode,
     gpio_type_t type,
     gpio_speed_t speed,
     gpio_pupd_t pupd,
     gpio_af_t afr);

/*
 * GPIO value accessors (set, get, clear)
 */
void    soc_gpio_set_value(gpioref_t   kref,
                           uint8_t   value);

uint8_t soc_gpio_get(gpioref_t   kref);

#endif/*!SOC_GPIO_H */
