/* \file syscalls-ipc.c
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

#include "libc.h"
#include "syscalls.h"
#include "tasks.h"
#include "softirq.h"
#include "ipc.h"
#include "sched.h"
#include "perm.h"
#include "sanitize.h"
#include "debug.h"
#include "sleep.h"


void ipc_do_recv(task_t *caller, __user regval_t *regs, bool blocking, e_task_mode mode) {
    ipc_endpoint_t *ep      = NULL;
    task_t         *sender  = NULL;

    /* Sender id. That field is mandatory to know who is the sender.
     * The 'id_sender' is thus also used to inform the receiver about who sent
     * a message in the case where the receiver was listening to any task.  */
    e_task_id      *id_sender = (e_task_id *) regs[1];

    /* Pointer to buffer size. Also used to return the number of bytes written
     * by the sender. */
    logsize_t       *size = (logsize_t *) regs[2];

    /* Buffer address */
    char           *buf = (char *)regs[3];

    /* Debug */
    KERNLOG(DBG_DEBUG,
        "DEBUG: ipc_do_recv() task %d <- task %d\n", caller->id, *id_sender);

    /***********************
     * Verifying parameters
     ***********************/

    if (mode == TASK_MODE_ISRTHREAD) {
        KERNLOG(DBG_ERR, "[task %d] ipc_do_recv(): making IPCs while in ISR mode is not allowed!\n", caller->id);
        goto ret_denied;
    }

    /* Test if task initialization is complete */
    if (caller->init_done == false) {
        KERNLOG(DBG_ERR,
            "[task %d] ipc_do_recv(): initialization not completed\n", caller->id);
        goto ret_denied;
    }

    /* Verifying &size is in caller address space */
    if (!sanitize_is_pointer_in_slot((void *)size, caller->id, mode)) {
        KERNLOG(DBG_ERR,
            "[task %d] ipc_do_recv(): size (%x) is not in caller space\n", caller->id, size);
        goto ret_inval;
    }

    /* Verifying &id_sender is in caller address space */
    if (!sanitize_is_pointer_in_slot((void *)id_sender, caller->id, mode)) {
        KERNLOG(DBG_ERR,
            "[task %d] ipc_do_recv(): id_sender (%x) is not in caller space\n", caller->id, id_sender);
        goto ret_inval;
    }

    /* Verifying that the id corresponds to a user task */
    if (!task_is_user(*id_sender) && *id_sender != ANY_APP) {
        KERNLOG(DBG_ERR,
            "[task %d] ipc_do_recv(): invalid id_sender (%d)\n", caller->id, *id_sender);
        goto ret_inval;
    }

    if (*id_sender != ANY_APP) {
        sender = task_get_task(*id_sender);
        if (sender == NULL ||
            sender->state[TASK_MODE_MAINTHREAD] == TASK_STATE_EMPTY) {
            KERNLOG(DBG_ERR,
                "[task %d] ipc_do_recv(): invalid sender (%d) - empty task\n", caller->id, *id_sender);
            goto ret_inval;
        }
    }

    /* A task can't send a message to itself */
    if (caller->id == *id_sender) {
        KERNLOG(DBG_ERR,
            "[task %d] ipc_do_recv(): invalid id_sender (%d) - same as caller->id\n", caller->id, *id_sender);
        goto ret_inval;
    }

    /*
     * Verifying permissions
     */

    if (*id_sender != ANY_APP) {

#ifdef CONFIG_KERNEL_DOMAIN
	    if (!perm_same_ipc_domain(*id_sender, caller->id)) {
	        KERNLOG(DBG_ERR,
	            "[task %d] ipc_do_recv(): sender %d domain not granted\n", caller->id, *id_sender);
	        goto ret_denied;
	    }
#endif

        if (!perm_ipc_is_granted(*id_sender, caller->id)) {
            KERNLOG(DBG_ERR,
                "[task %d] ipc_do_recv(): not granted to listen sender %d\n", caller->id, *id_sender);
            goto ret_denied;
        }
    }

    /* Verifying that &buf is in caller address space.
     * Important note: the sender can transmit a void message to send a
     * notification. In that case, that sanatization step is not required.  */
    if (*size) {
        if (!sanitize_is_data_pointer_in_slot((void *)buf, *size, caller->id, mode)) {
            KERNLOG(DBG_ERR,
                "ipc_do_recv(): buffer (%x - %x) not in caller (%d) space\n", buf, buf + *size, caller->id);
            goto ret_inval;
        }
    }

    /***************************
     * Defining an IPC EndPoint
     ***************************/

    ep = NULL;

    /* Listening to ANY_APP is a special case.
     * The receiver may have already received any message. Thus,
     * we have to look for the IPC endpoints with a pending message. */
    if (*id_sender == ANY_APP) {
        for (int i=ID_APP1; i<=ID_APP7; i++) {
            if (caller->ipc_endpoint[i] != NULL &&
                caller->ipc_endpoint[i]->state == WAIT_FOR_RECEIVER &&
                caller->ipc_endpoint[i]->to == caller->id) {
                    ep = caller->ipc_endpoint[i];
                    break; /* read data on the endpoint */
            }
        }
    }
    /* Listening to an identified user task (ID_APP*) */
    else {
        if (caller->ipc_endpoint[*id_sender] != NULL &&
            caller->ipc_endpoint[*id_sender]->state == WAIT_FOR_RECEIVER &&
            caller->ipc_endpoint[*id_sender]->to == caller->id) {
            ep = caller->ipc_endpoint[*id_sender];
        }
    }

    /**********************
     * Reading the message
     **********************/

    /* If there is no pending message to read, we terminate here */
    if (ep == NULL) {
        /* Waking up idle senders */
        if (*id_sender != ANY_APP &&
            sender->state[TASK_MODE_MAINTHREAD] == TASK_STATE_IDLE)
        {
            sender->state[TASK_MODE_MAINTHREAD] = TASK_STATE_RUNNABLE;
        }

        /* Receiver is blocking until it receives a message or it returns
         * E_SYS_BUSY */
        if (blocking) {
            caller->state[TASK_MODE_MAINTHREAD] = TASK_STATE_IPC_RECV_BLOCKED;
            return;
        } else {
            goto ret_busy;
        }
    }

    /* 
     * A message was sent. First, we verify that the caller is granted
     * to read a message sent by the sender in the specific case of a recv(ANY)
     */

    if (*id_sender == ANY_APP) {

        /* The caller is not allowed to read a message from the sender */
        if (!perm_ipc_is_granted(ep->from, caller->id)) {

            KERNLOG(DBG_ERR,
                "[task %d] ipc_do_recv(): sender %d not granted\n",
                caller->id, ep->from);

            /* Free sender from it's blocking state */
            syscall_r0_update(sender, TASK_MODE_MAINTHREAD, SYS_E_DENIED);
            sender->state[TASK_MODE_MAINTHREAD] = TASK_STATE_RUNNABLE;

            /* Receiver is blocking until it receives a message or it returns
             * E_SYS_BUSY */
            if (blocking) {
                caller->state[TASK_MODE_MAINTHREAD] = TASK_STATE_IPC_RECV_BLOCKED;
                return;
            } else {
                goto ret_busy;
            }
        }
    }

    /* The syscall returns the sender ID */
    *id_sender = ep->from;

    sender = task_get_task(ep->from);
    if (sender == NULL ||
        sender->state[TASK_MODE_MAINTHREAD] == TASK_STATE_EMPTY)
    {
        panic("[task %d] invalid sender (%d) - empty task\n", caller->id, *id_sender);
    }

    /* Copying the message in the receiver's buffer */
    if (ep->size > *size) {
        KERNLOG(DBG_ERR,
            "ipc_do_recv(): IPC message overflows: receiver's (%x) buffer is too small (%d > %d)\n", caller->id, ep->size, *size);
        *size = ep->size;
        goto ret_inval;
    }

    memcpy(buf, ep->data, ep->size);

    /* Returning the data size */
    *size = ep->size;

    /* The EndPoint is ready for another use */
    ep->state = READY;
    ep->size  = 0;

    /* Free sender from it's blocking state */
    switch (sender->state[TASK_MODE_MAINTHREAD]) {
        case TASK_STATE_IPC_WAIT_ACK:
            syscall_r0_update(sender, TASK_MODE_MAINTHREAD, SYS_E_DONE);
            sender->state[TASK_MODE_MAINTHREAD] = TASK_STATE_RUNNABLE;
            break;

        case TASK_STATE_IPC_SEND_BLOCKED:
            sender->state[TASK_MODE_MAINTHREAD] = TASK_STATE_SVC_BLOCKED;
            softirq_query(SFQ_SYSCALL, sender->id, 0, 0, 0);
            task_set_task_state(ID_SOFTIRQ, TASK_MODE_MAINTHREAD, TASK_STATE_RUNNABLE);
            break;

        default:
            break;
    }

    syscall_r0_update(caller, mode, SYS_E_DONE);
    caller->state[mode] = TASK_STATE_RUNNABLE;
    return;

 ret_inval:
    syscall_r0_update(caller, mode, SYS_E_INVAL);
    caller->state[mode] = TASK_STATE_RUNNABLE;
    return;

 ret_busy:
    syscall_r0_update(caller, mode, SYS_E_BUSY);
    caller->state[mode] = TASK_STATE_RUNNABLE;
    return;

 ret_denied:
    syscall_r0_update(caller, mode, SYS_E_DENIED);
    caller->state[mode] = TASK_STATE_RUNNABLE;
    return;
}


void ipc_do_send(task_t *caller, __user regval_t *regs, bool blocking, e_task_mode mode)
{
    ipc_endpoint_t *ep = NULL;
    task_t         *receiver = NULL;

    /* Receiver id. Mandatory to know who is the receiver */
    e_task_id   id_receiver = (e_task_id) regs[1];

    /* Buffer size */
    logsize_t    size = (logsize_t)regs[2];

    /* Buffer address */
    char       *buf = (char *)regs[3];

    /* Debug */
    KERNLOG(DBG_DEBUG,
        "DEBUG: ipc_do_send() task %d -> task %d\n", caller->id, id_receiver);

    /***********************
     * Verifying parameters
     ***********************/

    if (mode == TASK_MODE_ISRTHREAD) {
        KERNLOG(DBG_ERR, "[task %d] ipc_do_send(): making IPCs while in ISR mode is not allowed!\n", caller->id);
        goto ret_denied;
    }

    /* Test if task initialization is complete */
    if (caller->init_done == false) {
        KERNLOG(DBG_ERR,
            "[task %d] ipc_do_send(): initialization not completed\n",
            caller->id);
        goto ret_denied;
    }

    /* Verifying that &buf is in caller address space.
     * Important note: the sender can transmit a void message to send a
     * notification. In that case, that sanatization step is not required.  */
    if (size) {
        if (!sanitize_is_data_pointer_in_any_slot((void *)buf, size, caller->id, mode)) {
            KERNLOG(DBG_ERR,
                "ipc_do_send(): buffer (%x - %x) not in caller (%d) space\n",
                buf, buf + size, caller->id);
            goto ret_inval;
        }
    }

    /* Verifying that the receiver id corresponds to a user task */
    if (!task_is_user(id_receiver)) {
        KERNLOG(DBG_ERR,
            "[task %d] ipc_do_send(): invalid id_receiver (%d)\n",
            caller->id, id_receiver);
        goto ret_inval;
    }

    receiver = task_get_task(id_receiver);

    /* Verifying that the receiver is valid */
    if (receiver == NULL ||
        receiver->state[TASK_MODE_MAINTHREAD] == TASK_STATE_EMPTY)
    {
        KERNLOG(DBG_ERR,
            "[task %d] ipc_do_send(): invalid receiver (%d) - empty task\n", caller->id, id_receiver);
        goto ret_inval;
    }

    /* A task can't send a message to itself */
    if (caller->id == id_receiver) {
        KERNLOG(DBG_ERR,
            "[task %d] ipc_do_send(): invalid id_receiver (%d) - same as caller->id\n", caller->id, id_receiver);
        goto ret_inval;
    }

    /* Is size valid ? */
    if (size > MAX_IPC_MSG) {
        KERNLOG(DBG_ERR,
            "[task %d] ipc_do_send(): invalid size (%d > %d)\n",
            caller->id, size, MAX_IPC_MSG);
        goto ret_inval;
    }

    /*
     * Verifying permissions
     */

#ifdef CONFIG_KERNEL_DOMAIN
    if (!perm_same_ipc_domain(caller->id, id_receiver)) {
        KERNLOG(DBG_ERR,
            "[task %d] ipc_do_send(): receiver domain %d not granted\n", caller->id, id_receiver);
        goto ret_denied;
    }
#endif

    if (!perm_ipc_is_granted(caller->id, id_receiver)) {
        KERNLOG(DBG_ERR,
            "[task %d] ipc_do_send(): receiver %d not granted\n", caller->id, id_receiver);
        goto ret_denied;
    }


    /***************************
     * Defining an IPC EndPoint
     ***************************/

    ep = NULL;

    /* Creating a new IPC endpoint between the sender and the receiver */
    if (caller->ipc_endpoint[id_receiver] == NULL) {
        if (receiver->ipc_endpoint[caller->id] != NULL) {
            panic("ipc_do_send(): IPC endpoint already defined by the receiver");
        }
        ep = ipc_get_endpoint();
        if (ep == NULL) {
            panic("ipc_do_send(): impossible to create a new IPC endpoint");
        }
        caller->ipc_endpoint[id_receiver]  = ep;
        receiver->ipc_endpoint[caller->id] = ep;
    }
    /* Reusing an already existing EndPoint */
    else {
        ep = caller->ipc_endpoint[id_receiver];
    }

    /********************
     * Sending a message
     ********************/

    /* Wake up idle receivers */
    if (sleep_is_sleeping_task(receiver->id)) {
        sleep_try_waking_up(receiver->id);
    } else {
        if (receiver->state[TASK_MODE_MAINTHREAD] == TASK_STATE_IDLE) {
            receiver->state[TASK_MODE_MAINTHREAD] = TASK_STATE_RUNNABLE;
        }
    }

    /* The receiver has already a pending message and the endpoint is
     * already in use. */
    if (ep->state == WAIT_FOR_RECEIVER && ep->to == id_receiver) {
        if (blocking) {
            caller->state[TASK_MODE_MAINTHREAD] = TASK_STATE_IPC_SEND_BLOCKED;
#ifdef CONFIG_SCHED_SUPPORT_FIPC
            syscall_set_target_task_forced(receiver);
#endif
            return;
        } else {
            goto ret_busy;
        }
    }

    if (ep->state != READY) {
        panic("ipc_do_send(): invalid IPC endpoint state");
    }

    ep->from = caller->id;
    ep->to   = id_receiver;

    /* We copy the message in the IPC buffer */
    memcpy(ep->data, buf, size);
    ep->size = size;

    /* Adjusting the EndPoint state */
    ep->state = WAIT_FOR_RECEIVER;

    /* If the receiver was blocking, it can be 'freed' from its blocking
     * state. We reinject it so that it can fulfill its syscall */
    if (receiver->state[TASK_MODE_MAINTHREAD] == TASK_STATE_IPC_RECV_BLOCKED) {
        receiver->state[TASK_MODE_MAINTHREAD] = TASK_STATE_SVC_BLOCKED;
        softirq_query(SFQ_SYSCALL, receiver->id, 0, 0, 0);
        task_set_task_state(ID_SOFTIRQ, TASK_MODE_MAINTHREAD, TASK_STATE_RUNNABLE);
    }

    if (blocking) {
        caller->state[TASK_MODE_MAINTHREAD] = TASK_STATE_IPC_WAIT_ACK;
#ifdef CONFIG_SCHED_SUPPORT_FIPC
        syscall_set_target_task_forced(receiver);
#endif
        return;
    }
    else {
        syscall_r0_update(caller, mode, SYS_E_DONE);
        caller->state[mode] = TASK_STATE_RUNNABLE;
        return;
    }

 ret_inval:
    syscall_r0_update(caller, mode, SYS_E_INVAL);
    caller->state[mode] = TASK_STATE_RUNNABLE;
    return;

 ret_busy:
    syscall_r0_update(caller, mode, SYS_E_BUSY);
    caller->state[mode] = TASK_STATE_RUNNABLE;
    return;

 ret_denied:
    syscall_r0_update(caller, mode, SYS_E_DENIED);
    caller->state[mode] = TASK_STATE_RUNNABLE;
    return;
}

static inline void ipc_do_log(task_t *caller, __user regval_t *regs, e_task_mode mode)
{
    uint32_t size = regs[2];
    uint32_t msg = regs[3];

    /* Is the message in the task address space? */
    if (!sanitize_is_data_pointer_in_slot((void*)msg, size, caller->id, mode)) {
        goto ret_inval;
    }

    if (size >= 512) {
        goto ret_inval;
    }

    dbg_log("[%s] ", caller->name);
    dbg_log((char*)msg);
    dbg_flush();

    syscall_r0_update(caller, mode, SYS_E_DONE);
    syscall_set_target_task_runnable(caller);
    return;

 ret_inval:
    syscall_r0_update(caller, mode, SYS_E_INVAL);
    syscall_set_target_task_runnable(caller);
    return;
}

/*
** IPC type to define, please use register based, not buffer based to
** set type and content (r1, r2, r3, r4... r1 = target, r2 = ipctype, r3 = ipc arg1...)
*/
void sys_ipc(task_t *caller, __user regval_t *regs, e_task_mode mode)
{
    uint32_t type = regs[0];
    // check that msg toward msg+size is in task's data section.
    switch (type) {
    case IPC_LOG:
        KERNLOG(DBG_DEBUG, "[syscall][ipc][task %s] ipc log\n", caller->name);
        ipc_do_log(caller, regs, mode);
        break;
    case IPC_RECV_SYNC:
        KERNLOG(DBG_DEBUG, "[syscall][ipc][task %s] recv sync\n", caller->name);
        ipc_do_recv(caller, regs, true, mode); /* blocking */
        break;
    case IPC_SEND_SYNC:
        KERNLOG(DBG_DEBUG, "[syscall][ipc][task %s] send sync\n", caller->name);
        ipc_do_send(caller, regs, true, mode); /* blocking */
        break;
    case IPC_RECV_ASYNC:
        KERNLOG(DBG_DEBUG, "[syscall][ipc][task %s] recv async\n", caller->name);
        ipc_do_recv(caller, regs, false, mode); /* not blocking */
        break;
    case IPC_SEND_ASYNC:
        KERNLOG(DBG_DEBUG, "[syscall][ipc][task %s] send async\n", caller->name);
        ipc_do_send(caller, regs, false, mode); /* not blocking */
        break;
    default:
        KERNLOG(DBG_DEBUG, "[syscall][ipc][task %s] invalid!!\n", caller->name);
        syscall_r0_update(caller, mode, SYS_E_INVAL);
        syscall_set_target_task_runnable(caller);
        break;
    }
    return;
}

