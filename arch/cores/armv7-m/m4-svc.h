/* \file m4-svc.h
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

#ifndef _M4_SVC_H
#define _M4_SVC_H

#include "cortex_m_functions.h"
 
#define SVC_UNPRIVILEGED    0x00
#define SVC_PRIVILEGED      0x01

#define SVC_MAIN            0x00   /* Main stack */
#define SVC_PROCESS         0x02   /* Process stack */
 
#define SVC_SYSCALL         0x42   /* syscall */
 
/* Set Process Stack Pointer value */
#define __SVC_SetPSP(psp)           __set_PSP((uint32_t)(psp))
 
/* Select Process Stack as Thread mode Stack */
#define __SVC_SetCONTROL(control)   __set_CONTROL(control)
 
#if defined ( __CC_ARM )
void __svc(1) __SVC(uint8_t svc_number);

#elif defined ( __GNUC__ )
#define __SVC(code) asm volatile ("SVC %[immediate]"::[immediate] "I" (code))
extern void __SVC_1(uint8_t svc_number);

#endif  /* __CC_ARM */
 
#endif  /* _M4_SVC_H */
