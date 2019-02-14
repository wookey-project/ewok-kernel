/*
 * \file gpio.h
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
#ifndef KERNEL_GPIO_H
#define KERNEL_GPIO_H
/*
 * Remember to include libstd types.h header for stdint support
 */

/**< The maximum number of GPIO lines per device*/
#define MAX_GPIOS 16

typedef void (*user_handler_t) (uint8_t irq, uint32_t status, uint32_t data);

/*
 * GPIO Alternate functions (numeric values)
 */
typedef enum {
    GPIO_AF_AF0   =  0x0,
    GPIO_AF_AF1   =  0x1,
    GPIO_AF_AF2   =  0x2,
    GPIO_AF_AF3   =  0x3,
    GPIO_AF_AF4   =  0x4,
    GPIO_AF_AF5   =  0x5,
    GPIO_AF_AF6   =  0x6,
    GPIO_AF_AF7   =  0x7,
    GPIO_AF_AF8   =  0x8,
    GPIO_AF_AF9   =  0x9,
    GPIO_AF_AF10  =  0xa,
    GPIO_AF_AF11  =  0xb,
    GPIO_AF_AF12  =  0xc,
    GPIO_AF_AF13  =  0xd,
    GPIO_AF_AF14  =  0xe,
    GPIO_AF_AF15  =  0xf
} gpio_af_t;

/*
 * GPIO alternate functions
 * human readable values, using macros, these are still gpio_af_t.
 */
#define GPIO_AF_SYSTEM      GPIO_AF_AF0
#define GPIO_AF_TIM1        GPIO_AF_AF1
#define GPIO_AF_TIM2        GPIO_AF_AF1
#define GPIO_AF_TIM3        GPIO_AF_AF2
#define GPIO_AF_TIM4        GPIO_AF_AF2
#define GPIO_AF_TIM5        GPIO_AF_AF2
#define GPIO_AF_TIM8        GPIO_AF_AF3
#define GPIO_AF_TIM9        GPIO_AF_AF3
#define GPIO_AF_TIM10       GPIO_AF_AF3
#define GPIO_AF_TIM11       GPIO_AF_AF3
#define GPIO_AF_I2C1        GPIO_AF_AF4
#define GPIO_AF_I2C2        GPIO_AF_AF4
#define GPIO_AF_I2C3        GPIO_AF_AF4
#define GPIO_AF_SPI1        GPIO_AF_AF5
#define GPIO_AF_SPI2        GPIO_AF_AF5
#define GPIO_AF_SPI3        GPIO_AF_AF6
#define GPIO_AF_USART1      GPIO_AF_AF7
#define GPIO_AF_USART2      GPIO_AF_AF7
#define GPIO_AF_USART3      GPIO_AF_AF7
#define GPIO_AF_USART4      GPIO_AF_AF8
#define GPIO_AF_UART4       GPIO_AF_AF8
#define GPIO_AF_USART5      GPIO_AF_AF8
#define GPIO_AF_UART5       GPIO_AF_AF8
#define GPIO_AF_USART6      GPIO_AF_AF8
#define GPIO_AF_CAN1        GPIO_AF_AF9
#define GPIO_AF_CAN2        GPIO_AF_AF9
#define GPIO_AF_TIM12       GPIO_AF_AF9
#define GPIO_AF_TIM13       GPIO_AF_AF9
#define GPIO_AF_TIM14       GPIO_AF_AF9
#define GPIO_AF_OTG_FS      GPIO_AF_AF10
#define GPIO_AF_OTG_HS      GPIO_AF_AF10
#define GPIO_AF_ETH         GPIO_AF_AF11
#define GPIO_AF_FSMC        GPIO_AF_AF12
#define GPIO_AF_SDIO        GPIO_AF_AF12
#define GPIO_AF_OTG_HS_FS   GPIO_AF_AF12
#define GPIO_AF_DCMI        GPIO_AF_AF13
#define GPIO_AF_EVENTOUT    GPIO_AF_AF15

/**
 * GPIO inputs mode
 */
typedef enum {
	GPIO_NOPULL = 0,
		   /**< GPIO pin in No Pull mode */
	GPIO_PULLUP = 1,
		   /**< GPIO pin in Pull UP mode */
	GPIO_PULLDOWN = 2,
		   /**< GPIO pin in Pull Down mode */
} gpio_pupd_t;

/**
 * GPIO direction
 */
typedef enum {
	GPIO_PIN_INPUT_MODE = 0,
			   /**< GPIO pin in input mode */
	GPIO_PIN_OUTPUT_MODE = 1,
			   /**< GPIO pin in output mode */
	GPIO_PIN_ALTERNATE_MODE = 2,
			   /**< GPIO pin in anternative mode */
	GPIO_PIN_ANALOG_MODE = 3
			   /**< GPIO pin in analogic mode */
} gpio_mode_t;

/**
 * GPIO speed, depending on the value measured (timer, sensor...)
 */
typedef enum {
	GPIO_PIN_LOW_SPEED = 0,
			   /**< GPIO pin in low speed mode */
	GPIO_PIN_MEDIUM_SPEED = 1,
			   /**< GPIO pin in medium speed mode */
	GPIO_PIN_HIGH_SPEED = 2,
			   /**< GPIO pin in high speed mode */
	GPIO_PIN_VERY_HIGH_SPEED = 3,
			   /**< GPIO pin in very high speed mode */
} gpio_speed_t;

/**
 * GPIO ouputs mode
 */
typedef enum {
	GPIO_PIN_OTYPER_PP = 0,
			  /**< GPIO pin in Push-Pull mode */
	GPIO_PIN_OTYPER_OD = 1,
			  /**< GPIO pin in Open-Drain mode */
} gpio_type_t;


typedef enum {
  GPIO_MASK_SET_MODE  = 0b000000001,
  GPIO_MASK_SET_TYPE  = 0b000000010,
  GPIO_MASK_SET_SPEED = 0b000000100,
  GPIO_MASK_SET_PUPD  = 0b000001000,
  GPIO_MASK_SET_BSR_R = 0b000010000,
  GPIO_MASK_SET_BSR_S = 0b000100000,
  GPIO_MASK_SET_LCK   = 0b001000000,
  GPIO_MASK_SET_AFR   = 0b010000000,
  GPIO_MASK_SET_EXTI  = 0b100000000,
  GPIO_MASK_SET_ALL   = 0b111111111,
} gpio_mask_t;


typedef enum {
    /** No EXTI line for this GPIO */
  GPIO_EXTI_TRIGGER_NONE = 0,
    /** Trigger intterupt on rising edge only */
  GPIO_EXTI_TRIGGER_RISE,
    /** Trigger intterupt on falling edge only */
  GPIO_EXTI_TRIGGER_FALL,
    /** Trigger intterupt on both rising and falling edges */
  GPIO_EXTI_TRIGGER_BOTH
} gpio_exti_trigger_t;

/*
 * Lock EXTI line when the EXTI interrupt arrise ?
 */
typedef enum {
  /** Don't lock EXTI line, other EXTI interrupts can continue to arrise */
  GPIO_EXTI_UNLOCKED = 0,
  /** Lock EXTI line at handler time, the ISR has to voluntary re-enable it */
  GPIO_EXTI_LOCKED
} gpio_exti_lock_t;

/**
** \brief This is the GPIO informational structure for user drivers
**
** A device may require GPIO configuration. If yes,
** this structure must be fullfill by the userspace but the
** configuration is done by the kernel (no direct mapping of
** the GPIO configuration registers)
*/
typedef union {
    struct {
        unsigned char pin  : 4;
        unsigned char port : 4;
    };
    unsigned char val;
} gpioref_t;

/* GPIO ports */
#define GPIO_PA 0
#define GPIO_PB 1
#define GPIO_PC 2
#define GPIO_PD 3
#define GPIO_PE 4
#define GPIO_PF 5
#define GPIO_PG 6
#define GPIO_PH 7
#define GPIO_PI 8

typedef struct {
    gpio_mask_t mask;

    /**< GPIO kernel reference
     *   = concatenation of the GPIO port (4 bits) and the pin number (4 bits)
     *
     *   If set at 1 before registration, the kernel will dynamicaly allocate
     *   a free port/pin and update kref accordingly.
     *
     *   If set to 0 before registration, the kernel will use port & pin
     *   directly. GPIO port use at registration are named using 'A', 'B', ...
     *   up to the last GPIO port available (e.g. 'I' for STM32F4xx)
     */
	gpioref_t           kref;

	gpio_mode_t         mode;
	gpio_pupd_t         pupd;
	gpio_type_t         type;
	gpio_speed_t        speed;
	uint32_t            afr;
	uint32_t            bsr_r;
	uint32_t            bsr_s;
	uint32_t            lck;
    gpio_exti_trigger_t exti_trigger;
    gpio_exti_lock_t    exti_lock;
	user_handler_t      exti_handler;

} dev_gpio_info_t;

#endif
