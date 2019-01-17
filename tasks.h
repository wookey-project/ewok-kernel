/* \file tasks.h
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

#ifndef TASK_H_
#define TASK_H_

#include "autoconf.h"
#include "types.h"
#include "mpu.h"
#include "exported/devices.h"
#include "exported/dmas.h"
#include "dma-shared.h"
#include "kernel.h"

#define __KERNEL

#include "tasks-shared.h"
#include "ipc.h"
#include "devices-shared.h"

/* should be configured */
#define MAX_IRQS_PER_TASK       8
#define MAX_TIMERS_PER_TASK     6
#define MAX_DMAS_PER_TASK       8
#define MAX_DMA_SHM_PER_TASK    4
#define MAX_DEVS_PER_TASK       8


/*
** \brief task state
*/
typedef enum {
    /* No task in this slot */
    TASK_STATE_EMPTY,

    /* Task can be elected by the scheduler with its standard priority */
    TASK_STATE_RUNNABLE,

    /* Force the scheduler to choose that task */
    TASK_STATE_FORCED,

    /* Pending syscall. Task can't be scheduled. */
    TASK_STATE_SVC_BLOCKED,

    TASK_STATE_ISR_DONE,

    /* Task currently has nothing to do, not schedulable */
    TASK_STATE_IDLE,

    /* Task is sleeping */
    TASK_STATE_SLEEPING,

    /* Task is sleeping */
    TASK_STATE_SLEEPING_DEEP,

    /* Task has generated an exception (memory fault, etc.), not
     * schedulable anymore */
    TASK_STATE_FAULT,

    /* Task has return from its main() function. Yet its ISR handlers can
     * still be executed if needed */
    TASK_STATE_FINISHED,

    /* Task has emitted a blocking send(target) and is waiting
     * for that the EndPoint shared with the receiver gets ready */
    TASK_STATE_IPC_SEND_BLOCKED,

    /* Task has emitted a blocking recv(target) and is waiting
     * for a send() */
    TASK_STATE_IPC_RECV_BLOCKED,

    /* Task has emitted a blocking send(target) and is waiting
     * recv() acknowledgement from the target task */
    TASK_STATE_IPC_WAIT_ACK,

    TASK_STATE_LOCKED
} e_task_state;

/*
** \brief task type: kernel, user or idle
*/
typedef enum {
    /* Kernel task, executing restricted ASM instruction (typically
     * softirq) */
    TASK_TYPE_KERNEL,

    /* User task, being executed in user mode, with restricted access */
    TASK_TYPE_USER
} e_task_type;

/*
** \brief Specify the current task context state
*/
typedef enum {
    /* The task is using it's main context, executing its main thread */
    TASK_MODE_MAINTHREAD = 0,

    /* The task is using its ISR context, when executing one of its ISR
     * handler in user mode */
    TASK_MODE_ISRTHREAD = 1,
    TASK_MODE_MAX = 2,
} e_task_mode;

/**
 * \brief the task context struct, hosting the task context when scheduled
 *
 * \param fn: for handler mode (isr_ctx) only, to set which handler needs to be executed
 * \param dev: for handler mode (isr_ctx) only, specify the lonely device to map
 * \param frame: point to saved registers
 * \param ret: link register value
 * \param fp_regs: FPU registers values
 * \param fp_flags: FPU flags (cary, etc.)
 */
typedef struct {
    physaddr_t      fn;
    e_device_id     dev_id;
    dev_irq_info_t *irq;
    stack_frame_t  *frame;
#ifdef CONFIG_FPU
#ifndef CONFIG_FPU_ENABLE_PRIVILEGIED
    regval_t        fp_regs[8];
    regval_t        fp_flag;
#endif
#endif
} task_context_t;

/*
 * \brief This is the main task struct
 * This structure contains the overall task informations, including:
 *    - memory layout properties
 *    - task type (user, kernel)
 *    - task priority
 *    - task registered ressources (devices, DMA, etc.)
 *    - task current status (init or nominal mode
 *    - task threads contexts
 *
 *  This structure doesn't contain the permissions, as permissions
 *  are read-only data set at build time. Link beetween permissions and
 *  tasks is done using the task identifier.
 */
typedef struct task_t {
    char const *name;   /* task name, for pretty printing */

    physaddr_t fn;      /* task entry point */
    e_task_type type;   /* task type (user, kernel, ... */
    e_task_mode mode;   /* current task mode (thread or isr) */
    e_task_id  id;      /* id */

    uint8_t slot;       /* user slot (memory sub-region) used. 0 = unused */
    uint8_t num_slots;  /* number of slots used by the application */

    uint8_t prio;       /* priority (not used by now) */

#ifdef CONFIG_KERNEL_DOMAIN
    uint8_t domain;     /* task execution domain */
#endif

    uint8_t num_devs;           /* Number of devices for this task */
    uint8_t num_devs_mmapped;   /* Number of devices for this task */

#ifdef CONFIG_KERNEL_SCHED_DEBUG
    uint32_t count;
    uint32_t force_count;
    uint32_t isr_count;
#endif

#ifdef CONFIG_KERNEL_DMA_ENABLE
    uint32_t num_dma_shms;
    dma_shm_t dma_shm[MAX_DMA_SHM_PER_TASK];
    uint32_t num_dmas;  /* number of task's registered dma */
    e_dma_id dma[MAX_DMAS_PER_TASK];      /* list of task's devices */
#endif

    bool init_done;     /* set to true when sys_init(INIT_DONE) has been executed */

    e_device_id dev_id[MAX_DEVS_PER_TASK];   /* list of task's devices */

    physaddr_t ram_slot_start;  /* RAM slot start address */
    physaddr_t ram_slot_end;    /* RAM slot end address */
    physaddr_t txt_slot_start;  /* .text slot start address */
    physaddr_t txt_slot_end;    /* .text slot end address */

    physaddr_t stack_bottom;
    physaddr_t stack_top;
    uint16_t stack_size;        /* stack size (in bytes) */

    e_task_state state[TASK_MODE_MAX];     /* current schedulable state */
    ipc_endpoint_t* ipc_endpoint[ID_MAX];  /* input IPC context (if any) */
    task_context_t ctx[TASK_MODE_MAX];     /* main thread context */
} task_t;


/************************************************************************
 * Task package getters and setters
 ***********************************************************************/
/*
 * Get the list of tasks
 */
task_t* task_get_tasks_list(void);

/*
 * get the task structure using its identifier
 */
task_t* task_get_task(e_task_id        id);

/*
 * Set the given task thread to a given state
 */
void task_set_task_state(e_task_id     id,
                         e_task_mode   thread,
                         e_task_state  state);

e_task_state task_get_task_state(e_task_id id, e_task_mode mode);

/*
 * Get the task name using its identifier
 */
const char* task_get_name(e_task_id    id);


/*
** \fn specify if a task is a user task or not
**
** \param id: the slot (or task id) identifier
*/
uint8_t task_is_user(e_task_id         id);

/************************************************************************
 * Utility functions for task creation (public part)
 * These functions create task context, task stack, etc.
 ***********************************************************************/

/*
** \fn Generate a custom stack frame for a given task context
**
** \param t: the task_context (sp @ has to be set in it already)
** \param sp: a given stack pointer
** \param fn: a handler or function to use for LR stacked value
** \param args: table of 4 registers values, for r0,r1,r2,r3, or 0 if no args
*/
void task_create_stack(task_context_t*  t,
                       physaddr_t       sp,
                       physaddr_t       fn,
                       physaddr_t*      args);

/************************************************************************
 * Global task package initializer
 ***********************************************************************/

/*
** \fn task module initialization function
*/
void task_init(void);

#endif                          /*!TASK_H_ */
