/* \file syscalls.h
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
#ifndef _KERNEL_SYSCALLS_H_
#define _KERNEL_SYSCALLS_H_

/*
 * IPC broadcast magic number
 */
#define ANY_APP 0xff

typedef enum {
    SVC_EXIT,
    SVC_YIELD,
    SVC_GET_TIME,
    SVC_RESET,
    SVC_SLEEP,
    SVC_GET_RANDOM,
    SVC_LOG,
    SVC_REGISTER_DEVICE,
    SVC_REGISTER_DMA,
    SVC_REGISTER_DMA_SHM,
    SVC_GET_TASKID,
    SVC_INIT_DONE,
    SVC_IPC_RECV_SYNC,
    SVC_IPC_SEND_SYNC,
    SVC_IPC_RECV_ASYNC,
    SVC_IPC_SEND_ASYNC,
    SVC_GPIO_SET,
    SVC_GPIO_GET,
    SVC_GPIO_UNLOCK_EXTI,
    SVC_DMA_RECONF,
    SVC_DMA_RELOAD,
    SVC_DMA_DISABLE,
    SVC_DEV_MAP,
    SVC_DEV_UNMAP,
    SVC_DEV_RELEASE,
    SVC_LOCK_ENTER,
    SVC_LOCK_EXIT,
    SVC_PANIC
} e_svc_type;

/**
** \private
** enumerate defining the syscall to execute (value in r0)
** yield: require a schedule and set task as unschedulable while no IT for it arrise
** register_irq_handler: ask to be called by the generic kernel IRQ handler for the
** corresponding IRQ
**
** register_device_access: at schedule() time, the memory region corresponding to the device
** is mapped RW for the user otherwhise, its stays unaccessible
**
** This enumerate is used by the libstd and should not be used directly by the user application
** or at its own risk. See libstd's syscall.h header for libstd kernel API.
*/
typedef enum {
    SYS_YIELD = 0,
    SYS_INIT,
    SYS_IPC,
    SYS_CFG,
    SYS_GETTICK,
    SYS_RESET,
    SYS_SLEEP,
    SYS_LOCK,
    SYS_GET_RANDOM,
    SYS_LOG
} e_syscall_type;

/**
** \brief Definition of the INIT syscall types
*/
typedef enum {
 /** request device access */
    INIT_DEVACCESS = 0,
 /** request HW DMA controlled access */
    INIT_DMA,
 /** declare a DMA shared region with another task, giving it the right
   to initiate a DMA transaction from or toward it */
    INIT_DMA_SHM,
 /** request the identifier of another task, giving its name */
    INIT_GETTASKID,
 /** finishing task init, any IPC_INIT* ipc will return DENIED */
    INIT_DONE,
 /** number of INIT commands */
    INIT_MAX,
} e_init_type;

/**
** \brief Definition of all the IPC syscall types
*/
typedef enum {
    /** Waiting data from another task (blocking syscall) */
    IPC_RECV_SYNC = 0,

    /** Sending data to another task (executed just after), or
     * return busy if the target already have an ipc content to read */
    IPC_SEND_SYNC,

    /** Read a waiting ipc content or returns SYS_E_INVAL if nothing to read */
    IPC_RECV_ASYNC,

    /** Sending data to another task (no forcing scheduling). If the target
     * already have an ipc content to read, the data is lost (busy is returned) */
    IPC_SEND_ASYNC,
} e_ipc_type;

typedef enum {
    /** Set value in a GPIO previously registered and enabled */
    CFG_GPIO_SET,

    /** Get value from a GPIO previously registered and enabled */
    CFG_GPIO_GET,

    /** Unlock previously locked EXTI line associated to given GPIO */
    CFG_GPIO_UNLOCK_EXTI,

    /** Reconfigure the DMA, given a new dma_t structure for one of the task's
     * predeclared DMA Streams */
    CFG_DMA_RECONF,

    /** Reload a DMA Stream, given a dma_t structure with DMA Controller, Stream
     * & channel identifier that is already owned by the task */
    CFG_DMA_RELOAD,

    /** Disable a DMA stream, which can be re-enable later using
     * CFG_DMA_RELOAD or CFG_DMA_RECONF */
    CFG_DMA_DISABLE,
    /** Map a device set as DEV_MAP_VOLUNTARY */
    CFG_DEV_MAP,
    /** unmap a device set as DEV_MAP_VOLUNTARY */
    CFG_DEV_UNMAP,
    /** Release a device */
    CFG_DEV_RELEASE
} e_cfg_type;

//[PTH] TODO: differentiate a synchronous send/recv and an asynchronous (with loss) one

typedef enum {
    PREC_MILLI = 0, /**< request for number of milliseconds since startup */
    PREC_MICRO,     /**< request for number of microseconds since startup */
    PREC_CYCLE      /**< request for number of CPU cycles since startup */
} e_tick_type;

typedef enum {
    LOCK_ENTER,
    LOCK_EXIT
} e_lock_type;

/**
** \brief Syscalls return values
*/
typedef enum {
    SYS_E_DONE = 0, /**< Syscall has succesfully being executed */
    SYS_E_INVAL,    /**< Invalid input data */
    SYS_E_DENIED,   /**< Permission is denied */
    SYS_E_BUSY,     /**< Target is busy OR not enough ressources OR ressource is already used */
    SYS_E_MAX,      /**< Number of possible return values */
} e_syscall_ret;

#endif /*!kernel/syscalls.h */
