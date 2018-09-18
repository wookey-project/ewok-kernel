/* \file irq.h
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
#ifndef KERNEL_IRQ_H
#define KERNEL_IRQ_H

/* Max number of post IRQ hooks */
#define DEV_MAX_PH_INSTR 10

/**
 ** \brief type of posthook the kernel can manage at interrupt time
 ** before the ISR is being executed. Be carefull that this may
 ** impact the device state. The kernel can give back one of the
 ** registers back to the ISR using the status argument of the ISR.
 */
typedef enum {
    IRQ_PH_NIL = 0,   /**< No action */
    IRQ_PH_READ,      /**< Read a value from a register */
    IRQ_PH_WRITE,     /**< Write a value in a regiser */
    IRQ_PH_AND,       /**< Read a register, apply a bitwise AND operation
                       **  and write the result in a register */
    IRQ_PH_MASK       /**< Read a register, write it to another one, using a
                       ** third register as write mask */
} dev_irq_ph_action_t;

typedef struct {
    uint16_t  offset;  /**< Offset of the register to read */
    uint32_t  value;   /**< Value read */
} dev_irq_ph_read_t;

/**
 ** \brief when asking to write a given register, a write mask is probably
 ** needed. The write table is based on write offset/write mask
 */
typedef struct {
    uint16_t  offset;  /**< Offset of the register to write */
    uint32_t  value;   /**< Value to write */
    uint32_t  mask;    /**< Associated write mask */
} dev_irq_ph_write_t;

typedef struct {
    uint16_t    offset_dest; /**< Offset of the register to write */
    uint16_t    offset_src;  /**< Offset of the register with the mask */
    uint32_t    mask;        /**< The masking value */
    uint8_t     mode;
} dev_irq_ph_and_t;

typedef struct {
    uint16_t    offset_dest;  /**< The offset of the register to write */
    uint16_t    offset_src;   /**< The offset of the register to use as value */
    uint16_t    offset_mask;  /**< The offset of the tregister to use as mask */
    uint8_t     mode;
} dev_irq_ph_mask_t;

#define MODE_STANDARD  0 /**< val = val   */
#define MODE_NOT       1 /**< val = ~val  */

typedef struct {
    dev_irq_ph_action_t     instr;
    union {
        dev_irq_ph_read_t   read;
        dev_irq_ph_write_t  write;
        dev_irq_ph_and_t    and;
        dev_irq_ph_mask_t   mask;
    };
} dev_irq_ph_instruction_t;

/**
 ** \brief this is the IRQ post-hook structure
 ** This permit to declare to the kernel what can be done at IRQ time to
 ** avoid IRQ burst or any other invalid behavior from devices.
 */
typedef struct {
    /** The posthook identifier */
    dev_irq_ph_instruction_t  action[DEV_MAX_PH_INSTR];

    /** From which register the status is read ? */
    uint16_t  status;

    /** From which register the data is read ? */
    uint16_t  data;
} dev_irq_ph_t;

/**
 ** \brief Impact of the ISR on the main thread execution
 */
typedef enum {
    /** ISR awakes the main tread but has no impact on scheduler policy */
    IRQ_ISR_STANDARD = 0,
    /** ISR ask for a single, forced execution of its main thread */
    IRQ_ISR_FORCE_MAINTHREAD = 1,
    /** ISR doesn't awake the main thread (use case without main thread or idle
     ** main thread) */
    IRQ_ISR_WITHOUT_MAINTHREAD = 2,
} dev_irq_isr_scheduling_t;

/**
 *  \brief This is the IRQ handler informational structure for user drivers
 *
 *  A device may require one or more interrupt handlers. If yes, this
 *  structure must be fullfill for each interrupt by the userspace.
 *  The kernel will do the corresponding work to execute the handler
 *  when the corresponding IRQ rise. Yet, the handler will be executed:
 *  - with the user task's privileges
 *  - in thread mode (preemptible by HW interrupts)
 *  - with the corresponding device (and only this one) mapped
 */
typedef struct {
    /**< The IRQ handler. Will be executed with its own stack.
     *   This handler will have access to the stack content (variables,
     *   functions, etc.) but can't modify the task's context (task's
     *   main thread stack or processor state).
     *   By now, user IRQ hanler can't execute syscalls. This is due to
     *   the fact that syscalls require context switch which may lead to
     *   the execution of another ISR, which will delete the current ISR
     *   stack (the physical memory of the stack is shared between ISR).
     *   As a consequence, any syscall will return SYS_E_DENIED. Please
     *   interact with your task and let it do the syscalls after instead.
     *   The handler address is checked. It must be own by the task.
     */
    user_handler_t handler;

    /**< The IRQ number associated to the handler.
     *   This is the real IRQ number as if the ISR was directly executed in
     *   kernel mode. Yet the kernel will manage the IRQ/FIQ mode and the ISR
     *   will be delayed in thread mode, where it can be preempted by FIQ/IRQ.
     *   The IRQ number must correspond to an existing SoC device allowed by
     *   the kernel.
     */
    uint8_t irq;

    /**< Type of post-ISR impact, see dev_irq_isr_scheduling_t description */
    dev_irq_isr_scheduling_t mode;

    /**< Most of IRQ-based devices require small actions in handler
     *   mode, to avoid IT burst. This posthook permit to ask the kernel
     *   to execute some basic action on the device registers to clean
     *   the interrupt or read the status registers.
     *   These action must be on offsets (starting at device base address)
     *   into the device's user-mapped address (i.e. the userspace would
     *   have been able to do the same in its ISR).
     */
    dev_irq_ph_t posthook;
} dev_irq_info_t;

#endif
