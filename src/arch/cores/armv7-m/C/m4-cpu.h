/* \file m4-cpu.h
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
#ifndef M4_CPU
#define M4_CPU

#include "types.h"

__INLINE __attribute__ ((always_inline))
void core_write_psp(void *ptr)
{
    asm volatile ("MSR psp, %0\n\t"::"r" (ptr));
}

__INLINE __attribute__ ((always_inline))
void core_write_msp(void *ptr)
{
    asm volatile ("MSR msp, %0\n\t"::"r" (ptr));
}

__INLINE __attribute__ ((always_inline))
void *core_read_psp(void)
{
    void *result = NULL;
    asm volatile ("MRS %0, psp\n\t":"=r" (result));
    return (result);
}

__INLINE __attribute__ ((always_inline))
void *core_read_msp(void)
{
    void *result = NULL;
    asm volatile ("MRS %0, msp\n\t":"=r" (result));
    return (result);
}

__INLINE __attribute__ ((always_inline))
void enable_irq(void)
{
    __ASM volatile ("cpsie i; isb":::"memory");
}

__INLINE __attribute__ ((always_inline))
void disable_irq(void)
{
    __ASM volatile ("cpsid i":::"memory");

}

__INLINE __attribute__ ((always_inline))
void full_memory_barrier(void)
{
    __ASM volatile ("dsb; isb":::);
}

__INLINE __attribute__ ((always_inline))
uint32_t __get_CONTROL(void)
{
    uint32_t result;

    __ASM volatile ("MRS %0, control":"=r" (result));
    return (result);
}

__INLINE __attribute__ ((always_inline))
void __set_CONTROL(uint32_t control)
{
    __ASM volatile ("MSR control, %0"::"r" (control));
}

__INLINE __attribute__ ((always_inline))
uint32_t __get_IPSR(void)
{
    uint32_t result;

    __ASM volatile ("MRS %0, ipsr":"=r" (result));
    return (result);
}

__INLINE __attribute__ ((always_inline))
uint32_t __get_APSR(void)
{
    uint32_t result;

    __ASM volatile ("MRS %0, apsr":"=r" (result));
    return (result);
}

__INLINE __attribute__ ((always_inline))
uint32_t __get_xPSR(void)
{
    uint32_t result;

    __ASM volatile ("MRS %0, xpsr":"=r" (result));
    return (result);
}

__INLINE __attribute__ ((always_inline))
uint32_t __get_PRIMASK(void)
{
    uint32_t result;

    __ASM volatile ("MRS %0, primask":"=r" (result));
    return (result);
}

__INLINE __attribute__ ((always_inline))
void __set_PRIMASK(uint32_t priMask)
{
    __ASM volatile ("MSR primask, %0"::"r" (priMask));
}

__INLINE void wait_for_interrupt(void)
{
    asm volatile ("wfi");
}

#if defined(__CC_ARM)
/* No Operation */
#define __NOP		__nop
/* Instruction Synchronization Barrier */
#define __ISB()	__isb(0xF)
/* Data Synchronization Barrier */
#define __DSB()	__dsb(0xF)
/* Data Memory Barrier */
#define __DMB()	__dmb(0xF)
/* Reverse byte order (32 bit) */
#define __REV		__rev
/* Reverse byte order (16 bit) */
static __INLINE __ASM uint32_t __REV16(uint32_t value)
{
rev16 r0, r0 bx lr}
/* Breakpoint */
#define __BKPT	__bkpt
#elif defined(__GNUC__)

static inline __attribute__ ((always_inline))
void __NOP(void)
{
    __asm__ volatile ("nop");
}

static inline __attribute__ ((always_inline))
void __ISB(void)
{
    __asm__ volatile ("isb");
}

static inline __attribute__ ((always_inline))
void __DSB(void)
{
    __asm__ volatile ("dsb");
}

static inline __attribute__ ((always_inline))
void __DMB(void)
{
    __asm__ volatile ("dmb");
}

static inline __attribute__ ((always_inline))
uint32_t __REV(uint32_t value)
{
    uint32_t result;
    __asm__ volatile ("rev %0, %1":"=r" (result):"r"(value));
    return result;
}

static inline __attribute__ ((always_inline))
uint32_t __REV16(uint32_t value)
{
    uint32_t result;
    __asm__ volatile ("rev16 %0, %1":"=r" (result):"r"(value));
    return result;
}

static inline __attribute__ ((always_inline))
void __BKPT(void)
{
    __asm__ volatile ("bkpt");
}
#endif

#endif                          /*!M4_CPU */
