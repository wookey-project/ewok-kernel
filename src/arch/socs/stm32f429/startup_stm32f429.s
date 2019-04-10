/**
  ******************************************************************************
  * @file      startup_stm32f4xx.s
  * @author    MCD Application Team
  * @version   V1.0.0
  * @date      30-September-2011
  * @brief     STM32F4xx Devices vector table for Atollic TrueSTUDIO toolchain.
  *            This module performs:
  *                - Set the initial SP
  *                - Set the initial PC == Reset_Handler,
  *                - Set the vector table entries with the exceptions ISR address
  *                - Configure the clock system and the external SRAM mounted on
  *                  STM324xG-EVAL board to be used as data memory (optional,
  *                  to be enabled by user)
  *                - Branches to main in the C library (which eventually
  *                  calls main()).
  *            After Reset the Cortex-M4 processor is in Thread mode,
  *            priority is Privileged, and the Stack is set to Main.
  ******************************************************************************
  * @attention
  *
  * THE PRESENT FIRMWARE WHICH IS FOR GUIDANCE ONLY AIMS AT PROVIDING CUSTOMERS
  * WITH CODING INFORMATION REGARDING THEIR PRODUCTS IN ORDER FOR THEM TO SAVE
  * TIME. AS A RESULT, STMICROELECTRONICS SHALL NOT BE HELD LIABLE FOR ANY
  * DIRECT, INDIRECT OR CONSEQUENTIAL DAMAGES WITH RESPECT TO ANY CLAIMS ARISING
  * FROM THE CONTENT OF SUCH FIRMWARE AND/OR THE USE MADE BY CUSTOMERS OF THE
  * CODING INFORMATION CONTAINED HEREIN IN CONNECTION WITH THEIR PRODUCTS.
  *
  * <h2><center>&copy; COPYRIGHT 2011 STMicroelectronics</center></h2>
  ******************************************************************************
  */

.syntax unified
.cpu cortex-m4
.fpu softvfp
.thumb

.global g_pfnVectors
.global g_BaseAddress
.global g_StackAddress

.extern Default_SubHandler

/* start address for the initialization values of the .data section. defined in linker script */
.word   _sidata
/* start address for the .data section. defined in linker script */
.word   _sdata
/* end address for the .data section. defined in linker script */
.word   _edata
/* start address for the .bss section. defined in linker script */
.word   _sbss
/* end address for the .bss section. defined in linker script */
.word   _ebss
.word   _sigot
.word   _sgot
.word   _egot


/*
.word   _svtors
.word   _evtors
*/
/*
 * @brief Globals variables
 * @param  None
 * @retval None
 *
 */

.section .data
g_BaseAddress:
    .word 0
g_StackAddress:
    .word 0

/*
 * @brief  This is the code that gets called when the processor first
 *          starts execution following a reset event. Only the absolutely
 *          necessary set is performed, after which the application
 *          supplied main() routine is called.
 * @param  None
 * @retval None
 */

.section .text.Reset_Handler
    .weak  Reset_Handler
    .type  Reset_Handler, %function
Reset_Handler:
    bl  _start                  /* Entry point address */
_start:
    movs    r5, lr
    sub     r5, #5              /* In thumb mode LR is pointing to PC + 4 bytes  + 1 because in thumb mode LR must be odd aligned*/
    sub     r2, r5, #0x188      /* Compute vector table address FIXME: We should use dynimic value for VTORS_SIZE */
    ldr     r2, [r2]
    msr     msp, r2             /* Reset stack address to default 0x20002000 */

    movs  r1, #0
    b       LoopCopyDataInit
CopyDataInit:                   /* Copy the data segment initializers from flash to SRAM */
    ldr     r3, =_sidata        /* start address for the initialization values of the .data section. */
    ldr     r3, [r3, r1]
    str     r3, [r0, r1]
    adds    r1, r1, #4
LoopCopyDataInit:
    ldr     r0, =_sdata         /* start address for the .data section */
    ldr     r3, =_edata         /* end address for the .data section */
    adds    r2, r0, r1
    cmp     r2, r3
    bcc     CopyDataInit


    ldr     r2, =_sbss          /* start address for the .bss section */
    b       LoopFillZerobss
FillZerobss:                     /* Zero fill the bss segment. */
    movs    r3, #0
    str     r3, [r2], #4
LoopFillZerobss:
    ldr     r3, = _ebss          /* end address for the .bss section */
    cmp     r2, r3
    bcc     FillZerobss
    movs    r0, #1
    ldr     r1, = g_BaseAddress
    str     r5, [r1]
    dmb
    bl      main
    bx      lr

.size  Reset_Handler, .-Reset_Handler

.section .text.Default_Handler
    .weak  Default_Handler
    .type  Default_Handler, %function
Default_Handler:
    cpsid   i

    /*
     * The NVIC has already saved R0-R3, R12, LR, PC and xPSR registers on the
     * stack. We save the remaining registers (R4-R11) and LR (with the new
     * value) on that previously used stack.
     */

    /* 1) Which stack was previously used ?  */

    tst     lr, #4      /* bit 2: (0) MSP (1) PSP stack      */
    ite     eq          /* if equal 0                        */
    mrseq   r0, msp     /* r0 <- MSP                         */
    mrsne   r0, psp     /* r0 <- PSP (process stack)         */

    /*
     * 2) Save registers on the previously used stack.
     *    R0 points to the saved registers:
     *        LR, R4-R11, R0-R3, R12, previous LR, PC, xPSR
     */

    stmfd   r0!, {r4-r11, lr}

    /* 3) Adjusting the previously used stack pointer (might be PSP or MSP) */

    tst     lr, #4      /* bit 2: (0) MSP (1) PSP stack      */
    ite     eq          /* if equal 0                        */
    msreq   msp, r0     /* MSP <- r0                         */
    msrne   psp, r0     /* PSP <- r0                         */

    /*
     * R0 is passed as a parameter. It still points to the saved registers.
     * In case of task switching, R0 returned by `Default_SubHandler' might be
     * different.
     * R1 is returned by `Default_SubHandler' and it contains the task type.
     * Valid R1 values are privileged (0) or unprivileged (1).
     */

    bl      Default_SubHandler

    /* Registers LR, R4-R11 are restored */
    ldmfd   r0!, {r4-r11, lr}

    /*
     * Adjusting PSP/MSP so that the NVIC can restore the remaining registers
     * and setting the execution mode (privileged or unprivileged)
     */

    tst     lr, #4      /* bit 2: (0) MSP (1) PSP stack      */
    bne     psp_use     /* if not equal 0                    */

msp_use:
    /* That branch should never be executed as every task use the PSP */
    msr     msp, r0     /* MSP <- r0 */
    cpsie   i
    bx      lr

psp_use:
    msr     psp, r0     /* PSP <- r0 */

    /* Is it an unprivileged task ? */
    cmp     r1, #1
    bne     kern_mode

user_mode:
    mov     r0, #3
    msr     control, r0
    isb
    cpsie   i
    bx      lr

kern_mode:
    mov     r0, #2
    msr     control, r0
    isb
    cpsie   i
    bx      lr
.size Default_Handler, .-Default_Handler

/******************************************************************************
 *
 * The minimal vector table for a Cortex M4. Note that the proper constructs
 * must be placed on this to ensure that it ends up at physical address
 * 0x0000.0000.
 *
 ******************************************************************************/
.section  .isr_vector,"a",%progbits
  .type  g_pfnVectors, %object
  .size  g_pfnVectors, .-g_pfnVectors

g_pfnVectors:
  .word  _estack
  .word  Reset_Handler
  .word  Default_Handler
  .word  Default_Handler
  .word  Default_Handler
  .word  Default_Handler
  .word  Default_Handler
  .word  0
  .word  0
  .word  0
  .word  0
  .word  Default_Handler
  .word  Default_Handler
  .word  0
  .word  Default_Handler
  .word  Default_Handler

  /*
   * External Interrupts
   */
  .word     Default_Handler     /* Window WatchDog */
  .word     Default_Handler     /* PVD through EXTI Line detection */
  .word     Default_Handler     /* Tamper and TimeStamps through the EXTI line */
  .word     Default_Handler     /* RTC Wakeup through the EXTI line */
  .word     Default_Handler     /* FLASH */
  .word     Default_Handler     /* RCC */
  .word     Default_Handler     /* EXTI Line0 */
  .word     Default_Handler     /* EXTI Line1 */
  .word     Default_Handler     /* EXTI Line2 */
  .word     Default_Handler     /* EXTI Line3 */
  .word     Default_Handler     /* EXTI Line4 */
  .word     Default_Handler     /* DMA1 Stream 0 */
  .word     Default_Handler     /* DMA1 Stream 1 */
  .word     Default_Handler     /* DMA1 Stream 2 */
  .word     Default_Handler     /* DMA1 Stream 3 */
  .word     Default_Handler     /* DMA1 Stream 4 */
  .word     Default_Handler     /* DMA1 Stream 5 */
  .word     Default_Handler     /* DMA1 Stream 6 */
  .word     Default_Handler     /* ADC1, ADC2 and ADC3s */
  .word     Default_Handler     /* CAN1 TX */
  .word     Default_Handler     /* CAN1 RX0 */
  .word     Default_Handler     /* CAN1 RX1 */
  .word     Default_Handler     /* CAN1 SCE */
  .word     Default_Handler     /* External Line[9:5]s */
  .word     Default_Handler     /* TIM1 Break and TIM9 */
  .word     Default_Handler     /* TIM1 Update and TIM10 */
  .word     Default_Handler     /* TIM1 Trigger and Commutation and TIM11 */
  .word     Default_Handler     /* TIM1 Capture Compare */
  .word     Default_Handler     /* TIM2 */
  .word     Default_Handler     /* TIM3 */
  .word     Default_Handler     /* TIM4 */
  .word     Default_Handler     /* I2C1 Event */
  .word     Default_Handler     /* I2C1 Error */
  .word     Default_Handler     /* I2C2 Event */
  .word     Default_Handler     /* I2C2 Error */
  .word     Default_Handler     /* SPI1 */
  .word     Default_Handler     /* SPI2 */
  .word     Default_Handler     /* USART1 */
  .word     Default_Handler     /* USART2 */
  .word     Default_Handler     /* USART3 */
  .word     Default_Handler     /* External Line[15:10]s */
  .word     Default_Handler     /* RTC Alarm (A and B) through EXTI Line */
  .word     Default_Handler     /* USB OTG FS Wakeup through EXTI line */
  .word     Default_Handler     /* TIM8 Break and TIM12 */
  .word     Default_Handler     /* TIM8 Update and TIM13 */
  .word     Default_Handler     /* TIM8 Trigger and Commutation and TIM14 */
  .word     Default_Handler     /* TIM8 Capture Compare */
  .word     Default_Handler     /* DMA1 Stream7 */
  .word     Default_Handler     /* FSMC */
  .word     Default_Handler     /* SDIO */
  .word     Default_Handler     /* TIM5 */
  .word     Default_Handler     /* SPI3 */
  .word     Default_Handler     /* UART4 */
  .word     Default_Handler     /* UART5 */
  .word     Default_Handler     /* TIM6 and DAC1&2 underrun errors */
  .word     Default_Handler     /* TIM7 */
  .word     Default_Handler     /* DMA2 Stream 0 */
  .word     Default_Handler     /* DMA2 Stream 1 */
  .word     Default_Handler     /* DMA2 Stream 2 */
  .word     Default_Handler     /* DMA2 Stream 3 */
  .word     Default_Handler     /* DMA2 Stream 4 */
  .word     Default_Handler     /* Ethernet */
  .word     Default_Handler     /* Ethernet Wakeup through EXTI line */
  .word     Default_Handler     /* CAN2 TX */
  .word     Default_Handler     /* CAN2 RX0 */
  .word     Default_Handler     /* CAN2 RX1 */
  .word     Default_Handler     /* CAN2 SCE */
  .word     Default_Handler     /* USB OTG FS */
  .word     Default_Handler     /* DMA2 Stream 5 */
  .word     Default_Handler     /* DMA2 Stream 6 */
  .word     Default_Handler     /* DMA2 Stream 7 */
  .word     Default_Handler     /* USART6 */
  .word     Default_Handler     /* I2C3 event */
  .word     Default_Handler     /* I2C3 error */
  .word     Default_Handler     /* USB OTG HS End Point 1 Out */
  .word     Default_Handler     /* USB OTG HS End Point 1 In */
  .word     Default_Handler     /* USB OTG HS Wakeup through EXTI */
  .word     Default_Handler     /* USB OTG HS */
  .word     Default_Handler     /* DCMI */
  .word     Default_Handler     /* CRYP crypto */
  .word     Default_Handler     /* Hash and Rng */
  .word     Default_Handler     /* FPU */


/*******************   (C)   COPYRIGHT   2011   STMicroelectronics   *****END   OF   FILE****/
