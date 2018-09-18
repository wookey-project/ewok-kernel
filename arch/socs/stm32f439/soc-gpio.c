/* \file soc-gpio.c
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
#include "types.h"
#include "exported/devices.h"
#include "exported/gpio.h"
#include "soc-gpio.h"

/*
** Convert a port num (0x0 = GPIOA, 0x1 = GPIOB...) into port base address
*/
static uint32_t soc_gpio_get_port_base (gpioref_t kref)
{
    uint32_t port_base;
    switch (kref.port) {
	    case GPIO_PA: port_base = GPIOA_BASE; break;
	    case GPIO_PB: port_base = GPIOB_BASE; break;
	    case GPIO_PC: port_base = GPIOC_BASE; break;
	    case GPIO_PD: port_base = GPIOD_BASE; break;
	    case GPIO_PE: port_base = GPIOE_BASE; break;
	    case GPIO_PF: port_base = GPIOF_BASE; break;
	    case GPIO_PG: port_base = GPIOG_BASE; break;
	    case GPIO_PH: port_base = GPIOH_BASE; break;
	    case GPIO_PI: port_base = GPIOI_BASE; break;
	    default:
	        port_base = 0;
	        break;
    }
    return port_base;
}

void soc_gpio_set_mode(volatile uint32_t * gpioX_moder, uint8_t pin,
                       uint8_t mode)
{
    set_reg_value(gpioX_moder, mode, 0x3 << (2 * pin), 2 * pin);
}

void soc_gpio_set_type(volatile uint32_t * gpioX_otyper, uint8_t pin,
                       uint8_t type)
{
    set_reg_value(gpioX_otyper, type, 1 << pin, pin);
}

void soc_gpio_set_speed(volatile uint32_t * gpioX_ospeedr, uint8_t pin,
                        uint8_t speed)
{
    set_reg_value(gpioX_ospeedr, speed, 0x3 << (2 * pin), 2 * pin);
}

void soc_gpio_set_pupd(volatile uint32_t * gpioX_pupdr, uint8_t pin,
                       uint8_t pupd)
{
    set_reg_value(gpioX_pupdr, pupd, 0x3 << (2 * pin), 2 * pin);
}

void soc_gpio_set_od(volatile uint32_t * gpioX_odr, uint8_t pin, uint8_t od)
{
    set_reg_value(gpioX_odr, od, 1 << pin, pin);
}

void soc_gpio_set_bsr_r(volatile uint32_t * gpioX_bsrr_r, uint8_t pin,
                        uint8_t reset)
{
    set_reg_value(gpioX_bsrr_r, reset, 1 << pin, pin);
}

void soc_gpio_set_bsr_s(volatile uint32_t * gpioX_bsrr_r, uint8_t pin,
                        uint8_t set)
{
    set_reg_value(gpioX_bsrr_r, set, 1 << pin, pin);
}

void soc_gpio_set_lck(volatile uint32_t * gpioX_lckr, uint8_t pin,
                      uint8_t value)
{
    set_reg_value(gpioX_lckr, value, 1 << pin, pin);
}

void soc_gpio_set_afr(volatile uint32_t * gpioX_afr, uint8_t pin,
                      uint8_t function)
{
    if (pin > 7)
        set_reg_value(gpioX_afr + 1, function, 0xf << (4 * (pin - 8)),
                      4 * (pin - 8));
    else
        set_reg_value(gpioX_afr, function, 0xf << (4 * pin), 4 * pin);
}

#define GPIO_CONFIG(port) \
		set_reg_bits(r_CORTEX_M_RCC_AHB1ENR, RCC_AHB1ENR_GPIO##port##EN);\
		gpioX_moder = GPIO_MODER(GPIO##port##_BASE);\
		gpioX_otyper = GPIO_OTYPER(GPIO##port##_BASE);\
		gpioX_ospeedr = GPIO_OSPEEDR(GPIO##port##_BASE);\
		gpioX_pupdr = GPIO_PUPDR(GPIO##port##_BASE);\
		gpioX_idr = GPIO_IDR(GPIO##port##_BASE); \
		gpioX_odr = GPIO_ODR(GPIO##port##_BASE);\
		gpioX_bsrr_r = GPIO_BSRR_R(GPIO##port##_BASE);\
		gpioX_bsrr_s = GPIO_BSRR_S(GPIO##port##_BASE);\
		gpioX_lckr = GPIO_LCKR(GPIO##port##_BASE);\
		gpioX_afr_l = GPIO_AFR_L(GPIO##port##_BASE);\
		gpioX_afr_h = GPIO_AFR_H(GPIO##port##_BASE)

uint8_t soc_gpio_set_config(const dev_gpio_info_t * gpio)
{
    volatile uint32_t  *gpioX_moder,   *gpioX_otyper,  *gpioX_ospeedr,
                       *gpioX_pupdr,   *gpioX_idr,     *gpioX_odr,
                       *gpioX_bsrr_r,  *gpioX_bsrr_s,  *gpioX_lckr,
                       *gpioX_afr_l, *gpioX_afr_h;

    physaddr_t portaddr = soc_gpio_get_port_base(gpio->kref);

    /* Does the port exist? */
    if (portaddr == 0) {
        return 1;
    }

    switch (portaddr) {
        case GPIOA_BASE: GPIO_CONFIG(A); break;
        case GPIOB_BASE: GPIO_CONFIG(B); break;
        case GPIOC_BASE: GPIO_CONFIG(C); break;
        case GPIOD_BASE: GPIO_CONFIG(D); break;
        case GPIOE_BASE: GPIO_CONFIG(E); break;
        case GPIOF_BASE: GPIO_CONFIG(F); break;
        case GPIOG_BASE: GPIO_CONFIG(G); break;
        case GPIOH_BASE: GPIO_CONFIG(H); break;
        case GPIOI_BASE: GPIO_CONFIG(I); break;
        default:
            return 1;
    }

    /* Set the appropriate values according to the mask */
    if (gpio->mask & GPIO_MASK_SET_MODE) {
        soc_gpio_set_mode(gpioX_moder, gpio->kref.pin, gpio->mode);
    }
    if (gpio->mask & GPIO_MASK_SET_TYPE) {
        soc_gpio_set_type(gpioX_otyper, gpio->kref.pin, gpio->type);
    }
    if (gpio->mask & GPIO_MASK_SET_SPEED) {
        soc_gpio_set_speed(gpioX_ospeedr, gpio->kref.pin, gpio->speed);
    }
    if (gpio->mask & GPIO_MASK_SET_PUPD) {
        soc_gpio_set_pupd(gpioX_pupdr, gpio->kref.pin, gpio->pupd);
    }
    if (gpio->mask & GPIO_MASK_SET_BSR_R) {
        soc_gpio_set_bsr_r(gpioX_bsrr_r, gpio->kref.pin, gpio->bsr_r);
    }
    if (gpio->mask & GPIO_MASK_SET_BSR_S) {
        soc_gpio_set_bsr_s(gpioX_bsrr_r, gpio->kref.pin, gpio->bsr_s);
    }
    if (gpio->mask & GPIO_MASK_SET_LCK) {
        soc_gpio_set_lck(gpioX_lckr, gpio->kref.pin, gpio->lck);
    }
    if (gpio->mask & GPIO_MASK_SET_AFR) {
        soc_gpio_set_afr(gpioX_afr_l, gpio->kref.pin, gpio->afr);
    }

    return 0;
}

uint8_t soc_gpio_configure
    (uint8_t port, uint8_t pin, gpio_mode_t mode, gpio_type_t type,
     gpio_speed_t speed, gpio_pupd_t pupd, gpio_af_t afr)
{
    volatile uint32_t  *gpioX_moder,   *gpioX_otyper,  *gpioX_ospeedr,
                       *gpioX_pupdr,   *gpioX_idr,     *gpioX_odr,
                       *gpioX_bsrr_r,  *gpioX_bsrr_s,  *gpioX_lckr,
                       *gpioX_afr_l, *gpioX_afr_h;

    switch (port) {
        case GPIO_PA: GPIO_CONFIG(A); break;
        case GPIO_PB: GPIO_CONFIG(B); break;
        case GPIO_PC: GPIO_CONFIG(C); break;
        case GPIO_PD: GPIO_CONFIG(D); break;
        case GPIO_PE: GPIO_CONFIG(E); break;
        case GPIO_PF: GPIO_CONFIG(F); break;
        case GPIO_PG: GPIO_CONFIG(G); break;
        case GPIO_PH: GPIO_CONFIG(H); break;
        case GPIO_PI: GPIO_CONFIG(I); break;
        default:
            return 1;
    }

    soc_gpio_set_mode(gpioX_moder, pin, mode);
    soc_gpio_set_type(gpioX_otyper, pin, type);
    soc_gpio_set_speed(gpioX_ospeedr, pin, speed);
    soc_gpio_set_pupd(gpioX_pupdr, pin, pupd);
    soc_gpio_set_afr(gpioX_afr_l, pin, afr);

    return 0;
}

void soc_gpio_set_value(gpioref_t kref, uint8_t value)
{
    physaddr_t portaddr = soc_gpio_get_port_base(kref);
    soc_gpio_set_od(GPIO_ODR(portaddr), kref.pin, !!value);
}

void soc_gpio_set(gpioref_t kref)
{
    soc_gpio_set_value(kref, 1);
}

void soc_gpio_clear(gpioref_t kref)
{
    soc_gpio_set_value(kref, 0);
}

uint8_t soc_gpio_get(gpioref_t kref)
{
    physaddr_t portaddr = soc_gpio_get_port_base(kref);
    return !!get_reg_value(GPIO_IDR(portaddr), 1 << (kref.pin), kref.pin);
}
