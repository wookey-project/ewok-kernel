/* \file usb_device.h
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

/** @file usb_device.h
 * \brief Contains usb descriptors
 */
#ifndef _USB_DEVICE_H
#define _USB_DEVICE_H

#include "autoconf.h"

/* Strings */
#define MAX_DESC_STRING_SIZE		32
#define LANGUAGE_ENGLISH		0x0409

#define STRING_MANUFACTURER		CONFIG_USB_DEV_MANUFACTURER
#define STRING_MANUFACTURER_INDEX	1
#define STRING_PRODUCT			CONFIG_USB_DEV_PRODNAME
#define STRING_PRODUCT_INDEX		2
#define STRING_SERIAL			"123456789012345678901234"
#define STRING_SERIAL_INDEX		3

#define ID_VENDOR           CONFIG_USB_DEV_VENDORID
#define ID_PRODUCT          CONFIG_USB_DEV_PRODUCTID

#endif
