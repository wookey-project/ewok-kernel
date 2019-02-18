/* \file leds.h
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
#ifndef LEDS_H_
# define LEDS_H_


# define LED3_PIN	13
# define LED4_PIN	12
# define LED5_PIN	14
# define LED6_PIN	15


#define PROD_LED_STATUS LED3_PIN
#define PROD_LED_ACTIVITY LED4_PIN


enum led {LED3 = LED3_PIN, LED4 = LED4_PIN, LED5 = LED5_PIN, LED6 = LED6_PIN};

#endif /* !LEDS_H_ */
