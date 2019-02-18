/* \file soc-scb.h
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
#ifndef SOC_SCB_H
#define SOC_SCB_H

#include "regutils.h"
#include "soc-core.h"

/* System control block design hints and tips
 * Ensure software uses aligned accesses of the correct size to access the system control block registers:
 * • except for the CFSR and SHPR1-SHPR3, it must use aligned word accesses
 * • for the CFSR and SHPR1-SHPR3 it can use byte or aligned halfword or word accesses.
 *
 * The processor does not support unaligned accesses to system control block registers
 *
 * In a fault handler.
 *
 * to determine the true faulting address:
 *  1. Read and save the MMFAR or BFAR value.
 *  2. Read the MMARVALID bit in the MMFSR, or the BFARVALID bit in the BFSR.
 *
 *  The MMFAR or BFAR address is valid only if this bit is 1.
 *  Software must follow this sequence because another higher priority exception might change
 *  the MMFAR or BFAR value. For example, if a higher priority handler preempts the current
 *  fault handler, the other fault might change the MMFAR or BFAR value.
 */

/* SCB Registers */
#define r_CORTEX_M_SCB_ACTLR                REG_ADDR(SCS_BASE + (uint32_t) 0x08)    /* (R/W)  Auxiliary control register */

#define r_CORTEX_M_SCB				        REG_ADDR(SCB_BASE + (uint32_t) 0x00)
#define r_CORTEX_M_SCB_CPUID                REG_ADDR(SCB_BASE + (uint32_t) 0x00)    /* (R/ )  CPUID Base Register */
#define r_CORTEX_M_SCB_ICSR                 REG_ADDR(SCB_BASE + (uint32_t) 0x04)    /* (R/W)  Interrupt Control and State Register */
#define r_CORTEX_M_SCB_VTOR                 REG_ADDR(SCB_BASE + (uint32_t) 0x08)    /* (R/W)  Vector Table Offset Register */
#define r_CORTEX_M_SCB_AIRCR                REG_ADDR(SCB_BASE + (uint32_t) 0x0C)    /* (R/W)  Application Interrupt and Reset Control Register */
#define r_CORTEX_M_SCB_SCR                  REG_ADDR(SCB_BASE + (uint32_t) 0x10)    /* (R/W)  System Control Register */
#define r_CORTEX_M_SCB_CCR                  REG_ADDR(SCB_BASE + (uint32_t) 0x14)    /* (R/W)  Configuration Control Register */

#define r_CORTEX_M_SCB_SHPR1                REG_ADDR(SCB_BASE + (uint32_t) 0x18)    /* (R/W)  System Handlers Priority Registers (4-6) */
#define r_CORTEX_M_SCB_SHPR2                REG_ADDR(SCB_BASE + (uint32_t) 0x1C)    /* (R/W)  System Handlers Priority Registers (11) */
#define r_CORTEX_M_SCB_SHPR3                REG_ADDR(SCB_BASE + (uint32_t) 0x20)    /* (R/W)  System Handlers Priority Registers (14-15) */

#define r_CORTEX_M_SCB_SHCSR                REG_ADDR(SCB_BASE + (uint32_t) 0x24)    /* (R/W)  System Handler Control and State Register */

#define r_CORTEX_M_SCB_CFSR                 REG_ADDR(SCB_BASE + (uint32_t) 0x28)    /* (R/W)  Configurable Fault Status Register  */
#define r_CORTEX_M_SCB_MMSR                 REG_ADDR(SCB_BASE + (uint32_t) 0x28)    /* (R/W)  MemManage Fault Address Register (A subregister of the CFSR) */
#define r_CORTEX_M_SCB_BFSR                 REG_ADDR(SCB_BASE + (uint32_t) 0x29)    /* (R/W)  BusFault Status Register  */
#define r_CORTEX_M_SCB_UFSR                 REG_ADDR(SCB_BASE + (uint32_t) 0x2a)    /* (R/W)  UsageFault Status Register  */

#define r_CORTEX_M_SCB_HFSR                 REG_ADDR(SCB_BASE + (uint32_t) 0x2c)    /* (R/W)  Hard fault status register  */
#define r_CORTEX_M_SCB_MMFAR                REG_ADDR(SCB_BASE + (uint32_t) 0x34)    /* (R/W)  Memory management fault address register */
#define r_CORTEX_M_SCB_BFAR                 REG_ADDR(SCB_BASE + (uint32_t) 0x38)    /* (R/W)  Bus fault address register (BFAR) */
#define r_CORTEX_M_SCB_AFSR                 REG_ADDR(SCB_BASE + (uint32_t) 0x3c)    /* (R/W)  Auxiliary fault status register */

#define r_CORTEX_M_SCB_CPACR                REG_ADDR(SCB_BASE + (uint32_t) 0x88)    /* (R/W)  Coprocessor Access Control register */

/* Auxiliary control register Définitions */
#define SCB_ACTLR_DISOOFP_Pos               9   /* Bit 9 DISOOFP  */
#define SCB_ACTLR_DISOOFP_Msk               ((uint32_t) 0x01 << SCB_ACTLR_DISOOFP_Pos)
#define SCB_ACTLR_DISFPCA_Pos               8   /* Bit 8 DISFPCA  */
#define SCB_ACTLR_DISFPCA_Msk               ((uint32_t) 0x01 << SCB_ACTLR_DISFPCA_Pos)
#define SCB_ACTLR_DISFOLD_Pos               2   /* Bit 2 DISFOLD  */
#define SCB_ACTLR_DISFOLD_Msk               ((uint32_t) 0x01 << SCB_ACTLR_DISFOLD_Pos)
#define SCB_ACTLR_DISDEFWBUF_Pos            1   /* Bit 1 DISDEFWBUF   */
#define SCB_ACTLR_DISDEFWBUF_Msk            ((uint32_t) 0x01 << SCB_ACTLR_DISDEFWBUF_Pos)
#define SCB_ACTLR_DISMCYCINT_Pos            0   /* Bit 0 DISMCYCINT   */
#define SCB_ACTLR_DISMCYCINT_Msk            ((uint32_t) 0x01 << SCB_ACTLR_DISMCYCINT_Pos)

/* SCB CPUID Register Definitions */
#define SCB_CPUID_IMPLEMENTER_Pos          24   /* Bits 31:24 IMPLEMENTER Position */
#define SCB_CPUID_IMPLEMENTER_Msk          ((uint32_t) 0x00ff << SCB_CPUID_IMPLEMENTER_Pos)

#define SCB_CPUID_VARIANT_Pos              20   /* Bits 23:20 VARIANT Position */
#define SCB_CPUID_VARIANT_Msk              ((uint32_t) 0x000f << SCB_CPUID_VARIANT_Pos)

#define SCB_CPUID_ARCHITECTURE_Pos         16   /* Bits 19:16 ARCHITECTURE Position */
#define SCB_CPUID_ARCHITECTURE_Msk         ((uint32_t) 0x000f << SCB_CPUID_ARCHITECTURE_Pos)

#define SCB_CPUID_PARTNO_Pos                4   /* Bits 15:4 PartNo Position */
#define SCB_CPUID_PARTNO_Msk               ((uint32_t) 0x0fff << SCB_CPUID_PARTNO_Pos)

#define SCB_CPUID_REVISION_Pos              0   /* Bits 3:0 Revision Position */
#define SCB_CPUID_REVISION_Msk             ((uint32_t) 0x000f << SCB_CPUID_REVISION_Pos)

/* SCB Interrupt Control State Register Definitions */
#define SCB_ICSR_NMIPENDSET_Pos            31   /* Bit 31 NMIPENDSET:
                                                   NMI set-pending bit position */
#define SCB_ICSR_NMIPENDSET_Msk            ((uint32_t) 0x01 << SCB_ICSR_NMIPENDSET_Pos)

#define SCB_ICSR_PENDSVSET_Pos             28   /* Bit 28 PENDSVSET:
                                                   PendSV set-pending bit Position */
#define SCB_ICSR_PENDSVSET_Msk             ((uint32_t) 0x01 << SCB_ICSR_PENDSVSET_Pos)

#define SCB_ICSR_PENDSVCLR_Pos             27   /* Bit 27 PENDSVCLR:
                                                   PendSV clear-pending bit Position */
#define SCB_ICSR_PENDSVCLR_Msk             ((uint32_t) 0x01 << SCB_ICSR_PENDSVCLR_Pos)

#define SCB_ICSR_PENDSTSET_Pos             26   /* Bit 26 PENDSTSET:
                                                   SysTick exception set-pending bit Position */
#define SCB_ICSR_PENDSTSET_Msk             ((uint32_t) 0x01 << SCB_ICSR_PENDSTSET_Pos)

#define SCB_ICSR_PENDSTCLR_Pos             25   /* Bit 25 PENDSTCLR:
                                                   SysTick exception clear-pending bit Position */
#define SCB_ICSR_PENDSTCLR_Msk             ((uint32_t) 0x01 << SCB_ICSR_PENDSTCLR_Pos)

#define SCB_ICSR_ISRPREEMPT_Pos            23   /* Bit 23 ISRPREEMPT:
                                                   reserved for Debug use and reads-as-zero when
                                                   the processor is not in Debug */
#define SCB_ICSR_ISRPREEMPT_Msk            ((uint32_t) 0x01 << SCB_ICSR_ISRPREEMPT_Pos)

#define SCB_ICSR_ISRPENDING_Pos            22   /* Bit 22 ISRPENDING:
                                                   Interrupt pending flag, excluding NMI and Faults */
#define SCB_ICSR_ISRPENDING_Msk            ((uint32_t) 0x01 << SCB_ICSR_ISRPENDING_Pos)

#define SCB_ICSR_VECTPENDING_Pos           12   /* Bits 18:12 VECTPENDING: Pending vector.
                                                   Indicates the exception number of the highest priority
                                                   pending enabled exception Position */
#define SCB_ICSR_VECTPENDING_Msk           (0x1FFUL << SCB_ICSR_VECTPENDING_Pos)

#define SCB_ICSR_RETTOBASE_Pos             11   /* Bit 11 RETTOBASE: Return to base level.
                                                   Indicates whether there are preempted active                                                                                                                          exceptions Position */
#define SCB_ICSR_RETTOBASE_Msk             ((uint32_t) 0x01 << SCB_ICSR_RETTOBASE_Pos)

#define SCB_ICSR_VECTACTIVE_Pos             0   /* Bits 8:0 VECTACTIVE Active vector.
                                                   Contains the active exception number Position */
#define SCB_ICSR_VECTACTIVE_Msk            ((uint32_t) 0x1FF << SCB_ICSR_VECTACTIVE_Pos)

/* SCB Vector Table Offset Register Definitions */
#define SCB_VTOR_TBLOFF_Pos                9    /* Bits 29:9 TBLOFF: Vector table base offset field */
#define SCB_VTOR_TBLOFF_Msk                ((uint32_t) 0x1fffff << SCB_VTOR_TBLOFF_Pos)

/* SCB Application Interrupt and Reset Control Register Definitions */
#define SCB_AIRCR_VECTKEY_Pos              16   /* Bits 31:16 VECTKEYSTAT/ VECTKEY Register key */
#define SCB_AIRCR_VECTKEY_Msk              ((uint32_t) 0xFFFF << SCB_AIRCR_VECTKEY_Pos)

#define SCB_AIRCR_ENDIANESS_Pos            15   /* Bit 15 ENDIANESS Data endianness bit */
#define SCB_AIRCR_ENDIANESS_Msk            ((uint32_t) 0x01 << SCB_AIRCR_ENDIANESS_Pos)

#define SCB_AIRCR_PRIGROUP_Pos              8   /* Bits 10:8 PRIGROUP: Interrupt priority grouping field  */
#define SCB_AIRCR_PRIGROUP_Msk             ((uint32_t) 0x07 << SCB_AIRCR_PRIGROUP_Pos)

#define SCB_AIRCR_SYSRESETREQ_Pos           2   /* Bit 2 SYSRESETREQ System reset request */
#define SCB_AIRCR_SYSRESETREQ_Msk          ((uint32_t) 0x01 << SCB_AIRCR_SYSRESETREQ_Pos)

#define SCB_AIRCR_VECTCLRACTIVE_Pos         1   /* Bit 1 VECTCLRACTIVE Reserved for Debug use.
                                                   This bit reads as 0.
                                                   When writing to the register you must write 0 to
                                                   this bit, otherwise behavior is unpredictable. */
#define SCB_AIRCR_VECTCLRACTIVE_Msk        ((uint32_t) 0x01 << SCB_AIRCR_VECTCLRACTIVE_Pos)

#define SCB_AIRCR_VECTRESET_Pos             0   /* Bit 0 VECTRESET
                                                   Reserved for Debug use.
                                                   This bit reads as 0.
                                                   When writing to the register you must write 0 to
                                                   this bit, otherwise behavior is unpredictable. */
#define SCB_AIRCR_VECTRESET_Msk            ((uint32_t) 0x01 << SCB_AIRCR_VECTRESET_Pos)

/* SCB System Control Register Definitions */
#define SCB_SCR_SEVONPEND_Pos               4   /* Bit 4 SEVEONPEND Send Event on Pending bit */
#define SCB_SCR_SEVONPEND_Msk              ((uint32_t) 0x01 << SCB_SCR_SEVONPEND_Pos)

#define SCB_SCR_SLEEPDEEP_Pos               2   /* Bit 2 SLEEPDEEP  */
#define SCB_SCR_SLEEPDEEP_Msk              ((uint32_t) 0x01 << SCB_SCR_SLEEPDEEP_Pos)

#define SCB_SCR_SLEEPONEXIT_Pos             1   /* Bit 1 SLEEPONEXIT  */
#define SCB_SCR_SLEEPONEXIT_Msk            ((uint32_t) 0x01 << SCB_SCR_SLEEPONEXIT_Pos)

/* SCB Configuration Control Register Definitions */
#define SCB_CCR_STKALIGN_Pos                9   /* Bit 9 STKALIGN */
#define SCB_CCR_STKALIGN_Msk               ((uint32_t) 0x01 << SCB_CCR_STKALIGN_Pos)

#define SCB_CCR_BFHFNMIGN_Pos               8   /* Bit 8 BFHFNMIGN */
#define SCB_CCR_BFHFNMIGN_Msk              ((uint32_t) 0x01 << SCB_CCR_BFHFNMIGN_Pos)

#define SCB_CCR_DIV_0_TRP_Pos               4   /* Bit 4 DIV_0_TRP */
#define SCB_CCR_DIV_0_TRP_Msk              ((uint32_t) 0x01 << SCB_CCR_DIV_0_TRP_Pos)

#define SCB_CCR_UNALIGN_TRP_Pos             3   /* Bit 3 UNALIGN_ TRP */
#define SCB_CCR_UNALIGN_TRP_Msk            ((uint32_t) 0x01 << SCB_CCR_UNALIGN_TRP_Pos)

#define SCB_CCR_USERSETMPEND_Pos            1   /* Bit 1 USERSETMPEND */
#define SCB_CCR_USERSETMPEND_Msk           ((uint32_t) 0x01 << SCB_CCR_USERSETMPEND_Pos)

#define SCB_CCR_NONBASETHRDENA_Pos          0   /* Bit 0 NONBASETHRDENA */
#define SCB_CCR_NONBASETHRDENA_Msk         ((uint32_t) 0x01 << SCB_CCR_NONBASETHRDENA_Pos)

//System handler priority register 1 (SHPR1)
#define SCB_SHPR1_PRI_4_Pos                 0   /* Bits 7:0 PRI_4:
                                                   Priority of system handler 4,
                                                   memory management fault */
#define SCB_SHPR1_PRI_4_Msk                 ((uint32_t) 0xff << SCB_SHPR1_PRI_4_Pos)

#define SCB_SHPR1_PRI_5_Pos                 8   /* Bits 15:8 PRI_5:
                                                   Priority of system handler 5, bus fault */
#define SCB_SHPR1_PRI_5_Msk                 ((uint32_t) 0xff << SCB_SHPR1_PRI_5_Pos)

//System handler priority register 2 (SHPR2)
#define SCB_SHPR2_PRI_6_Pos                 16  /* Bits 23:16 PRI_6:
                                                   Priority of system handler 6, usage fault */
#define SCB_SHPR2_PRI_6_Msk                 ((uint32_t) 0xff << SCB_SHPR2_PRI_6_Pos)
#define SCB_SHPR2_PRI_11_Pos                 24 /* Bits 31:24 PRI_11:
                                                   Priority of system handler 11, SVCall */
#define SCB_SHPR2_PRI_11_Msk                ((uint32_t) 0xff << SCB_SHPR2_PRI_11_Pos)

//System handler priority register 3 (SHPR3)
#define SCB_SHPR3_PRI_14_Pos                16  /* Bits 23:16 PRI_14:
                                                   Priority of system handler 14, PendSV */
#define SCB_SHPR3_PRI_14_Msk                ((uint32_t) 0xff << SCB_SHPR3_PRI_14_Pos)
#define SCB_SHPR3_PRI_15_Pos                24  /* Bits 31:24 PRI_15:
                                                   Priority of system handler 15, SysTick exception */
#define SCB_SHPR3_PRI_15_Msk                ((uint32_t) 0xff << SCB_SHPR3_PRI_15_Pos)

/* SCB System Handler Control and State Register Definitions */
#define SCB_SHCSR_USGFAULTENA_Pos          18   /* Bit 18 USGFAULTENA:
                                                   Usage fault enable bit, set to 1 to enable */
#define SCB_SHCSR_USGFAULTENA_Msk          ((uint32_t) 0x01 << SCB_SHCSR_USGFAULTENA_Pos)

#define SCB_SHCSR_BUSFAULTENA_Pos          17   /* Bit 17 BUSFAULTENA:
                                                   Bus fault enable bit, set to 1 to enabl */
#define SCB_SHCSR_BUSFAULTENA_Msk          ((uint32_t) 0x01 << SCB_SHCSR_BUSFAULTENA_Pos)

#define SCB_SHCSR_MEMFAULTENA_Pos          16   /* Bit 16 MEMFAULTENA:
                                                   Memory management fault enable bit,
                                                   set to 1 to enable */
#define SCB_SHCSR_MEMFAULTENA_Msk          ((uint32_t) 0x01 << SCB_SHCSR_MEMFAULTENA_Pos)

#define SCB_SHCSR_SVCALLPENDED_Pos         15   /* Bit 15 SVCALLPENDED:
                                                   SVC call pending bit,
                                                   reads as 1 if exception is pending */
#define SCB_SHCSR_SVCALLPENDED_Msk         ((uint32_t) 0x01 << SCB_SHCSR_SVCALLPENDED_Pos)

#define SCB_SHCSR_BUSFAULTPENDED_Pos       14   /* Bit 14 BUSFAULTPENDED:
                                                   Bus fault exception pending bit,
                                                   reads as 1 if exception is pending */
#define SCB_SHCSR_BUSFAULTPENDED_Msk       ((uint32_t) 0x01 << SCB_SHCSR_BUSFAULTPENDED_Pos)

#define SCB_SHCSR_MEMFAULTPENDED_Pos       13   /* Bit 13 MEMFAULTPENDED:
                                                   Memory management fault exception pending bit,
                                                   reads as 1 if exception is pending */
#define SCB_SHCSR_MEMFAULTPENDED_Msk       ((uint32_t) 0x01 << SCB_SHCSR_MEMFAULTPENDED_Pos)

#define SCB_SHCSR_USGFAULTPENDED_Pos       12   /* Bit 12 USGFAULTPENDED:
                                                   Usage fault exception pending bit,
                                                   reads as 1 if exception is pending */
#define SCB_SHCSR_USGFAULTPENDED_Msk       ((uint32_t) 0x01 << SCB_SHCSR_USGFAULTPENDED_Pos)

#define SCB_SHCSR_SYSTICKACT_Pos           11   /* Bit 11 SYSTICKACT:
                                                   SysTick exception active bit,
                                                   reads as 1 if exception is active */
#define SCB_SHCSR_SYSTICKACT_Msk           ((uint32_t) 0x01 << SCB_SHCSR_SYSTICKACT_Pos)

#define SCB_SHCSR_PENDSVACT_Pos            10   /* Bit 10 PENDSVACT:
                                                   PendSV exception active bit,
                                                   reads as 1 if exception is activen */
#define SCB_SHCSR_PENDSVACT_Msk            ((uint32_t) 0x01 << SCB_SHCSR_PENDSVACT_Pos)

#define SCB_SHCSR_MONITORACT_Pos            8   /* Bit 8 MONITORACT:
                                                   Debug monitor active bit,
                                                   reads as 1 if Debug monitor is active */
#define SCB_SHCSR_MONITORACT_Msk           ((uint32_t) 0x01 << SCB_SHCSR_MONITORACT_Pos)

#define SCB_SHCSR_SVCALLACT_Pos             7   /* Bit 7 SVCALLACT:
                                                   SVC call active bit,
                                                   reads as 1 if SVC call is active */
#define SCB_SHCSR_SVCALLACT_Msk            ((uint32_t) 0x01 << SCB_SHCSR_SVCALLACT_Pos)

#define SCB_SHCSR_USGFAULTACT_Pos           3   /* Bit 3 USGFAULTACT:
                                                   Usage fault exception active bit,
                                                   reads as 1 if exception is active */
#define SCB_SHCSR_USGFAULTACT_Msk          ((uint32_t) 0x01 << SCB_SHCSR_USGFAULTACT_Pos)

#define SCB_SHCSR_BUSFAULTACT_Pos           1   /* Bit 1 BUSFAULTACT:
                                                   Bus fault exception active bit,
                                                   reads as 1 if exception is active */
#define SCB_SHCSR_BUSFAULTACT_Msk          ((uint32_t) 0x01 << SCB_SHCSR_BUSFAULTACT_Pos)

#define SCB_SHCSR_MEMFAULTACT_Pos           0   /* Bit 0 MEMFAULTACT:
                                                   Memory management fault exception active bit,
                                                   reads as 1 if exception is active */
#define SCB_SHCSR_MEMFAULTACT_Msk          ((uint32_t) 0x01 << SCB_SHCSR_MEMFAULTACT_Pos)

/* Configurable fault status register (CFSR; UFSR+BFSR+MMFSR)
 * The CFSR is byte accessible. You can access the CFSR or its subregisters as follows:
 * • Access the complete CFSR with a word access to 0xE000ED28
 * • Access the MMFSR with a byte access to 0xE000ED28
 * • Access the MMFSR and BFSR with a halfword access to 0xE000ED28
 * • Access the BFSR with a byte access to 0xE000ED29
 * • Access the UFSR with a halfword access to 0xE000ED2A.
 *
 * The CFSR indicates the cause of a memory management fault, bus fault, or usage fault.
 */

#define SCB_CFSR_UFSR_Pos                       16  /* Bits 31:16 UFSR:
                                                       Usage fault status register (UFSR) */
#define SCB_CFSR_UFSR_Msk                       ((uint32_t) 0xffff << SCB_CFSR_UFSR_Pos)
#define SCB_CFSR_BFSR_Pos                       8   /* Bits 15:8 BFSR:
                                                       Bus fault status register (BFSR) */
#define SCB_CFSR_BFSR_Msk                       ((uint32_t) 0xff << SCB_CFSR_BFSR_Pos)
#define SCB_CFSR_MMFSR_Pos                      0   /* Bits 7:0 MMFSR:
                                                       Memory management fault address register (MMFSR) */
#define SCB_CFSR_MMFSR_Msk                      ((uint32_t) 0xff << SCB_CFSR_MMFSR_Pos)

 /* Usage fault status register (UFSR) */
#define SCB_CFSR_UFSR_DIVBYZERO_Pos              25 /* Bit 25 DIVBYZERO:
                                                       Divide by zero usage fault. */
#define SCB_CFSR_UFSR_DIVBYZERO_Msk              ((uint32_t) 0x01 << SCB_UFSR_DIVBYZERO_Pos)
#define SCB_CFSR_UFSR_UNALIGNED_Pos              24 /* Bit 24 UNALIGNED:
                                                       Unaligned access usage fault. */
#define SCB_CFSR_UFSR_UNALIGNED_Msk              ((uint32_t) 0x01 << SCB_UFSR_UNALIGNED_Pos)
#define SCB_CFSR_UFSR_NOCP_Pos                   19 /* Bit 19 NOCP:
                                                       No coprocessor usage fault. */
#define SCB_CFSR_UFSR_NOCP_Msk                   ((uint32_t) 0x01 << SCB_UFSR_NOCP_Pos)
#define SCB_CFSR_UFSR_INVPC_Pos                  18 /* Bit 18 INVPC:
                                                       Invalid PC load usage fault,
                                                       caused by an invalid PC load by EXC_RETURN */
#define SCB_CFSR_UFSR_INVPC_Msk                  ((uint32_t) 0x01 << SCB_UFSR_INVPC_Pos)
#define SCB_CFSR_UFSR_INVSTATE_Pos               17 /* Bit 17 INVSTATE:
                                                       Invalid state usage fault. */
#define SCB_CFSR_UFSR_INVSTATE_Msk               ((uint32_t) 0x01 << SCB_UFSR_INVSTATE_Pos)
#define SCB_CFSR_UFSR_UNDEFINSTR_Pos             16 /* Bit 16 UNDEFINSTR:
                                                       Undefined instruction usage fault. */
#define SCB_CFSR_UFSR_UNDEFINSTR_Msk             ((uint32_t) 0x01 << SCB_UFSR_UNDEFINSTR_Pos)

/* Bus fault status register (BFSR) */
#define SCB_CFSR_BFSR_BFARVALID_Pos              15 /* Bit 15 BFARVALID:
                                                       Bus Fault Address Register (BFAR) valid flag.
                                                       The processor sets this bit to 1 */
#define SCB_CFSR_BFSR_BFARVALID_Msk              ((uint32_t) 0x01 << SCB_BFSR_BFARVALID_Pos)
#define SCB_CFSR_BFSR_LSPERR_Pos                 13 /* Bit 13 LSPERR:
                                                       Bus fault on floating-point lazy state preservation. */
#define SCB_CFSR_BFSR_LSPERR_Msk                 ((uint32_t) 0x01 << SCB_BFSR_LSPERR_Pos)
#define SCB_CFSR_BFSR_STKERR_Pos                 12 /* Bit 12 STKERR:
                                                       Bus fault on stacking for exception entry. */
#define SCB_CFSR_BFSR_STKERR_Msk                 ((uint32_t) 0x01 << SCB_BFSR_STKERR_Pos)
#define SCB_CFSR_BFSR_UNSTKERR_Pos               11 /* Bit 11 UNSTKERR:
                                                       Bus fault on unstacking for a return from exception. */
#define SCB_CFSR_BFSR_UNSTKERR_Msk               ((uint32_t) 0x01 << SCB_BFSR_UNSTKERR_Pos)
#define SCB_CFSR_BFSR_IMPRECISERR_Pos            10 /* Bit 10 IMPRECISERR:
                                                       Imprecise data bus error. */
#define SCB_CFSR_BFSR_IMPRECISERR_Msk            ((uint32_t) 0x01 << SCB_BFSR_IMPRECISERR_Pos)
#define SCB_CFSR_BFSR_PRECISERR_Pos              9  /* Bit 9 PRECISERR:
                                                       Precise data bus error. */
#define SCB_CFSR_BFSR_PRECISERR_Msk              ((uint32_t) 0x01 << SCB_BFSR_PRECISERR_Pos)
#define SCB_CFSR_BFSR_IBUSERR_Pos                8  /* Bit 8 IBUSERR:
                                                       Instruction bus error. */
#define SCB_CFSR_BFSR_IBUSERR_Msk                ((uint32_t) 0x01 << SCB_BFSR_IBUSERR_Pos)

/* Memory management fault address register (MMFSR)*/
#define SCB_CFSR_MMFSR_MMARVALID_Pos             7  /* Bit 7 MMARVALID:
                                                       Memory Management Fault Address Register (MMAR) valid flag. */
#define SCB_CFSR_MMFSR_MMARVALID_Msk             ((uint32_t) 0x01 << SCB_CFSR_MMFSR_MMARVALID_Pos)
#define SCB_CFSR_MMFSR_MLSPERR_Pos               5  /* Bit 5 MLSPERR:
                                                       MemManage fault  status */
#define SCB_CFSR_MMFSR_MLSPERR_Msk               ((uint32_t) 0x01 << SCB_CFSR_MMFSR_MLSPERR_Pos)
#define SCB_CFSR_MMFSR_MSTKERR_Pos               4  /* Bit 4 MSTKERR:
                                                       Memory manager fault on stacking for exception entry. */
#define SCB_CFSR_MMFSR_MSTKERR_Msk               ((uint32_t) 0x01 << SCB_CFSR_MMFSR_MSTKERR_Pos)
#define SCB_CFSR_MMFSR_MUNSTKERR_Pos             3  /* Bit 3 MUNSTKERR:
                                                       Memory manager fault on unstacking
                                                       for a return from exception. */
#define SCB_CFSR_MMFSR_MUNSTKERR_Msk             ((uint32_t) 0x01 << SCB_CFSR_MMFSR_MUNSTKERR_Pos)
#define SCB_CFSR_MMFSR_DACCVIOL_Pos              1  /* Bit 1 DACCVIOL:
                                                       Data access violation flag. */
#define SCB_CFSR_MMFSR_DACCVIOL_Msk              ((uint32_t) 0x01 << SCB_CFSR_MMFSR_DACCVIOL_Pos)

#define SCB_CFSR_MMFSR_IACCVIOL_Pos              0  /* Bit 0 IACCVIOL:
                                                       Instruction access violation flag.
                                                       This fault occurs on any access to an XN region */
#define SCB_CFSR_MMFSR_IACCVIOL_Msk              ((uint32_t) 0x01 << SCB_CFSR_MMFSR_Pos)

/* Hard fault status register (HFSR)*/
#define SCB_HFSR_DEBUG_VT_Pos                   31  /*  Bit 31 DEBUG_VT:
                                                       Reserved for Debug use.
                                                       When writing to the register you must write 0 to this bit */
#define SCB_HFSR_DEBUG_VT_Msk              ((uint32_t) 0x01 << SCB_HFSR_DEBUG_VT_Pos)

#define SCB_HFSR_FORCED_Pos                30   /*  Bit 30 FORCED:
                                                   Forced hard fault.
                                                   Indicates a forced hard fault,
                                                   generated by escalation of a fault */
#define SCB_HFSR_FORCED_Msk                ((uint32_t) 0x01 << SCB_HFSR_FORCED_Pos)

#define SCB_HFSR_VECTTBL_Pos               1    /*  Bit 1 VECTTBL:
                                                   Vector table hard fault.
                                                   Indicates a bus fault on a vector table read during */
#define SCB_HFSR_VECTTBL_Msk               ((uint32_t) 0x01 << SCB_HFSR_VECTTBL_Pos)

/* Memory management fault address register (MMFAR) */
#define SCB_MMFAR_Pos                       0   /* Bits 31:0 MMFAR: Memory management fault address */
#define SCB_MMFAR_Msk                       ((uint32_t) 0xffffffff << SCB_MMFAR_Pos)

/* Bus fault address register (BFAR) */
#define SCB_BFAR_Pos                        0   /* Bits 31:0 Bus fault address
                                                   When the BFARVALID bit of the BFSR is set to 1,
                                                   this field holds the address f the location that
                                                   generated the bus fault. When an unaligned access faults
                                                   the address in the BFAR is the one requested by the instruction,
                                                   even if it is not the adress of the fault. */
#define SCB_BFAR_Msk                        ((uint32_t) 0xffffffff << SCB_BFAR_Pos)

/* Auxiliary fault status register (AFSR) */
#define SCB_AFSR_IMPDEF_Pos                  0  /* Bits 31:0 IMPDEF:
                                                   Implementation defined.
                                                   The AFSR contains additional system fault information. */
#define SCB_AFSR_IMPDEF_Msk                  ((uint32_t) 0xffffffff << SCB_AFSR_IMPDEF_Pos)
#endif /* SOC_SCB_H */
