/* \file soc-nvic.h
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
#ifndef SOC_NVIC_H
#define SOC_NVIC_H

#include "m4-cpu.h"
#include "soc-core.h"
#include "soc-exti.h"
#include "soc-scb.h"

/*
 * NVIC register block is 0xE000E100. The NVIC_STIR register is located in a separate block at 0xE000EF00.
 *
 * The NVIC supports:
 * • Up to 81 interrupts (interrupt number depends on the STM32 device type;
 *   refer to the datasheets)
 *
 * • A programmable priority level of 0-15 for each interrupt.
 *   A higher level corresponds to a lower priority, so level 0 is the highest interrupt priority
 *
 * • Level and pulse detection of interrupt signals
 *
 * • Dynamic reprioritization of interrupts
 *
 * • Grouping of priority values into group priority and subpriority fields
 *
 * • Interrupt tail-chaining
 *
 * • An external Non-maskable interrupt (NMI)
 *
 * The processor automatically stacks its state on exception entry and unstacks this state on
 * exception exit, with no instruction overhead.
 */

/* 0xE000E100-0xE000E10B NVIC_ISER0-NVIC_ISER2 (RW Privileged) Interrupt set-enable registers */
#define r_CORTEX_M_NVIC_ISER0   REG_ADDR(NVIC_BASE + (uint32_t)0x00)
#define r_CORTEX_M_NVIC_ISER1   REG_ADDR(NVIC_BASE + (uint32_t)0x04)
#define r_CORTEX_M_NVIC_ISER2   REG_ADDR(NVIC_BASE + (uint32_t)0x08)
/* 0XE000E180-0xE000E18B NVIC_ICER0-NVIC_ICER2 (RW Privileged) Interrupt clear-enable registers */
#define r_CORTEX_M_NVIC_ICER0   REG_ADDR(NVIC_BASE + (uint32_t)0x80)
#define r_CORTEX_M_NVIC_ICER1   REG_ADDR(NVIC_BASE + (uint32_t)0x84)
#define r_CORTEX_M_NVIC_ICER2   REG_ADDR(NVIC_BASE + (uint32_t)0x88)
/* 0XE000E200-0xE000E20B NVIC_ISPR0-NVIC_ISPR2 (RW Privileged) Interrupt set-pending registers */
#define r_CORTEX_M_NVIC_ISPR0   REG_ADDR(NVIC_BASE + (uint32_t)0x100)
#define r_CORTEX_M_NVIC_ISPR1   REG_ADDR(NVIC_BASE + (uint32_t)0x104)
#define r_CORTEX_M_NVIC_ISPR2   REG_ADDR(NVIC_BASE + (uint32_t)0x108)
/* 0XE000E280-0xE000E29C NVIC_ICPR0-NVIC_ICPR2 (RW Privileged) Interrupt clear-pending registers */
#define r_CORTEX_M_NVIC_ICPR0   REG_ADDR(NVIC_BASE + (uint32_t)0x180)
#define r_CORTEX_M_NVIC_ICPR1   REG_ADDR(NVIC_BASE + (uint32_t)0x184)
#define r_CORTEX_M_NVIC_ICPR2   REG_ADDR(NVIC_BASE + (uint32_t)0x188)
/* 0xE000E300-0xE000E31C NVIC_IABR0-NVIC_IABR2 (RW Privileged) Interrupt active bit registers */
#define r_CORTEX_M_NVIC_IABR0   REG_ADDR(NVIC_BASE + (uint32_t)0x200)
#define r_CORTEX_M_NVIC_IABR1   REG_ADDR(NVIC_BASE + (uint32_t)0x204)
#define r_CORTEX_M_NVIC_IABR2   REG_ADDR(NVIC_BASE + (uint32_t)0x208)
/* 0xE000E400-0xE000E503 NVIC_IPR0-NVIC_IPR20  (RW Privileged)Interrupt priority registers */
#define r_CORTEX_M_NVIC_IPR0    REG_ADDR(NVIC_BASE + (uint32_t)0x300)
#define r_CORTEX_M_NVIC_IPR1    REG_ADDR(NVIC_BASE + (uint32_t)0x301)
#define r_CORTEX_M_NVIC_IPR2    REG_ADDR(NVIC_BASE + (uint32_t)0x302)
#define r_CORTEX_M_NVIC_IPR3    REG_ADDR(NVIC_BASE + (uint32_t)0x303)
#define r_CORTEX_M_NVIC_IPR4    REG_ADDR(NVIC_BASE + (uint32_t)0x304)
#define r_CORTEX_M_NVIC_IPR5    REG_ADDR(NVIC_BASE + (uint32_t)0x305)
#define r_CORTEX_M_NVIC_IPR6    REG_ADDR(NVIC_BASE + (uint32_t)0x306)
#define r_CORTEX_M_NVIC_IPR7    REG_ADDR(NVIC_BASE + (uint32_t)0x307)
#define r_CORTEX_M_NVIC_IPR8    REG_ADDR(NVIC_BASE + (uint32_t)0x308)
#define r_CORTEX_M_NVIC_IPR9    REG_ADDR(NVIC_BASE + (uint32_t)0x309)
#define r_CORTEX_M_NVIC_IPR10   REG_ADDR(NVIC_BASE + (uint32_t)0x310)
#define r_CORTEX_M_NVIC_IPR11   REG_ADDR(NVIC_BASE + (uint32_t)0x311)
#define r_CORTEX_M_NVIC_IPR12   REG_ADDR(NVIC_BASE + (uint32_t)0x312)
#define r_CORTEX_M_NVIC_IPR13   REG_ADDR(NVIC_BASE + (uint32_t)0x313)
#define r_CORTEX_M_NVIC_IPR14   REG_ADDR(NVIC_BASE + (uint32_t)0x314)
#define r_CORTEX_M_NVIC_IPR15   REG_ADDR(NVIC_BASE + (uint32_t)0x315)
#define r_CORTEX_M_NVIC_IPR16   REG_ADDR(NVIC_BASE + (uint32_t)0x316)
#define r_CORTEX_M_NVIC_IPR17   REG_ADDR(NVIC_BASE + (uint32_t)0x317)
#define r_CORTEX_M_NVIC_IPR18   REG_ADDR(NVIC_BASE + (uint32_t)0x318)
#define r_CORTEX_M_NVIC_IPR19   REG_ADDR(NVIC_BASE + (uint32_t)0x310)
#define r_CORTEX_M_NVIC_IPR20   REG_ADDR(NVIC_BASE + (uint32_t)0x320)
#define r_CORTEX_M_NIVIC_STIR   REG_ADDR(NVIC_STIR_BASE)    /* 0xE000EF00 (WO Configurable) Software trigger interrupt register */

/* Interrupt set-enable registers (NVIC_ISERx) */
#define NVIC_ISER_SETENA  REG_ADDR(r_CORTEX_M_NVIC_ISER0)

/* Interrupt clear-enable registers (NVIC_ICERx) */
#define NVIC_ICER  REG_ADDR(r_CORTEX_M_NVIC_ICER0)

/* Interrupt set-pending registers (NVIC_ISPRx) */
#define NVIC_ISPR  REG_ADDR(r_CORTEX_M_NVIC_ISPR0)

/* Interrupt clear-pending registers (NVIC_ICPRx) */
#define NVIC_ICPR  REG_ADDR(r_CORTEX_M_NVIC_ICPR0)

/* Interrupt active bit registers (NVIC_IABRx) */
#define NVIC_IABR  REG_ADDR(r_CORTEX_M_NVIC_IABR0)

/* Interrupt priority registers (NVIC_IPRx) */
#define NVIC_IPR   REG_ADDR(r_CORTEX_M_NVIC_IPR0)

/* Software trigger interrupt register (NVIC_STIR) */
#define NVIC_STIR  REG_ADDR(r_CORTEX_M_NIVIC_STIR)

/* Interrupt set-enable registers */
#define NVIC_ISER   REG_ADDR(r_CORTEX_M_NVIC_ISER0)

/* ##########################   NVIC functions  #################################### */
/* \ingroup  CMSIS_Core_FunctionInterface
 * \defgroup CMSIS_Core_NVICFunctions CMSIS Core NVIC Functions
 * @{
 */

/* \brief  Set Priority Grouping
 * This function sets the priority grouping field using the required unlock sequence.
 * The parameter PriorityGroup is assigned to the field SCB_AIRCR [10:8] PRIGROUP field.
 * Only values from 0..7 are used.
 * In case of a conflict between priority grouping and available
 * priority bits (__NVIC_PRIO_BITS) the smallest possible priority group is set.
 * \param [in]      PriorityGroup  Priority grouping field
 */
__INLINE void NVIC_SetPriorityGrouping(uint32_t PriorityGroup)
{
    uint32_t reg_value;
    uint32_t PriorityGroupTmp = (PriorityGroup & (uint32_t) 0x07);  /* only values 0..7 are used          */

    reg_value = *r_CORTEX_M_SCB_AIRCR;  /* read old register configuration    */
    reg_value &= ~(SCB_AIRCR_VECTKEY_Msk | SCB_AIRCR_PRIGROUP_Msk); /* clear bits to change               */
    /* Insert write key and priority group */
    reg_value =
        (reg_value | ((uint32_t) 0x5FA << SCB_AIRCR_VECTKEY_Pos) |
         (PriorityGroupTmp << 8));
    *r_CORTEX_M_SCB_AIRCR = reg_value;
}

/* \brief  Get Priority Grouping
 * This function gets the priority grouping from NVIC Interrupt Controller.
 * Priority grouping is SCB->AIRCR [10:8] PRIGROUP field.
 * \return                Priority grouping field
 */
__INLINE uint32_t NVIC_GetPriorityGrouping(void)
{
    return ((*r_CORTEX_M_SCB_AIRCR & SCB_AIRCR_PRIGROUP_Msk) >> SCB_AIRCR_PRIGROUP_Pos);    /* read priority grouping field */
}

/* \brief  Enable External Interrupt
 * This function enables a device specific interrupt in the NVIC interrupt controller.
 * The interrupt number cannot be a negative value.
 * \param [in]      IRQn  Number of the external interrupt to enable
 */
__INLINE void NVIC_EnableIRQ(uint32_t IRQn)
{
    /*  NVIC->ISER[((uint32_t)(IRQn) >> 5)] = (1 << ((uint32_t)(IRQn) & 0x1F));  enable interrupt */
    NVIC_ISER[(uint32_t) ((int32_t) IRQn) >> 5] =
        (uint32_t) (1 << ((uint32_t) ((int32_t) IRQn) & (uint32_t) 0x1F));
}

/* \brief  Disable External Interrupt
 * This function disables a device specific interrupt in the NVIC interrupt controller.
 * The interrupt number cannot be a negative value.
 * \param [in]      IRQn  Number of the external interrupt to disable
 */
__INLINE void NVIC_DisableIRQ(uint32_t IRQn)
{
    NVIC_ICER[((uint32_t) (IRQn) >> 5)] = (uint32_t) (1 << ((uint32_t) (IRQn) & 0x1F)); /* disable interrupt */
}

/* \brief  Get Pending Interrupt
 * This function reads the pending register in the NVIC and returns the pending bit
 * for the specified interrupt.
 * \param [in]      IRQn  Number of the interrupt for get pending
 * \return             0  Interrupt status is not pending
 * \return             1  Interrupt status is pending
 */
__INLINE uint32_t NVIC_GetPendingIRQ(uint32_t IRQn)
{
    /* Return 1 if pending else 0 */
    return ((uint32_t)
            ((NVIC_ISPR[(uint32_t) (IRQn) >> 5] &
              (uint32_t) (1 << ((uint32_t) (IRQn) & 0x1F))) ? 1 : 0));
}

/* \brief  Set Pending Interrupt
 *
 * This function sets the pending bit for the specified interrupt.
 * The interrupt number cannot be a negative value.
 * \param [in]      IRQn  Number of the interrupt for set pending
 */
__INLINE void NVIC_SetPendingIRQ(uint32_t IRQn)
{
    NVIC_ISPR[((uint32_t) (IRQn) >> 5)] = (uint32_t) (1 << ((uint32_t) (IRQn) & 0x1F)); /* set interrupt pending */
}

/* \brief  Clear Pending Interrupt
 * This function clears the pending bit for the specified interrupt.
 * The interrupt number cannot be a negative value.
 * \param [in]      IRQn  Number of the interrupt for clear pending
 */
__INLINE void NVIC_ClearPendingIRQ(uint32_t IRQn)
{
    NVIC_ICPR[((uint32_t) (IRQn) >> 5)] = (uint32_t) (1 << ((uint32_t) (IRQn) & 0x1F)); /* Clear pending interrupt */
}

/* \brief  Get Active Interrupt
 * This function reads the active register in NVIC and returns the active bit.
 * \param [in]      IRQn  Number of the interrupt for get active
 * \return             0  Interrupt status is not active
 * \return             1  Interrupt status is active
 */
__INLINE uint32_t NVIC_GetActive(uint32_t IRQn)
{
    /* Return 1 if active else 0 */
    return ((uint32_t)
            ((NVIC_IABR[(uint32_t) (IRQn) >> 5] &
              (uint32_t) (1 << ((uint32_t) (IRQn) & 0x1F))) ? 1 : 0));
}

/* \brief  System Reset
 * This function initiate a system reset request to reset the MCU.
 */
__INLINE void NVIC_SystemReset(void)
{
    __DSB();                    /* Ensure all outstanding memory accesses included buffered write are completed before reset */
    *r_CORTEX_M_SCB_AIRCR = ((0x5FA << SCB_AIRCR_VECTKEY_Pos) | (*r_CORTEX_M_SCB_AIRCR & SCB_AIRCR_PRIGROUP_Msk) | SCB_AIRCR_SYSRESETREQ_Msk);  /* Keep priority group unchanged */
    __DSB();                    /* Ensure completion of memory access */
    while (1)
        continue;               /* wait until reset */
}

/*@} end of CMSIS_Core_NVICFunctions */

#endif /*!SOC_NVIC_H */
