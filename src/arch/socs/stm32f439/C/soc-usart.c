/* \file soc-usart.c
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
#include "autoconf.h"
#include "debug.h"
#include "soc-gpio.h"
#include "C/exported/devices.h"
#include "soc-exti.h"
#include "soc-nvic.h"
#include "soc-rcc.h"
#include "soc-interrupts.h"
#include "soc-usart.h"
#include "soc-usart-regs.h"
#include "C/gpio.h"

/**** USART basic Read / Write ****/
void soc_usart_putc(uint8_t usart, char c)
{
    /* Wait for TX to be ready */
    while (!get_reg(r_CORTEX_M_USART_SR(usart), USART_SR_TXE))
        continue;
    *r_CORTEX_M_USART_DR(usart) = c;
}

/* Instantiate the putc for each USART */
#define USART_PUTC_CALLBACK(num)\
void soc_usart##num##_putc(char c)\
{\
	soc_usart_putc(num, c);\
}\

USART_PUTC_CALLBACK(1)
USART_PUTC_CALLBACK(2)
USART_PUTC_CALLBACK(3)
USART_PUTC_CALLBACK(4)
USART_PUTC_CALLBACK(5)
USART_PUTC_CALLBACK(6)

void soc_usart_write(uint8_t usart, char *msg, uint32_t len)
{
    while (len--) {
        soc_usart_putc(usart, *msg);
        msg++;
    }
}

char soc_usart_getc(uint8_t usart)
{
    while (!get_reg(r_CORTEX_M_USART_SR(usart), USART_SR_RXNE))
        continue;
    return *r_CORTEX_M_USART_DR(usart);
}

/* Instantiate the getc for each USART */
#define USART_GETC_CALLBACK(num)\
char soc_usart##num##_getc(void)\
{\
	return soc_usart_getc(num);\
}\

USART_GETC_CALLBACK(1)
    USART_GETC_CALLBACK(2)
    USART_GETC_CALLBACK(3)
    USART_GETC_CALLBACK(4)
    USART_GETC_CALLBACK(5)
    USART_GETC_CALLBACK(6)

uint32_t soc_usart_read(uint8_t usart, char *buf, uint32_t len)
{
    uint32_t start_len = len;
    while (len--) {
        *buf = soc_usart_getc(usart);
        if (*buf == '\n')
            break;
        buf++;
    }
    return start_len - len;
}

void soc_usart_set_baudrate(usart_config_t * config)
{
    uint32_t divider = 0;
    uint16_t mantissa = 0;
    uint8_t fraction = 0;

    /* FIXME we should check CR1 in order to get the OVER8 configuration */

    /* Compute the divider using the baudrate and the APB bus clock
     * (APB1 or APB2) depending on the considered USART */
    divider = soc_usart_get_bus_clock(config) / config->baudrate;

    mantissa = (uint16_t) divider / 16;
    fraction = (uint8_t) ((divider - mantissa * 16));
    write_reg_value(r_CORTEX_M_USART_BRR(config->usart),
                    (((mantissa & 0x0fff) << 4) | (0x0f & fraction)));
}

/* USART mapping for UART mode (TX, RX), and their configuration */
#define UART_GPIO_COMMON(po, pi, x) \
	{\
	 .kref.port = po,\
	 .kref.pin = pi,\
	 .mask = GPIO_MASK_SET_MODE | GPIO_MASK_SET_PUPD | GPIO_MASK_SET_SPEED | GPIO_MASK_SET_TYPE | GPIO_MASK_SET_AFR,\
	 .mode = GPIO_PIN_ALTERNATE_MODE,\
	 .pupd = GPIO_NOPULL,\
	 .speed = GPIO_PIN_VERY_HIGH_SPEED,\
	 .type = GPIO_PIN_OTYPER_PP,\
	 .afr = x,\
	}\


dev_gpio_info_t uart_gpio_config[] = {
    /***************************************/
    /* USART1 */
    /* TX is PB6 with alternate function AF7 */
    UART_GPIO_COMMON(GPIO_PB, 6, GPIO_AF_USART1),
    /* RX is PB7 with alternate function AF7 */
    UART_GPIO_COMMON(GPIO_PB, 7, GPIO_AF_USART1),
    /***************************************/
    /* USART2 */
    /* TX is PA2 with alternate function AF7 */
    UART_GPIO_COMMON(GPIO_PA, 2, GPIO_AF_USART2),
    /* RX is PA3 with alternate function AF7 */
    UART_GPIO_COMMON(GPIO_PA, 3, GPIO_AF_USART2),
    /***************************************/
    /* USART3 */
    /* TX is PB10 with alternate function AF7 */
    UART_GPIO_COMMON(GPIO_PB, 10, GPIO_AF_USART3),
    /* RX is PB11 with alternate function AF7 */
    UART_GPIO_COMMON(GPIO_PB, 11, GPIO_AF_USART3),
    /***************************************/
    /* USART4 */
#ifdef CONFIG_WOOKEY
    UART_GPIO_COMMON(GPIO_PA, 0, GPIO_AF_USART4),
    UART_GPIO_COMMON(GPIO_PA, 1, GPIO_AF_USART4),
#elif CONFIG_DISCO407
    /* TX is PC10 with alternate function AF8 */
    UART_GPIO_COMMON(GPIO_PC, 10, GPIO_AF_USART4),
    /* RX is PC11 with alternate function AF8 */
    UART_GPIO_COMMON(GPIO_PC, 11, GPIO_AF_USART4),
#elif CONFIG_DISCO429
    /* TX is PC10 with alternate function AF8 */
    UART_GPIO_COMMON(GPIO_PC, 10, GPIO_AF_USART4),
    /* RX is PC11 with alternate function AF8 */
    UART_GPIO_COMMON(GPIO_PC, 11, GPIO_AF_USART4),
#else
# error "STM32F4xx-based board not supported, check GPIO config"
#endif
    /***************************************/
    /* USART5 */
    /* TX is PC12 with alternate function AF8 */
    UART_GPIO_COMMON(GPIO_PC, 12, GPIO_AF_USART5),
    /* RX is PD2 with alternate function AF8 */
    UART_GPIO_COMMON(GPIO_PD, 2, GPIO_AF_USART5),
    /***************************************/
    /* USART6 */
    /* TX is PC6 with alternate function AF8 */
    UART_GPIO_COMMON(GPIO_PC, 6, GPIO_AF_USART6),
    /* RX is PC7 with alternate function AF8 */
    UART_GPIO_COMMON(GPIO_PC, 7, GPIO_AF_USART6),
};

/* This is a template configuration for the USART in UART mode */

/* FIXME should be rewritten in order to handle all uart configurations
 * [RB]: first attempt to implement this ...
 */
static void soc_usart_init_gpio(usart_config_t * config)
{
    dev_gpio_info_t *tx_config;
    dev_gpio_info_t *rx_config;

    /* Sanity check */
    if ((config->usart < 1) || (config->usart > 6)) {
        panic("Wrong usart %d. You should use USART1 to USART6", config->usart);
    }

    switch (config->mode) {
    case UART:
        tx_config = &uart_gpio_config[2 * (config->usart - 1)];
        rx_config = &uart_gpio_config[(2 * (config->usart - 1)) + 1];

        if (tx_config->kref.port == 0 && rx_config->kref.port == 0) {
            panic
                ("UART usart %d does not seem to support UART or to be rooted on the board!",
                 config->usart);
        }

        soc_gpio_configure
           (tx_config->kref.port,
            tx_config->kref.pin,
            tx_config->mode,
            tx_config->type,
            tx_config->speed,
            tx_config->pupd,
            tx_config->afr);

        soc_gpio_configure
           (rx_config->kref.port,
            rx_config->kref.pin,
            rx_config->mode,
            rx_config->type,
            rx_config->speed,
            rx_config->pupd,
            rx_config->afr);

        /* Configure the */
        break;
    default:
        panic("Wrong usart mode %d.", config->mode);
    }
}

static void soc_usart_clock_init(usart_config_t * config)
{
    switch (config->usart) {
    case 1:
        set_reg_bits(r_CORTEX_M_RCC_APB2ENR, RCC_APB2ENR_USART1EN);
        break;
    case 2:
        set_reg_bits(r_CORTEX_M_RCC_APB1ENR, RCC_APB1ENR_USART2EN);
        break;
    case 3:
        set_reg_bits(r_CORTEX_M_RCC_APB1ENR, RCC_APB1ENR_USART3EN);
        break;
    case 4:
        set_reg_bits(r_CORTEX_M_RCC_APB1ENR, RCC_APB1ENR_UART4EN);
        break;
    case 5:
        set_reg_bits(r_CORTEX_M_RCC_APB1ENR, RCC_APB1ENR_UART5EN);
        break;
    case 6:
        set_reg_bits(r_CORTEX_M_RCC_APB2ENR, RCC_APB2ENR_USART6EN);
        break;
    default:
        panic("Wrong usart %d. You should use USART1 to USART6", config->usart);
    }

    return;
}

/**** IRQ Handlers ****/

#define USART_IRQHANDLER(num, type) \
/* Global variable holding the callback to USART num */\
cb_usart_data_received_t cb_usart##num##_data_received = NULL;\
/* Register the IRQ */\
void U##type##ART##num##_IRQ_Handler(stack_frame_t *sf __attribute__((unused)))\
{\
	if(cb_usart##num##_data_received != NULL){\
		cb_usart##num##_data_received();\
	}\
}

/* Instantiate the IRQs for the 6 USARTs
 * The weird second macro argument handles the fact that USART 4 and 5 are in
 * UARTs.
 */
USART_IRQHANDLER(1, S)
    USART_IRQHANDLER(2, S)
    USART_IRQHANDLER(3, S)
    USART_IRQHANDLER(4,)
    USART_IRQHANDLER(5,)
    USART_IRQHANDLER(6, S)

/* Configure the handlers */
#define USART_CONFIG_CALLBACKS(num, type) \
	case num:\
		if (config->callback_data_received != NULL){\
			NVIC_EnableIRQ(U##type##ART##num##_IRQ - 0x10);\
			/* Enable dedicated IRQ and register the callback */\
			cb_usart##num##_data_received = config->callback_data_received;\
		}\
		if(config->callback_usart_getc_ptr != NULL){\
			*(config->callback_usart_getc_ptr) = soc_usart##num##_getc;\
		}\
		if(config->callback_usart_putc_ptr != NULL){\
			*(config->callback_usart_putc_ptr) = soc_usart##num##_putc;\
		}\
		break;\

static void soc_usart_callbacks_init(usart_config_t * config)
{
    if (config->callback_data_received) {
        /* A reception callback has been provided: enable interrupts
         * for RX using the control register
         */
        set_reg_bits(r_CORTEX_M_USART_CR1(config->usart), USART_CR1_RXNEIE_Msk);
    }
    switch (config->usart) {
        USART_CONFIG_CALLBACKS(1, S)
        USART_CONFIG_CALLBACKS(2, S)
        USART_CONFIG_CALLBACKS(3, S)
        USART_CONFIG_CALLBACKS(4,)
        USART_CONFIG_CALLBACKS(5,)
        USART_CONFIG_CALLBACKS(6, S)
    default:
        panic("Wrong usart %d. You should use USART1 to USART6", config->usart);
    }

    return;
}

/**** usart_init ****/
void soc_usart_init(usart_config_t * config)
{

    soc_usart_clock_init(config);
    soc_usart_init_gpio(config);
    soc_usart_set_baudrate(config);

    /* registering the handler */
    /*
    switch (config->usart) {
      case 0:
      case 1:
        irq_handler_set(USART1_IRQ, USART1_IRQ_Handler, 0, ID_DEV_UNUSED);
        break;
      case 2:
        irq_handler_set(USART2_IRQ, USART2_IRQ_Handler, 0, ID_DEV_UNUSED);
        break;
      case 3:
        irq_handler_set(USART3_IRQ, USART3_IRQ_Handler, 0, ID_DEV_UNUSED);
        break;
      case 4:
        irq_handler_set(UART4_IRQ, UART4_IRQ_Handler, 0, ID_DEV_UNUSED);
        break;
      case 5:
        irq_handler_set(UART5_IRQ, UART5_IRQ_Handler, 0, ID_DEV_UNUSED);
        break;
      case 6:
        irq_handler_set(USART6_IRQ, USART6_IRQ_Handler, 0, ID_DEV_UNUSED);
        break;
      default:
        irq_handler_set(USART1_IRQ, USART1_IRQ_Handler, 0, ID_DEV_UNUSED);
    }
    */

    /* Control register 1 */
    set_reg(r_CORTEX_M_USART_CR1(config->usart), config->parity,
            USART_CONFIG_PARITY);
    set_reg(r_CORTEX_M_USART_CR1(config->usart), config->options_cr1,
            USART_CONFIG_OPTIONS_CR1);

    /* Control register 2 */
    set_reg(r_CORTEX_M_USART_CR2(config->usart), config->stop_bits,
            USART_CONFIG_STOP_BITS);
    set_reg(r_CORTEX_M_USART_CR1(config->usart), config->options_cr2,
            USART_CONFIG_OPTIONS_CR2);

    /* USART 4 and 5 have some configuration limitations: check them before continuing */
    if ((config->hw_flow_control & (USART_CR3_CTSIE_Msk | USART_CR3_CTSE_Msk |
                                    USART_CR3_RTSE_Msk | USART_CR3_SCEN_Msk |
                                    USART_CR3_NACK_Msk))
        && ((config->usart == 4) || (config->usart == 5))) {
        panic
            ("Usart%d config error: asking for a flag in CR3 unavailable for USART4 and USART5",
             config->usart);
    }
    if ((config->hw_flow_control & (USART_CR3_DMAT_Msk | USART_CR3_DMAR_Msk))
        && (config->usart == 5)) {
        panic
            ("Usart%d config error: asking for a flag in CR3 unavailable for USART5",
             config->usart);
    }
    if ((config->guard_time_prescaler)
        && ((config->usart == 4) || (config->usart == 5))) {
        panic
            ("Usart%d config error: asking for guard time/prescaler in GTPR unavailable for USART4 and USART5",
             config->usart);
    }
    /* Control register 3 */
    set_reg(r_CORTEX_M_USART_CR3(config->usart), config->hw_flow_control,
            USART_CONFIG_HW_FLW_CTRL);

    /* Initialize callbacks */
    soc_usart_callbacks_init(config);

    return;
}

/* Get the current clock value of the USART bus */
uint32_t soc_usart_get_bus_clock(usart_config_t * config)
{
    switch (config->usart) {
    case 1:
    case 6:
        return PROD_CLOCK_APB2;
        break;
    case 2:
    case 3:
    case 4:
    case 5:
        return PROD_CLOCK_APB1;
        break;
    default:
        panic("Wrong usart %d. You should use USART1 to USART6", config->usart);
    }

    return 0;
}
