/* \file perm.h
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

#ifndef PERM_H_
#define PERM_H_

#include "types.h"
#include "tasks.h"

typedef enum {
    PERM_RES_DEV_DMA,
    PERM_RES_DEV_CRYPTO_USR,
    PERM_RES_DEV_CRYPTO_CFG,
    PERM_RES_DEV_CRYPTO_FULL,
    PERM_RES_DEV_BUSES,
    PERM_RES_DEV_EXTI,
    PERM_RES_DEV_TIM,
    PERM_RES_TIM_GETMILLI,
    PERM_RES_TIM_GETMICRO,
    PERM_RES_TIM_GETCYCLE,
    PERM_RES_TSK_FISR,
    PERM_RES_TSK_FIPC,
    PERM_RES_TSK_RESET,
    PERM_RES_TSK_UPGRADE,
    PERM_RES_MEM_DYNAMIC_MAP
} res_perm_t;


/**
 * \brief test if a task is allow to declare a DMA SHM with another task
 *
 * Here we are based on a symetric paradigm (i.e. when a
 * task is allowed to declare a DMA SHM with another task, the other
 * task is allowed to host a DMA SHM from it). Nonetheless it
 * is still an half duplex communication channel (DMA SHM are
 * read-only or write-only, accessible only by the DMA controler
 * and never mapped into the task memory slot).
 *
 * \param[in] from the task which want to declare a DMA SHM
 * \param[in] tto  the task target of the DMA SHM peering
 *
 * \return true if the permission is granted, of false
 *
 */
bool perm_dmashm_is_granted(e_task_id from,
                            e_task_id to);

/**
 * \brief test if a task is allow to send an IPC to another task
 *
 * Here we are based on a symetric paradigm (i.e. when a
 * task is allowed to send an IPC to another task, the other
 * task is allowed to receive an IPC from it). Nonetheless it
 * is still an half duplex communication channel.
 *
 * \param[in] from the task which want to send an IPC data
 * \param[in] tto  the task target of the IPC
 *
 * \return true if the permission is granted, of false
 *
 */
bool perm_ipc_is_granted(e_task_id from,
                         e_task_id to);

/**
 * \brief test if the ressource is allowed for the task
 *
 * A typical example of such an API is the following:
 * if (!perm_ressource_is_granted(PERM_RES_DEV_DMA, mytask)) {
 *     goto ret_denied;
 * }
 *
 * \param[in] perm_name the name of the permission
 * \param[in] task the task requiring the permission
 *
 * \return true if the permission is granted, of false
 *
 */
bool perm_ressource_is_granted(res_perm_t  perm_name,
                               e_task_id   task_id);


#ifdef CONFIG_KERNEL_DOMAIN
/**
 * \brief test if two tasks are in the same security domain
 *
 * \param[in] from first task which want to communicate
 * \param[in] to   target of the first task IPC
 *
 * \return true if the tasks are in the same domain, or false
 */
bool perm_same_ipc_domain(e_task_id      src,
                          e_task_id      dst);
#endif

#endif                          /*!PERM_H_ */
