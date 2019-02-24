/* \file arch/types.h
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
#ifndef SOC_TYPES_H
#define SOC_TYPES_H

typedef signed char int8_t;
typedef signed short int16_t;
typedef signed int int32_t;
typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int uint32_t;
typedef unsigned long long int uint64_t;
/* fully typed log buffer size */
typedef uint8_t logsize_t;

typedef enum {false = 0, true = 1} bool;
typedef enum {SUCCESS, FAILURE} retval_t;

/* Secure boolean against fault injections for critical tests */
typedef enum {secfalse = 0x55aa55aa, sectrue = 0xaa55aa55} secbool;

#define KBYTE 1024
#define MBYTE 1048576
#define GBYTE 1073741824

#define NULL				((void *)0)

/* 32bits targets specific */
typedef uint32_t physaddr_t;
typedef uint8_t svcnum_t;

#if defined(__CC_ARM)
# define __ASM            __asm  /* asm keyword for ARM Compiler    */
# define __INLINE         static __inline    /* inline keyword for ARM Compiler */
# define __ISR_HANDLER           /* [PTH] todo: find the way to deactivate localy frame pointer or use rx, x<4 for it */
# define __NAKED                 /* [PTH] todo: find the way to set the function naked (without pre/postamble) */
# define __UNUSED                /* [PTH] todo: find the way to set a function/var unused */
# define __WEAK                  /* [PTH] todo: find the way to set a function/var weak */
#elif defined(__GNUC__)
# define __ASM            __asm  /* asm keyword for GNU Compiler    */
# define __INLINE        static inline
#ifdef __clang__
  # define __ISR_HANDLER  __attribute__((interrupt("IRQ")))
#else
  # define __ISR_HANDLER   __attribute__((optimize("-fomit-frame-pointer")))
#endif
# define __NAKED         __attribute__((naked))
# define __UNUSED        __attribute__((unused))
# define __WEAK          __attribute__((weak))
# define __packed		__attribute__((__packed__))
#endif

#endif
