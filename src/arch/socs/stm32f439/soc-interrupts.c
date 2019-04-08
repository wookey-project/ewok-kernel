/* \file soc-interrupts.h
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
#include "m4-systick.h"
#include "m4-core.h"
#include "soc-interrupts.h"
#include "soc-dwt.h"
#include "soc-nvic.h"
#include "soc-scb.h"
#include "devices-shared.h"
#include "debug.h"
#include "kernel.h"
#include "isr.h"
#include "default_handlers.h"

#ifdef KERNEL
#include "tasks.h"
#include "sched.h"
#include "layout.h"
#endif

/*
** Default IRQ mapping. This permit to each handler to detect
** if the effective IRQ handling has to be executed by a userspace task that
** have registered the IRQ as its own. If yes, the handler must:
** 1) update the memory mapping to be conform to the task memory mapping constraints
** 2) Change mode to usermode and execute fn
** 3) when coming back from fn, reloading the kernel memory map
**
** Some handlers are set here to be correctly set at boot time (e.g. Systick handler)
*/
static s_irq irq_table[] = {
    // ARM VTORS start with reset Stack (MSP)
    {ESTACK,        { NULL },     ID_UNUSED, ID_DEV_UNUSED, 0},
    // Should never be called from here
    {RESET_IRQ,     { NULL },     ID_UNUSED, ID_DEV_UNUSED, 0},
    {NMI_IRQ,       { NULL },     ID_UNUSED, ID_DEV_UNUSED, 0},
    {HARDFAULT_IRQ, { HardFault_Handler },  ID_UNUSED, ID_DEV_UNUSED, 0},
    {MEMMANAGE_IRQ, { NULL },     ID_UNUSED, ID_DEV_UNUSED, 0},
    {BUSFAULT_IRQ,  { NULL },     ID_UNUSED, ID_DEV_UNUSED, 0},
    {USAGEFAULT_IRQ, { NULL },    ID_UNUSED, ID_DEV_UNUSED, 0},
    {VOID1_IRQ,     { NULL },     ID_UNUSED, ID_DEV_UNUSED, 0},
    {VOID2_IRQ,     { NULL },     ID_UNUSED, ID_DEV_UNUSED, 0},
    {VOID3_IRQ,     { NULL },     ID_UNUSED, ID_DEV_UNUSED, 0},
    {VOID4_IRQ,     { NULL },     ID_UNUSED, ID_DEV_UNUSED, 0},
    {SVC_IRQ,       { NULL },     ID_UNUSED, ID_DEV_UNUSED, 0},
    {DEBUGON_IRQ,   { NULL },     ID_UNUSED, ID_DEV_UNUSED, 0},
    {VOID5_IRQ,     { NULL },     ID_UNUSED, ID_DEV_UNUSED, 0},
    {PENDSV_IRQ,    { NULL },     ID_UNUSED, ID_DEV_UNUSED, 0},
    {SYSTICK_IRQ,   { core_systick_handler },  ID_UNUSED, ID_DEV_UNUSED, 0},
    {WWDG_IRQ,      { WWDG_IRQ_Handler },   ID_UNUSED, ID_DEV_UNUSED, 0},  // 0x10
    {PVD_IRQ,           { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {TAMP_STAMP_IRQ,    { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {RTC_WKUP_IRQ,      { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {FLASH_IRQ,         { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {RCC_IRQ,           { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {EXTI0_IRQ,         { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {EXTI1_IRQ,         { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {EXTI2_IRQ,         { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {EXTI3_IRQ,         { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {EXTI4_IRQ,         { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {DMA1_Stream0_IRQ,  { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {DMA1_Stream1_IRQ,  { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {DMA1_Stream2_IRQ,  { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {DMA1_Stream3_IRQ,  { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {DMA1_Stream4_IRQ,  { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {DMA1_Stream5_IRQ,  { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},      // 0x20
    {DMA1_Stream6_IRQ,  { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {ADC_IRQ,           { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {CAN1_TX_IRQ,       { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {CAN1_RX0_IRQ,      { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {CAN1_RX1_IRQ,      { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {CAN1_SCE_IRQ,      { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {EXTI9_5_IRQ,       { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {TIM1_BRK_TIM9_IRQ, { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {TIM1_UP_TIM10_IRQ, { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {TIM1_TRG_COM_TIM11_IRQ, { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {TIM1_CC_IRQ,       { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {TIM2_IRQ,          { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {TIM3_IRQ,          { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {TIM4_IRQ,          { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {I2C1_EV_IRQ,       { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {I2C1_ER_IRQ,       { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},           // 0x30
    {I2C2_EV_IRQ,       { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {I2C2_ER_IRQ,       { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {SPI1_IRQ,          { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {SPI2_IRQ,          { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {USART1_IRQ,        { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {USART2_IRQ,        { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {USART3_IRQ,        { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {EXTI15_10_IRQ,     { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {RTC_Alarm_IRQ,     { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {OTG_FS_WKUP_IRQ,   { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {TIM8_BRK_TIM12_IRQ,{ NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {TIM8_UP_TIM13_IRQ, { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {TIM8_TRG_COM_TIM14_IRQ, { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {TIM8_CC_IRQ,       { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {DMA1_Stream7_IRQ,  { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {FSMC_IRQ,          { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},              // 0x40
    {SDIO_IRQ,          { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {TIM5_IRQ,          { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {SPI3_IRQ,          { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {UART4_IRQ,         { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {UART5_IRQ,         { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {TIM6_DAC_IRQ,      { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {TIM7_IRQ,          { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {DMA2_Stream0_IRQ,  { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {DMA2_Stream1_IRQ,  { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {DMA2_Stream2_IRQ,  { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {DMA2_Stream3_IRQ,  { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {DMA2_Stream4_IRQ,  { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {ETH_IRQ,           { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {ETH_WKUP_IRQ,      { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {CAN2_TX_IRQ,       { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {CAN2_RX0_IRQ,      { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},          // 0x50
    {CAN2_RX1_IRQ,      { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {CAN2_SCE_IRQ,      { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {OTG_FS_IRQ,        { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {DMA2_Stream5_IRQ,  { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {DMA2_Stream6_IRQ,  { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {DMA2_Stream7_IRQ,  { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {USART6_IRQ,        { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {I2C3_EV_IRQ,       { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {I2C3_ER_IRQ,       { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {OTG_HS_EP1_OUT_IRQ,{ NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {OTG_HS_EP1_IN_IRQ, { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {OTG_HS_WKUP_IRQ,   { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {OTG_HS_IRQ,        { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {DCMI_IRQ,          { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {CRYP_IRQ,          { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
    {HASH_RNG_IRQ,      { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},          // 0x60
    {FPU_IRQ,           { NULL }, ID_UNUSED, ID_DEV_UNUSED, 0},
};

bool is_interrupt_already_used (e_irq_id id)
{
    if (irq_table[id].task_id != ID_UNUSED) {
        return true;
    } else {
        return false;
    }
}

uint8_t clear_interrupt_handler(e_irq_id id)
{
    irq_table[id].handler.synchronous_handler       = 0;
    irq_table[id].task_id       = ID_UNUSED;
    irq_table[id].device_id     = ID_DEV_UNUSED;
    return 0;
}

/*
** Register a custom handler for a given interrupt
*/
uint8_t set_interrupt_handler
    (e_irq_id id, const void *irq_handler, e_task_id task_id, e_device_id dev_id)
{
    if (irq_handler == NULL) {
        return 1;
    }

    if (irq_table[id].handler.synchronous_handler || irq_table[id].handler.postponed_handler != NULL) {
        KERNLOG(DBG_DEBUG, "INT %d irq_handler_set(): replacing an existing handler (%x) by a new handler in %x\n",
            id, irq_table[id].handler.synchronous_handler, irq_handler);
        dbg_flush();
    }

    /* Registering task's handler */
    if (task_id == 0) {
        /* registering kernel hanlder */
       irq_table[id].handler.synchronous_handler       = irq_handler;
    } else {
        /* or usersapce handler */
       irq_table[id].handler.postponed_handler         = irq_handler;
    }
    irq_table[id].task_id       = task_id;
    irq_table[id].device_id     = dev_id;

    return 0;
}

e_device_id get_device_from_interrupt(e_irq_id id)
{
    return irq_table[id].device_id;
}

s_irq* get_cell_from_interrupt(e_irq_id id)
{
    return &irq_table[id];
}

