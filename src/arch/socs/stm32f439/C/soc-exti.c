/* \file soc-exti.c
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
#include "soc-exti.h"
#include "soc-nvic.h"
#include "soc-interrupts.h"
#include "soc-rcc.h"
#include "C/exported/devices.h"

#define EXTI               REG_ADDR(EXTI_BASE)
#define EXTI_IMR           REG_ADDR(EXTI_BASE + 0x00)   /*!< Interrupt mask register            */
#define EXTI_EMR           REG_ADDR(EXTI_BASE + 0x04)   /*!< Event mask register                */
#define EXTI_RTSR          REG_ADDR(EXTI_BASE + 0x08)   /*!< Rising trigger selection register  */
#define EXTI_FTSR          REG_ADDR(EXTI_BASE + 0x0C)   /*!< Falling trigger selection register */
#define EXTI_SWIER         REG_ADDR(EXTI_BASE + 0x10)   /*!< Software interrupt event register  */
#define EXTI_PR            REG_ADDR(EXTI_BASE + 0x14)   /*!< Pending register                   */

#define EXTI_IMR_DEFAUT    ((uint32_t)0x00000000)
#define EXTI_EMR_DEFAUT    ((uint32_t)0x00000000)
#define EXTI_RTSR_DEFAUT   ((uint32_t)0x00000000)
#define EXTI_FTSR_DEFAUT   ((uint32_t)0x00000000)
#define EXTI_SWIER_DEFAUT  ((uint32_t)0x00000000)

/*
 * EXTI allows one and only one EXTI line per pin, whatever the port is.
 * There is 16 EXTI lines for 16 pin (0 => 15).
 *
 * SYSCFG_CR1 manages config for pin  0 => 3
 * SYSCFG_CR2 manages config for pin  4 => 7
 * SYSCFG_CR3 manages config for pin  8 => 11
 * SYSCFG_CR4 manages config for pin 12 => 15
 *
 * This function returns the corresponding EXTI register
 */
static uint32_t *soc_exti_get_SYSCFG_EXTICR(uint8_t pin)
{
  switch (pin) {
      case 0:
      case 1:
      case 2:
      case 3:
          return SYSCFG_EXTICR1;
          break;
      case 4:
      case 5:
      case 6:
      case 7:
          return SYSCFG_EXTICR2;
          break;
      case 8:
      case 9:
      case 10:
      case 11:
          return SYSCFG_EXTICR3;
          break;
      case 12:
      case 13:
      case 14:
      case 15:
          return SYSCFG_EXTICR4;
          break;
      default:
          return 0;
  }

}

/*
 * EXTI allows one and only one EXTI line per pin, whatever the port is.
 * There is 16 EXTI lines for 16 pin (0 => 15).
 *
 * SYSCFG_CR1 manages config for pin  0 => 3
 * SYSCFG_CR2 manages config for pin  4 => 7
 * SYSCFG_CR3 manages config for pin  8 => 11
 * SYSCFG_CR4 manages config for pin 12 => 15
 *
 * This function return the register field position
 */
static uint8_t soc_exti_get_pos(uint8_t pin)
{
  switch (pin) {
      case 0:
      case 4:
      case 8:
      case 12:
          return 0;
          break;
      case 1:
      case 5:
      case 9:
      case 13:
          return 4;
          break;
      case 2:
      case 6:
      case 10:
      case 14:
          return 8;
          break;
      case 3:
      case 7:
      case 11:
      case 15:
          return 12;
          break;
      default:
          return 0;
  }
}



/*
 * Return the bit (or the bitfield) of the pending IT lines of the
 * EXTI for the corresponding IRQ
 */
uint32_t soc_exti_get_pending_lines(uint8_t irq)
{
    switch (irq) {
        case EXTI0_IRQ:
            return get_reg_value(EXTI_PR, 0x1, 0);
            break;
        case EXTI1_IRQ:
            return get_reg_value(EXTI_PR, 0x1 << 1, 1);
            break;
        case EXTI2_IRQ:
            return get_reg_value(EXTI_PR, 0x1 << 2, 2);
            break;
        case EXTI3_IRQ:
            return get_reg_value(EXTI_PR, 0x1 << 3, 3);
            break;
        case EXTI4_IRQ:
            return get_reg_value(EXTI_PR, 0x1 << 4, 4);
            break;
        case EXTI9_5_IRQ:
            return get_reg_value(EXTI_PR, 0x1f << 5, 5);
            break;
        case EXTI15_10_IRQ:
            return get_reg_value(EXTI_PR, 0x3f << 10, 10);
            break;
        default:
            return 0;
    }
}

/*
 * From the pin number, return the corresponding EXTI line configured GPIO
 * port.
 * CAUTION: this function doesn't check that the EXTI line has been previously
 * configured
 */
uint8_t soc_exti_get_syscfg_exticr_port(uint8_t pin)
{
    uint32_t   *regaddr = NULL;
    uint8_t     pos = 0;

    regaddr = soc_exti_get_SYSCFG_EXTICR(pin);
    pos = soc_exti_get_pos(pin);

    if (regaddr) {
      return get_reg_value(regaddr, 0xf << pos, pos);
    }
    return 0xF;
}

/*
 * Clean EXTI line pending bit
 */
void soc_exti_clear_pending(uint8_t pin)
{
    set_reg_bits(EXTI_PR, (0x1 << pin));
}

/*
 * Configure an EXTI line for a given GPIO
 * if the EXTI line for this pin is already set, return 1, otherwhise
 * set it and return 0.
 * This function does not enable the corresponding NVIC line neither the
 * EXTI IMR bit (this is done using soc_exti_enable() function)
 *
 */
uint8_t soc_exti_config(dev_gpio_info_t *gpio)
{
    volatile uint32_t *reg = 0;
    uint8_t pos = 0;
    uint8_t field = 0;

    /****************************************************
     * Initial input checks
     ***************************************************/

    /* If EXTI mask not set, just return */
    if (!(gpio->mask & GPIO_MASK_SET_EXTI)) {
        return 0;
    }

    /* Mask set but no EXTI use, just return */
    if (gpio->exti_trigger == GPIO_EXTI_TRIGGER_NONE) {
        return 0;
    }

    /* If EXTI line is not free, return with an error */
    if (!soc_exti_is_free(gpio->kref)) {
        return 2;
    }

    /****************************************************
     * Effective configuration
     ***************************************************/

    /* Get EXTICRx register addr */
    reg = soc_exti_get_SYSCFG_EXTICR(gpio->kref.pin);

    /* Invalid register ! input pin value incorrect */
    if (!reg) {
        return 1;
    }

    /* Get EXTICRx field position in register */
    pos = soc_exti_get_pos(gpio->kref.pin);

    /*
     * Switching on GPIO port, to generate the field value for EXTICRx register.
     * In the datasheet (STM-RM0090, it seems that port num (starting with 0)
     * == field value. See STM-RM0090 §9.3.3.
     *
     * i.e. port 0 (A) -> field = 0, port 1 (B) -> field = 0x1, etc.
     */
    field = gpio->kref.port;
    set_reg_bits(reg, field << pos);

    /*
     * Configure Rising Trigger for current GPIO (if needed)
     */
    if (gpio->exti_trigger == GPIO_EXTI_TRIGGER_RISE ||
        gpio->exti_trigger == GPIO_EXTI_TRIGGER_BOTH)
    {
        set_reg_bits(EXTI_RTSR, 0x1 << gpio->kref.pin);
    }

    /*
     * Configure Falling Trigger for current GPIO (if needed)
     */
    if (gpio->exti_trigger == GPIO_EXTI_TRIGGER_FALL ||
        gpio->exti_trigger == GPIO_EXTI_TRIGGER_BOTH)
    {
        set_reg_bits(EXTI_FTSR, 0x1 << gpio->kref.pin);
    }

    return 0;
}

/**
 * return true if the EXTI line associated to the GPIO pin is not
 * already set
 */
bool soc_exti_is_free(gpioref_t kref)
{
    uint32_t exti_line_im = get_reg_value(EXTI_IMR, 0x1 << kref.pin, kref.pin);
    if (exti_line_im == 1) {
        /**
         * The Interrupt Mask for this EXTI line is set to 1, this means that
         * it as already been set previously.
         * This line is busy and can't be overridden.
         */
        return false;
    }
    return true;
}

/*
 * Disable the EXTI line. This only clear the IMR EXTI register bit (NVIC
 * stays untouched as some EXTI lines are shared in a signe IRQ
 */
void soc_exti_disable(gpioref_t kref)
{
    /*
     * First, unable the Interrupt Mask Register for this line
     */
    clear_reg_bits(EXTI_IMR, 0x1 << kref.pin);
}

/*
 * Enable the EXTI line. This means:
 * 1) Activate the EXTI_IMR bit of the corresponding pin
 * 2) Enable the corresponding IRQ line in the NVIC(may be already done for
 * multiplexed EXTI IRQs)
 */
uint8_t soc_exti_enable(gpioref_t kref)
{
    /*
     * First, unable the Interrupt Mask Register for this line
     */
    set_reg_bits(EXTI_IMR, 0x1 << kref.pin);

    /*
     * Then enable the corresponding EXTI NVIC line
     */
    switch (kref.pin) {
        case 0:
            NVIC_EnableIRQ(EXTI0_IRQ - 0x10);
            break;
        case 1:
            NVIC_EnableIRQ(EXTI1_IRQ - 0x10);
            break;
        case 2:
            NVIC_EnableIRQ(EXTI2_IRQ - 0x10);
            break;
        case 3:
            NVIC_EnableIRQ(EXTI3_IRQ - 0x10);
            break;
        case 4:
            NVIC_EnableIRQ(EXTI4_IRQ - 0x10);
            break;
        case 5:
        case 6:
        case 7:
        case 8:
        case 9:
            NVIC_EnableIRQ(EXTI9_5_IRQ - 0x10);
            break;
        case 10:
        case 11:
        case 12:
        case 13:
        case 14:
        case 15:
            NVIC_EnableIRQ(EXTI15_10_IRQ - 0x10);
            break;
        default:
            break; /* Should never happend with 0xf mask */
    }
    return 0;
}


void soc_exti_init(void)
{
    /* set IMR register to 0 (no IT) */
    write_reg_value(EXTI_IMR, 0x0);
    /* Enable the Syscfg, needed by EXTI */
    set_reg_bits(r_CORTEX_M_RCC_APB2ENR, RCC_APB2ENR_SYSCFGEN);
}
