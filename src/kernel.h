/* \file kernel.h
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

#ifndef KERNEL_H
#define KERNEL_H

#include "types.h"
#include "m4-systick.h"

/* global kernel defines */

#define __KERNEL

#define ANSI_COLOR_BLUE    "\x1b[37;44m"
#define ANSI_COLOR_RED     "\x1b[37;41m"
#define ANSI_COLOR_RESET   "\x1b[37;40m"

#define KERNLOG(level, fmt, ...)    \
    if (level <= DBG_ERR) {         \
        DEBUG(level, ANSI_COLOR_RED "[%ld] kernel: " fmt ANSI_COLOR_RESET, (unsigned long) core_systick_get_ticks(), ##__VA_ARGS__); \
    } else {                         \
        DEBUG(level, ANSI_COLOR_BLUE "[%ld] kernel: " fmt ANSI_COLOR_RESET, (unsigned long) core_systick_get_ticks(), ##__VA_ARGS__); \
    }

/* for visibility purpose, to mark all userspace variable in kernel code */
#define __user

/* kernel specific types */
typedef physaddr_t *stackaddr_t;    /* stack @ */
typedef uint16_t reghval_t;     /* register high-half value */
typedef uint16_t reglval_t;     /* register low-half value */
typedef uint32_t regval_t;      /* register value */

#endif                          /*!KERNEL_H */
