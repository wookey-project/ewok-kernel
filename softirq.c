/* softirq.c
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

#include "m4-mpu.h"
#include "m4-cpu.h"
#include "soc-interrupts.h"

#include "softirq.h"
#include "layout.h"
#include "types.h"
#include "debug.h"
#include "autoconf.h"
#include "libc.h"
#include "sched.h"
#include "syscalls.h"
#include "kernel.h"
#include "tasks.h"
#include "tasks-shared.h"
#include "devices.h"
#include "mpu.h"
#include "syscalls-init.h"
#include "syscalls-rng.h"

#include "dma.h"
#include "soc-dma.h"
#include "sleep.h"

/*
** max IRQ waiting
*/
#define MAX_QUEUE_SIZE CONFIG_KERNEL_SOFTIRQ_QUEUE_DEPTH

typedef enum {
    SFQ_DONE = 0,
    SFQ_WAITING
} e_softirq_state;

typedef struct {
    task_t *caller;             //syscall case, task requesting
    e_softirq_state state;
    uint8_t irqnum;             //IRQ case, nIRQ requesting
    physaddr_t handler;         //IRQ case, user handler
    physaddr_t status;          //IRQ case, status register value, when needed
    physaddr_t data;            //IRQ case, data register value, when needed
} softirq_t;

typedef void (*softirq_handler_t) (softirq_t *);

typedef struct {
    uint32_t    start;
    uint32_t    end;
    bool        full;
    bool        empty;
    softirq_t   queue[MAX_QUEUE_SIZE];
} softirqs_queue;

#define BUF_MAX        (MAX_QUEUE_SIZE - 1)

/*
** All input queue are ring buffers.
** This allows multiple syscalls/IRQ queries by external execution before finishing others.
** Note: a user ISR can't execute a syscall because it has no dedicated stack
*/
static softirqs_queue isr_queue;
static softirqs_queue syscall_queue;

/*
** push some content in one of the softirq ring buffers
*/
__INLINE uint8_t push_softirq(softirqs_queue *queue, e_task_id task_id,
                              uint8_t irqnum, physaddr_t handler,
                              physaddr_t *regs)
{
    task_t *caller;

    caller = task_get_task(task_id);
    if (caller == NULL) {
        panic("push_softirq(): faulty task_id %d", task_id);
    }

    /* No more space ! */
    if (queue->full) {
        return 1;
    }
    /* The current queue is the last slot which has just been
     * released, but not yet unlocked.
     */
    if (queue->queue[queue->end].state != SFQ_DONE) {
        return 1;
    }

    queue->empty = false;

    queue->queue[queue->end].state = SFQ_WAITING;
    queue->queue[queue->end].caller = caller;
    queue->queue[queue->end].irqnum = irqnum;
    queue->queue[queue->end].handler = handler;
    if (regs != 0) {
      queue->queue[queue->end].status = regs[0];
      queue->queue[queue->end].data = regs[1];
    } else {
      queue->queue[queue->end].status = 0;
      queue->queue[queue->end].data = 0;
    }

    queue->end++;
    queue->end %= BUF_MAX;
    if (queue->end == queue->start) {
        queue->full = true;
    }

    return 0;
}

/*
** pop some content from one of the softirq ring buffers
** This is a FIFO mode to respect the ISR and syscall order
**
** CAUTION: IRQ are temporary disabled to avoid race condition
** between pop and push from IRQ context. This disabling is
** really short, the time to effectively pop the cell and update
** the queue.
*/
__INLINE softirq_t* pop_softirq(softirqs_queue *queue)
{
    softirq_t *sfq;

    disable_irq();
    if (queue->empty) {
        enable_irq();
        return NULL;
    }

    queue->full = false;

    sfq = &(queue->queue[queue->start]);

    queue->start++;
    queue->start %= BUF_MAX;
    if (queue->end == queue->start) {
        queue->empty = true;
    }

    enable_irq();
    return sfq;
}

/*
** Handler managing syscalls (svc 0) waiting for execution in the softirq input queue
*/
static void softirq_handler_syscall(softirq_t * sfq)
{
    svcnum_t svc = 0;
    uint32_t *args = 0;
    char *svcptr = 0;
    uint32_t syscall = 0;
    stack_frame_t *frame = sfq->caller->ctx[TASK_MODE_MAINTHREAD].frame;

    // let's execute the effective content of the syscall from the userspace task
    // FIXME: [PTH] svc is 8bits on Thumb2, to be updated for portability
    svcptr = (char *)frame->pc;
    svc = (uint32_t) svcptr[-2];
    args = (uint32_t *) frame->r0;

    if (svc != 0) {
        dbg_log("unsupported system call svc=%d!\n", svc);
        dbg_flush();
    }

    syscall = (uint32_t) args[0];

    /*
     * TODO: Hardcoded TASK_MODE_MAINTHREAD should be replaced by the
     * caller task current mode at svc handler time, passed through
     * softirq_query, using the same mechanism as svc_handler_syscalls().
     */
    KERNLOG(DBG_DEBUG, "Executing syscall %d for task %s\n", syscall,
            sfq->caller->name);
    switch (syscall) {
        case SYS_YIELD:
            sys_yield(sfq->caller, TASK_MODE_MAINTHREAD);
            break;
        case SYS_RESET:
            sys_reset(sfq->caller, TASK_MODE_MAINTHREAD);
            break;
        case SYS_SLEEP:
            sys_sleep(sfq->caller, &args[1], TASK_MODE_MAINTHREAD);
            break;
        case SYS_LOCK:
            sys_lock(sfq->caller, &args[1], TASK_MODE_MAINTHREAD);
            break;
        case SYS_INIT:
            sys_init(sfq->caller, &args[1], TASK_MODE_MAINTHREAD);
            break;
        case SYS_IPC:
            sys_ipc(sfq->caller, &args[1], TASK_MODE_MAINTHREAD);
            break;
        case SYS_CFG:
            sys_cfg(sfq->caller, &args[1], TASK_MODE_MAINTHREAD);
            break;
        case SYS_GETTICK:
            sys_gettick(sfq->caller, &args[1], TASK_MODE_MAINTHREAD);
            break;
        case SYS_GET_RANDOM:
            sys_get_random(sfq->caller, &args[1], TASK_MODE_MAINTHREAD);
            break;
        default:
            WARN("Unknown syscall %d for task %s\n", syscall, sfq->caller->name);
            break;
    }
    return;
}

/*
 * This function prepare execution of the user ISR handler in user mode (with
 * PSP stack). When PendSV will request the scheduler, ISRTHREAD mode tasks
 * will be scheduled with the highest priority (note: it can
 * be preempted by any IRQ).
 */
static void softirq_handler_user_isr(softirq_t * sfq)
{
    static e_task_id    previous_isr_owner  = ID_UNUSED;
    task_t             *task            = sfq->caller;
    uint8_t             irq             = sfq->irqnum;
    physaddr_t          isr_params[4]   = { 0, 0, 0, 0 };
    e_device_id         dev_id;

    isr_params[0] = sfq->handler;
    isr_params[1] = (uint8_t) (irq - 16); /* IRQ num for NVIC starts with 0 */
    isr_params[2] = sfq->status;
    isr_params[3] = sfq->data;


    // FIXME: DMA device has to be mapped in IRQ context; dma is not a device_t

    dev_id = get_device_from_interrupt(irq);
    if (dev_id != ID_DEV_UNUSED) {
        task->ctx[TASK_MODE_ISRTHREAD].dev_id = dev_id;
    }
    else {
        task->ctx[TASK_MODE_ISRTHREAD].dev_id = ID_DEV_UNUSED;
    }

    task->ctx[TASK_MODE_ISRTHREAD].irq = dev_get_irqinfo_from_irq(irq);

    /* Creating the fake stack for ISR handler and create the initial frame */
    if (sfq->caller->id != previous_isr_owner) {
        /* Zeroing the stack only if previous ISR belongs to another task */
        memset((char *)STACK_TOP_ISR - STACK_SIZE_ISR, 0, STACK_SIZE_ISR);
        previous_isr_owner = sfq->caller->id;
    }

    task->ctx[TASK_MODE_ISRTHREAD].frame = (stack_frame_t *) STACK_TOP_ISR;

    /*
     * The schedule will execute 'task->ctx[TASK_MODE_ISRTHREAD].fn' that
     * is for every tasks 'libs/libstd/arch/cores/armv7-m/m4_syscall.c:
     * do_startisr()' function. That function is a wrapper that take
     * several parameters:
     *   isr_params[0]: user handler to execute
     *   isr_params[1]: irq
     *   isr_params[2]: status
     *   isr_params[3]: data
     */
    task_create_stack(&task->ctx[TASK_MODE_ISRTHREAD], STACK_TOP_ISR,
                      (uint32_t) task->ctx[TASK_MODE_ISRTHREAD].fn,
                      isr_params);

    task->mode = TASK_MODE_ISRTHREAD;
    task->state[TASK_MODE_ISRTHREAD] = TASK_STATE_RUNNABLE;

    full_memory_barrier();
}

/*
** initialize handlers
*/
void softirq_init(void)
{
    isr_queue.empty = true;
    isr_queue.full  = false;
    isr_queue.start = 0;
    isr_queue.end   = 0;
    memset(isr_queue.queue, 0x0, MAX_QUEUE_SIZE*sizeof(softirq_t));

    syscall_queue.empty = true;
    syscall_queue.full  = false;
    syscall_queue.start = 0;
    syscall_queue.end   = 0;
    memset(syscall_queue.queue, 0x0, MAX_QUEUE_SIZE*sizeof(softirq_t));

    KERNLOG(DBG_NOTICE,
            "Initialized softirq subsystem. Syscalls and user IRQ/FIQ are handled out of interrupt mode.\n");
    dbg_flush();
}

/*
** Query for a new softirq
** executed in hander mode
*/
void softirq_query(e_softirq_type sfq, e_task_id task_id, uint8_t irq,
                   physaddr_t irq_handler, physaddr_t *args)
{
    int ret;

    switch (sfq) {
    case SFQ_SYSCALL:
        ret = push_softirq(&syscall_queue, task_id, 0, 0, 0);
        if (ret) {
            panic("push_softirq() failed");
        }
        break;
    case SFQ_USR_ISR:
        ret = push_softirq(&isr_queue, task_id, irq, irq_handler, args);
        if (ret) {
            panic("push_softirq() failed");
        }
        break;
    default:
        panic("push_softirq(): unknown method!");
        break;
    }
    task_set_task_state (ID_SOFTIRQ, TASK_MODE_MAINTHREAD, TASK_STATE_RUNNABLE);
    request_schedule();
    full_memory_barrier();
}

/*
** This is the softirq task. Scheduled when a syscall or a userspace interrupt handler
** need to be executed. It is executed out of processor interrupt mode, on voluntary schedule
** only.
*/
void task_softirq(void)
{
    softirq_t  *sfq = NULL;

    while (1) {

        /*
         * User ISRs
         */
        if (!isr_queue.empty) {
            while ((sfq = pop_softirq(&isr_queue))) {
                if (sfq->state == SFQ_WAITING) {
                    if (sfq->caller->state[TASK_MODE_MAINTHREAD] != TASK_STATE_LOCKED &&
                        sfq->caller->state[TASK_MODE_MAINTHREAD] != TASK_STATE_SLEEPING_DEEP)
                    {
                        disable_irq();
                        softirq_handler_user_isr(sfq);
                        sfq->state = SFQ_DONE;
                        full_memory_barrier();
                        enable_irq();
#ifdef CONFIG_ISR_REACTIVITY
                        // ISR should be executed fastly, softirq let them being
                        // executed now, syscalls are delayed
                        request_schedule();
#endif
                    } else {
                        // while task is locked, postponing the ISR
                        uint32_t args[2] = { sfq->status, sfq->data };
                        disable_irq();
                        full_memory_barrier();
                        push_softirq(&isr_queue, sfq->caller->id, sfq->irqnum, sfq->handler, args);
                        sfq->state = SFQ_DONE;
                        enable_irq();
                    }
                }
            }
        }

        full_memory_barrier();

        /*
         * Syscalls
         */
        if (!syscall_queue.empty) {
            while ((sfq = pop_softirq(&syscall_queue))) {
                if (sfq->state == SFQ_WAITING) {
                    softirq_handler_syscall(sfq);
                    sfq->state = SFQ_DONE;
                }
            }
        }

        disable_irq();
        full_memory_barrier();

        if (syscall_queue.empty && isr_queue.empty) {
            /* Softirq is idle when there is no more syscall of ISR to manage */
            task_set_task_state (ID_SOFTIRQ, TASK_MODE_MAINTHREAD, TASK_STATE_IDLE);
            full_memory_barrier();
            request_schedule();
        }

        enable_irq();

    }
    /* end of main loop */
}
