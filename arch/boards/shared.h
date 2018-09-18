/* \file shared.h
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
#ifndef _SHARED_H
#define _SHARED_H

#include "autoconf.h"

#define MAX_APP_INDEX 3
#define APP_INDEX_FW1 0
#define APP_INDEX_DFU 1
#define APP_INDEX_FW2 2


#define BOOT_OK  0x0000FFFF
#define BOOT_KO  0xFFFF0000
#define BOOT_CK  0x00FF00FF


typedef int (* app_entry_t)(void);

typedef struct __packed {
        app_entry_t entry_point;
        uint32_t version;
        uint32_t boot_status;
        // const char sig[];
} app_t;


typedef struct __packed {
        uint32_t default_app_index;
        app_t apps[MAX_APP_INDEX];
        const char kernel_msg[24][82];
        uint32_t siglen;
        char sig[];
} shr_vars_t;

#endif
