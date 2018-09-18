/* sanitize.c
 *
 * Copyright (C) 2018 ANSSI
 * All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the BSD license.  See the LICENSE file for details.
 */

#include "types.h"
#include "sanitize.h"
#include "tasks.h"
#include "autoconf.h"
#include "layout.h"

/*
 * FIXME: add isr stack slotting in task_t struct
 */

/**
 * @file sanitize.c
 * @brief Generic data sanitation for user entries
 *
** This file implements the generic input sanitation for syscalls.
** It does not perform structure content check (logical values for
** device_t or dma_t for example), but verify that pointers, string
** or identifiers are valid in term of memory mapping, to avoid any
** invalid kernel memory access or memory access from one task slot
** to another
*/

/**************************************************************
 * About task slotting
 **************************************************************/

/*!
 * @brief return true if the pointer target a scalar value in task RAM slot
 * @param[in] ptr 32 bits data pointer
 * @param[in] t associated user task kernel structure 
 *
 * @return true if ptr point to an address in the RAM slot of the task
 */
bool sanitize_is_pointer_in_slot(__user void   *ptr,
                                 e_task_id      caller,
                                 e_task_mode    mode)
{

    const task_t *t = task_get_task(caller);
    if ((physaddr_t) ptr >= t->ram_slot_start
        && (physaddr_t) ptr + 4 <= t->ram_slot_end) {
        return true;
    } else if (mode == TASK_MODE_ISRTHREAD) {
        if (   (physaddr_t) ptr >= (STACK_TOP_ISR - STACK_SIZE_ISR)
            && (physaddr_t) ptr < STACK_TOP_ISR) {
            return true;
        }
    }
    return false;
}

/*!
 * @brief return true if the pointer target a scalar value in task .text or .rodata slot
 * @param[in] ptr 32 bits data pointer
 * @param[in] t associated user task kernel structure 
 *
 * @return true if ptr point to an address in the .text or .rodata section of the task
 */
bool sanitize_is_pointer_in_txt_slot(__user void       *ptr,
                                            e_task_id   caller)
{
    const task_t *t = task_get_task(caller);
    if ((physaddr_t) ptr >= t->txt_slot_start
        && (physaddr_t) ptr + 4 <= t->txt_slot_end) {
        return true;
    }
    return false;
}

/*!
 * @brief return true if the pointer target a scalar value in any task slots
 * @param[in] ptr 32 bits data pointer
 * @param[in] t associated user task kernel structure 
 *
 * @return true if ptr point to an address in any (RAM, .text or .rodata) sections of the task
 */
bool sanitize_is_data_pointer_in_any_slot(__user void     *ptr,
                                          __user uint32_t  size,
                                          __user e_task_id caller,
                                          e_task_mode      mode)
{
    if (   sanitize_is_data_pointer_in_slot(ptr, size, caller, mode)
        || sanitize_is_data_pointer_in_txt_slot(ptr, size, caller))
    {
        return true;
    } else if (mode == TASK_MODE_ISRTHREAD) {
        if (   (physaddr_t) ptr >= (STACK_TOP_ISR - STACK_SIZE_ISR)
                && (physaddr_t) ptr < STACK_TOP_ISR) {
            return true;
        }
    }
    return false;
}

/*!
 * @brief return true if the pointer target a structured value in task RAM slot
 * @param[in] ptr the data pointer
 * @param[in] size the size of the pointed content
 * @param[in] t associated user task kernel structure 
 *
 * @return true if ptr point to an address in the RAM slot of the task
 */
bool sanitize_is_data_pointer_in_slot(__user void      *ptr,
                                      __user uint32_t   size,
                                      __user e_task_id  caller,
                                      e_task_mode       mode)
{
    const task_t *t = task_get_task(caller);
    if ((physaddr_t) ptr >= t->ram_slot_start
        && (physaddr_t) ptr + size >= (physaddr_t) ptr
        && (physaddr_t) ptr + size <= t->ram_slot_end) {
        return true;
    } else if (mode == TASK_MODE_ISRTHREAD) {
        if (   (physaddr_t) ptr >= (STACK_TOP_ISR - STACK_SIZE_ISR)
                && (physaddr_t) ptr < STACK_TOP_ISR) {
            return true;
        }
    }
    return false;
}

/*!
 * @brief return true if the pointer target a structured value in task .text or .rodata slot
 * @param[in] ptr 32 bits data pointer
 * @param[in] size the size of the pointed content
 * @param[in] t associated user task kernel structure 
 *
 * @return true if ptr point to an address in the .text or .rodata section of the task
 */
bool sanitize_is_data_pointer_in_txt_slot(__user void     *ptr,
                                          __user uint32_t  size,
                                          __user e_task_id caller)
{
    const task_t *t = task_get_task(caller);
    if ((physaddr_t) ptr >= t->txt_slot_start
        && (physaddr_t) ptr + size >= (physaddr_t) ptr
        && (physaddr_t) ptr + size <= t->txt_slot_end) {
        return true;
    }
    return false;
}

/**************************************************************
 * About DMA slotting
 **************************************************************/

/*!
 * @brief Check that a pointer, associated to a size pointed, targets a DMA SHM region of the task
 * @param[in] ptr a DMA buffer pointer
 * @param[in] size the size of the DMA buffer
 * @param[in] mode (dma RO/RW)
 * @param[in] t associated user task kernel structure 
 *
 * @return true if ptr point to a valid shared DMA buffer, allowed as a source for DMA transactions
 */
bool sanitize_is_data_pointer_in_dma_shm(__user void               *ptr,
                                         __user uint32_t            size,
                                         __user dma_shm_access_t    mode,
                                         __user e_task_id           caller)
{
    const task_t *t = task_get_task(caller);
    for (uint8_t i = 0; i < t->num_dma_shms; ++i) {
        if (t->dma_shm[i].mode == mode &&
            (physaddr_t) ptr >= t->dma_shm[i].address &&
            (physaddr_t) ptr + size >= (physaddr_t) ptr &&
            (physaddr_t) ptr + size <= (t->dma_shm[i].address + t->dma_shm[i].size)) {
            return true;
        }
    }
    return false;
}

