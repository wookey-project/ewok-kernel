/* \file products.h
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
#ifndef PRODUCT_H
# define PRODUCT_H
#include "soc-rcc.h"

#define VECT_TAB_OFFSET  0x00 /*!< Vector Table base offset field.
                                  This value must be a multiple of 0x200. */

//#define PROD_ENABLE_HSE

#define PROD_ENABLE_PLL 1


#define PROD_PLL_M     16
#define PROD_PLL_N     336
#define PROD_PLL_P     2
#define PROD_PLL_Q     7

#define PROD_HCLK      RCC_CFGR_HPRE_DIV1
#define PROD_PCLK2     RCC_CFGR_HPRE2_DIV2
#define PROD_PCLK1     RCC_CFGR_HPRE1_DIV4

#define PROD_CLOCK_SYS //FIXME

#define PROD_CLOCK_APB1  42000000 // MHz
#define PROD_CLOCK_APB2  84000000 // MHz
#define PROD_CONSOLE_USART 1

#define PROD_CORE_FREQUENCY 168000

#define PROD_MAX_USB_ENDPOINTS 3 /* uint8_t */


#endif /* PRODUCT_H */
