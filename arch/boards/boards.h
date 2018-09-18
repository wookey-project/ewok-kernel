/* \file boards.h
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
#ifndef _BOARDS_H
#define _BOARDS_H
    #if defined(CONFIG_WOOKEY)
        #include "wookey/wookey.h"
    #elif defined(CONFIG_DISCO407)
        #include "32f407discovery/disco.h"
    #elif defined(CONFIG_DISCO429)
        #include "32f439discovery/disco.h"
    #else
        #error "You must define a board type"
    #endif
#endif /* _BOARDS_H */
