/* perm.c
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

#include "regutils.h"
#include "perm.h"
#include "tasks.h"
#include "gen_perms.h"
#include "debug.h"

/*
 * These defines are not used by now (they require the usage of a
 * macro construction, which impact the perm.h interface.
 *
 * The goal here is to keep the perm.h API as much generic and
 * substituable as possible, avoiding any side impact of the
 * perm internals
 *
 * The Ressource register is fully described in EwoK Sphinx documentation
 * See EwoK API>Permissions for more informations
 */
#define PERM_RES_DEV_DMA_Pos     31
#define PERM_RES_DEV_DMA_Msk     ((uint32_t)1 << PERM_RES_DEV_DMA_Pos)

#define PERM_RES_DEV_CRYPTO_Pos  29
#define PERM_RES_DEV_CRYPTO_Msk  ((uint32_t)3 << PERM_RES_DEV_CRYPTO_Pos)

#define PERM_RES_DEV_BUSES_Pos   28
#define PERM_RES_DEV_BUSES_Msk   ((uint32_t)1 << PERM_RES_DEV_BUSES_Pos)

#define PERM_RES_DEV_EXTI_Pos    27
#define PERM_RES_DEV_EXTI_Msk    ((uint32_t)1 << PERM_RES_DEV_EXTI_Pos)

#define PERM_RES_DEV_TIM_Pos     26
#define PERM_RES_DEV_TIM_Msk     ((uint32_t)1 << PERM_RES_DEV_TIM_Pos)

#define PERM_RES_TIM_GETCYCLES_Pos 22
#define PERM_RES_TIM_GETCYCLES_Msk ((uint32_t)3 << PERM_RES_TIM_GETCYCLES_Pos)

#define PERM_RES_TSK_FISR_Pos    15
#define PERM_RES_TSK_FISR_Msk    ((uint32_t)1 << PERM_RES_TSK_FISR_Pos)

#define PERM_RES_TSK_FIPC_Pos    14
#define PERM_RES_TSK_FIPC_Msk    ((uint32_t)1 << PERM_RES_TSK_FIPC_Pos)

#define PERM_RES_TSK_RESET_Pos    13
#define PERM_RES_TSK_RESET_Msk    ((uint32_t)1 << PERM_RES_TSK_RST_Pos)

#define PERM_RES_TSK_UPGRADE_Pos    12
#define PERM_RES_TSK_UPGRADE_Msk    ((uint32_t)1 << PERM_RES_TSK_UPG_Pos)

#define PERM_RES_MEM_DYNAMIC_MAP_Pos    7
#define PERM_RES_MEM_DYNAMIC_MAP_Msk    ((uint32_t)1 << PERM_RES_TSK_FIPC_Pos)

static ressource_reg_t perm_get_ressource_register(e_task_id task_identifier)
{
    /*
     * In C, table rows start with 0. EwoK id start with 1, 
     * we need to decrement id in consequence
     */
    return ressource_perm_tab[task_identifier - 1];

}

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
                            e_task_id to)
{
    /*
     * In C, table rows start with 0. EwoK id start with 1, 
     * we need to decrement id in consequence
     */
    return com_dmashm_perm[from - 1][to - 1];
}

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
                         e_task_id to)
{
    /*
     * In C, table rows start with 0. EwoK id start with 1, 
     * we need to decrement id in consequence
     */
    return com_ipc_perm[from - 1][to - 1];
}


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
                               e_task_id   task_id)
{
    uint32_t field = 0;
    uint32_t perm = 0;
    uint8_t field_pos;
    uint32_t field_mask;
    ressource_reg_t reg = perm_get_ressource_register(task_id);

    /*
     * Here we use a 'naive' switch/case instead of human-optimized code
     * or thing like res_perm_t indiced table to get back the permission
     * field based on the permission enumerate
     *
     * This permit to:
     * - avoid using .data content
     * - let the compiler optimize this simple implementation
     * - keep the code as much readable as possible
     *
     * Using a permission enumerate (without any bitfield consideration)
     * also permit to support new permissions and bit field order replacement
     * without impact on the perm API.
     *
     * This is also an advantage to keep a compatible API with the perm Ada
     * code, which does not use a bitfield but a complete Ada record for the
     * ressource register.
     */
    switch (perm_name) {
        /* Device specific permissions */
        case PERM_RES_DEV_DMA:
            perm = (uint32_t)1 << 31;
            field_mask = (uint32_t)1 << 31;
            field_pos = 31;
            break;
        case PERM_RES_DEV_CRYPTO_CFG:
            perm = (uint32_t)2 << 29;
            field_mask = (uint32_t)3 << 29;
            field_pos = 29;
            break;
        case PERM_RES_DEV_CRYPTO_USR:
            perm = (uint32_t)1 << 29;
            field_mask = (uint32_t)3 << 29;
            field_pos = 29;
            break;
        case PERM_RES_DEV_CRYPTO_FULL:
            perm = (uint32_t)3 << 29;
            field_mask = (uint32_t)3 << 29;
            field_pos = 29;
            break;
        case PERM_RES_DEV_BUSES:
            perm = (uint32_t)1 << 28;
            field_mask = (uint32_t)1 << 28;
            field_pos = 28;
            break;
        case PERM_RES_DEV_EXTI:
            perm = (uint32_t)1 << 27;
            field_mask = (uint32_t)1 << 27;
            field_pos = 27;
            break;
        case PERM_RES_DEV_TIM:
            perm = (uint32_t)1 << 26;
            field_mask = (uint32_t)1 << 26;
            field_pos = 26;
            break;
        /* Time specific permissions */
        case PERM_RES_TIM_GETMILLI:
            perm = (uint32_t)1 << 22;
            field_mask = (uint32_t)1 << 22;
            field_pos = 22;
            break;
        case PERM_RES_TIM_GETMICRO:
            perm = (uint32_t)1 << 23;
            field_mask = (uint32_t)1 << 23;
            field_pos = 23;
            break;
        case PERM_RES_TIM_GETCYCLE:
            perm = (uint32_t)3 << 22;
            field_mask = (uint32_t)3 << 22;
            field_pos = 22;
            break;
        /* Task specific permissions */
        case PERM_RES_TSK_FISR:
            perm = (uint32_t)1 << 15;
            field_mask = (uint32_t)1 << 15;
            field_pos = 15;
            break;
        case PERM_RES_TSK_FIPC:
            perm = (uint32_t)1 << 14;
            field_mask = (uint32_t)1 << 14;
            field_pos = 14;
            break;
        case PERM_RES_TSK_RESET:
            perm = (uint32_t)1 << 13;
            field_mask = (uint32_t)1 << 13;
            field_pos = 13;
            break;
        case PERM_RES_TSK_UPGRADE:
            perm = (uint32_t)1 << 12;
            field_mask = (uint32_t)1 << 12;
            field_pos = 12;
            break;
        case PERM_RES_MEM_DYNAMIC_MAP:
            perm = (uint32_t)1 << 7;
            field_mask = (uint32_t)1 << 7;
            field_pos = 7;
            break;
        default:
            return false;
            break;
    }

    field = get_reg_value(&reg, field_mask, field_pos);
    if (field == (perm >> field_pos)) {
        return true;
    }
    return false;
}


#ifdef CONFIG_KERNEL_DOMAIN
/**
 * \brief test if two tasks are in the same security domain
 *
 * \param[in] from first task which want to communicate
 * \param[in] to   target of the first task IPC
 *
 * \return true if the tasks are in the same domain, or false
 */
bool perm_same_ipc_domain(e_task_id src, e_task_id dst)
{
    if (src == ANY_APP || dst == ANY_APP) {
        return true;
    }
    task_t* tasks_list = task_get_tasks_list();
    if (tasks_list[src].domain == tasks_list[dst].domain) {
        return true;
    }
    return false;
}
#endif

