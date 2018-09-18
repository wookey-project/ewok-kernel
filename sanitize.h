/* \file sanitize.h
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

#ifndef SANITIZE_H_
#define SANITIZE_H_

#include "exported/dmas.h"
#include "tasks-shared.h"
#include "tasks.h"
#include "kernel.h"

/**************************************************************
 * About task slotting
 **************************************************************/

/*!
 * @brief return true if the pointer target a scalar value in task RAM slot
 * @param[in] ptr 32 bits data pointer
 * @param[in] t associated user task kernel structure 
 * @param[in] mode task mode at syscall time
 *
 * @return true if ptr point to an address in the RAM slot of the task
 */
bool sanitize_is_pointer_in_slot(__user void      *ptr,
                                 __user e_task_id  caller,
                                 e_task_mode       mode);

/*!
 * @brief return true if the pointer target a scalar value in task .text or .rodata slot
 * @param[in] ptr 32 bits data pointer
 * @param[in] t associated user task kernel structure 
 *
 * @return true if ptr point to an address in the .text or .rodata section of the task
 */
bool sanitize_is_pointer_in_txt_slot(__user void      *ptr,
                                     __user e_task_id  caller);

/*!
 * @brief return true if the pointer target a scalar value in any task slots
 * @param[in] ptr 32 bits data pointer
 * @param[in] t associated user task kernel structure 
 * @param[in] mode task mode at syscall time
 *
 * @return true if ptr point to an address in any (RAM, .text or .rodata) sections of the task
 */
bool sanitize_is_data_pointer_in_any_slot(__user void     *ptr,
                                          __user uint32_t  size,
                                          __user e_task_id caller,
                                          e_task_mode      mode);

/*!
 * @brief return true if the pointer target a structured value in task RAM slot
 * @param[in] ptr the data pointer
 * @param[in] size the size of the pointed content
 * @param[in] t associated user task kernel structure 
 * @param[in] mode task mode at syscall time
 *
 * @return true if ptr point to an address in the RAM slot of the task
 */
bool sanitize_is_data_pointer_in_slot(__user void      *ptr,
                                      __user uint32_t   size,
                                      __user e_task_id  caller,
                                      e_task_mode       mode);

/*!
 * @brief return true if the pointer target a structured value in task .text or .rodata slot
 * @param[in] ptr 32 bits data pointer
 * @param[in] size the size of the pointed content
 * @param[in] t associated user task kernel structure 
 *
 * @return true if ptr point to an address in the .text or .rodata section of the task
 */
bool sanitize_is_data_pointer_in_txt_slot(__user void      *ptr,
                                          __user uint32_t   size,
                                          __user e_task_id  caller);

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
                                         __user e_task_id           caller);

#endif
