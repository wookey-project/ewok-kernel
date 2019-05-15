.. _devices:

Managing devices from userland
==============================

.. contents::

.. highlight:: c

Task life-cycle
---------------

EwoK userspace tasks should follow a specific life-cycle, based on two
sequential states:

   * The *initialization state*, during which devices are declared and
     initialized
   * The *Nominal state*

Initialization state
^^^^^^^^^^^^^^^^^^^^

All resources declarations are performed during the initialization state. During
this state, the task can: 

   * declare and initialize a device
   * request DMA channels
   * ask for other tasks' identifiers
   * request some DMA shared memory (that will be shared with another task)
   * log messages into the kernel log console

These actions depend on permissions, as defined in
:ref:`EwoK pemission model <ewok-perm>`.

During this state, the task cannot use any device, nor
interact with any other task. Trying to use a device at this state or to
interact with other tasks will elicit a memory fault or a ``SYS_E_DENIED``.
The only possible syscalls are ``sys_log()``, used by ``printf()``,
and the ``sys_init()`` syscalls family.

.. danger::
   Do not try to access any registered device memory during the initialization
   phase, this will result into a memory fault

Ending the initialization phase is done with the following::

   sys_init(INIT_DONE);

After that step, the task is in *nominal state*. It has no way to request some
new hardware or software resources.

Nominal state
^^^^^^^^^^^^^

In this state, the task can use the previously declared resources.
All memory mapped devices are mapped in the task memory space, which
can therefore access that memory area.

.. warning::
   If a device is configured as a *voluntary mapped* device,
   its registers are not automatically mapped in the task's memory space.
   The task needs to voluntarily map it to be able to access it.

The task is no more authorized to execute any ``sys_init()`` call to the
kernel.

Other syscalls can be used:

   * ``sys_log()`` to transmit a message on the kernel logging facility
   * ``sys_ipc()`` syscalls family, to communicate through kernel IPC with
     other tasks
   * ``sys_cfg()`` syscalls family, to (re)configure previously declared
     devices and DMA
   * ``sys_get_systick()`` to get time stamping information
   * ``sys_yield()`` to voluntarily release the CPU core and sleep until an
     external event arises (IRQ or IPC targeting the task)
   * ``sys_sleep()`` to voluntarily release the CPU core and sleep for a given
     number of milliseconds
   * ``sys_reset()`` to voluntarily reset the SoC
   * ``sys_lock()`` to voluntarily lock a critical section and postpone the
     task's ISR for some time


Declaring and initializing resources
------------------------------------

Declaring and initializing a device
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Before using a device, a task must declare and initialize it.
Declaring and initializing a DMA stream is a particular case (see below).

The device structure is the following::

    typedef struct {
       char            name[16];      /**< device name */
       physaddr_t      address;       /**< device base address */
       uint16_t        size;          /**< device size (in bytes) */
       uint8_t         irq_num;       /**< number of device IRQs */
       uint8_t         gpio_num;      /**< number of device associated GPIOs */
       dev_irq_info_t  irqs[MAX_IRQS];   /**< table of IRQ management infos */
       dev_gpio_info_t gpios[MAX_GPIOS]; /**< table of GPIO configurations */
    } device_t;

The ``device_t`` structure is composed by:

   * The ``name`` field contains a name, used to ease debugging
   * The ``address`` and the ``size`` contains the MMIO address space, as
     defined in the datasheet
   * The ``irqs`` and ``gpios`` define a list of IRQs and GPIO pins (see below)

The device is then declared and initialized by using the ``sys_init(INIT_DEVACCESS)``
syscall (see :ref:`sys_init`). It is submitted to a set of permissions (see
:ref:`perms`).

The device is activated, including the RCC line(s), when the task ends its
initialization phase by calling ``sys_init(INIT_DONE``.

.. note::
   A device can be declared and initialized by only one task.

.. warning::
   Ada kernel is very strict with the syscall arguments types conformance. When
   passing structures, it is highly recommended to memset them to 0 before
   setting their content, otherwise the kernel will probably return SYS_E_INVAL

Declaring a GPIO pin
""""""""""""""""""""

GPIOs connect the SoC to the outside world (peripherals, buttons, leds, etc.)
Even if GPIO ports are devices per se (they are memory mapped, with their
own registers), EwoK never allows to directly map them in the user space.
A GPIO port controls several *pins* in a single register. A device usually needs
to control, at most, only some few pins. Thus, GPIO ports are shared
resources and the access to the pins are managed and mediated by the kernel.

.. highlight:: c

The ``dev_gpio_info_t`` structure is the following::

   typedef struct {
        gpio_mask_t         mask;
        gpioref_t           kref;
      	gpio_mode_t         mode;
      	gpio_pupd_t         pupd;
      	gpio_type_t         type;
      	gpio_speed_t        speed;
      	uint32_t            afr;
      	uint32_t            lck;
        gpio_exti_trigger_t exti_trigger;
        gpio_exti_lock_t    exti_lock;
      	user_handler_t      exti_handler;
   } dev_gpio_info_t;

The ``mode``, ``pupd``, ``type``, ``speed`` and ``afr`` are 
usual information about a GPIO pin.
The configuration ``mask`` allows to configure only some of these fields
(e.g. if there is no alternate function to configure).

The ``kref`` field the GPIO port/pin couple.

Here is an example of some GPIO pins declaration: ::

    usart_dev.gpios[0].mask =
        GPIO_MASK_SET_MODE | GPIO_MASK_SET_TYPE | GPIO_MASK_SET_SPEED |
        GPIO_MASK_SET_PUPD | GPIO_MASK_SET_AFR;

    usart_dev.gpios[0].kref.port = GPIO_PA;
    usart_dev.gpios[0].kref.pin = 6;

    usart_dev.gpios[0].type = GPIO_PIN_OTYPER_PP;
    usart_dev.gpios[0].pupd = GPIO_NOPULL;
    usart_dev.gpios[0].mode = GPIO_PIN_ALTERNATE_MODE;
    usart_dev.gpios[0].speed = GPIO_PIN_VERY_HIGH_SPEED;
    usart_dev.gpios[0].afr = GPIO_AF_USART1;

    usart_dev.gpios[1].mask =
        GPIO_MASK_SET_MODE | GPIO_MASK_SET_TYPE | GPIO_MASK_SET_SPEED |
        GPIO_MASK_SET_PUPD | GPIO_MASK_SET_AFR;

    usart_dev.gpios[1].kref.port = GPIO_PA;
    usart_dev.gpios[1].kref.pin = 7;

    usart_dev.gpios[1].afr = GPIO_AF_USART1;
    usart_dev.gpios[1].type = GPIO_PIN_OTYPER_PP;
    usart_dev.gpios[1].pupd = GPIO_NOPULL;
    usart_dev.gpios[1].mode = GPIO_PIN_ALTERNATE_MODE;
    usart_dev.gpios[1].speed = GPIO_PIN_VERY_HIGH_SPEED;


GPIOs and external interrupts (EXTI)
""""""""""""""""""""""""""""""""""""

GPIOs can be associated to external interrupts (EXTI). This is required to
asynchronously detect some external events based on GPIOs such as
a button pressed, an event on the touchscreen, etc.

These fields of the ``dev_gpio_info_t`` structure permit to configure such EXTIs:

   * ``exti_trigger`` specifies the kind of EXTI trigger 
   * ``exti_lock`` specifies whether the EXTI line has to be masked each time an EXTI
     interrupt arises (see ``sys_cfg(SYS_CFG_UNLOCK_EXTI)`` in :ref:`sys_cfg`)
   * ``exti_handler`` has the address of the ISR handler to execute

The IRQ line associated to the EXTI must not be declared: it is already fully
managed by the microkernel.

.. list-table::
   :widths: 20 80
   :header-rows: 1

   * - ``exti_trigger``
     - Description
   * - ``GPIO_EXTI_TRIGGER_NONE``
     - No trigger (the default)
   * - ``GPIO_EXTI_TRIGGER_RISE``
     - Trigger only on rising edge (value rising from 0 to 1)
   * - ``GPIO_EXTI_TRIGGER_FALL``
     - Trigger only on falling edge (value rising from 1 to 0)
   * - ``GPIO_EXTI_TRIGGER_BOTH``
     - Trigger on both edges

.. list-table::
   :widths: 20 80
   :header-rows: 1

   * - ``exti_lock``
     - Description
   * - ``GPIO_EXTI_UNLOCKED``
     - The EXTI interrupt arises normaly 
   * - ``GPIO_EXTI_LOCKED``
     - The EXTI line is muted at the first interrupt. No more interrupt on this
       line arises until the task voluntary unlock the line

Declaring an IRQ
""""""""""""""""

Declaring some IRQ is made through the use of the ``dev_irq_info_t``
structure: ::

   typedef struct {
       user_handler_t            handler;
       uint8_t                   irq;
       dev_irq_isr_scheduling_t  mode;
       dev_irq_ph_t              posthook;
   } dev_irq_info_t;


The parameters:

   * ``handler`` stores the address of the user defined ISR handler
   * ``irq`` is the IRQ number, given by the kernel
   * ``mode`` is a special field (described below)
   * ``posthook_status`` and ``posthook_data`` are described below

For each IRQ, the task must declare an IRQ handler.
An IRQ handler takes three parameters: ::

   void my_irq_handler (uint8_t irq, uint32_t posthook_status, uint32_t posthook_data);


The IRQ handler is executed in *ISR mode*. It has access to the task content
except for the stack.
It has its own stack, which is erased each time the handler terminates.
By default the termination of an ISR handler awakes its related
task's main thread if it's sleeping or idle.
This behavior can be modified by modifying the ``mode`` field of the 
``dev_irq_info_t`` structure:

.. list-table::
   :widths: 20 80
   :header-rows: 1

   * - ``mode``
     - Description
   * - ``IRQ_ISR_STANDARD``
     - Make main thread runnable
   * - ``IRQ_ISR_FORCE_MAINTHREAD``
     - Make main thread runnable and force its execution
   * - ``IRQ_ISR_WITHOUT_MAINTHREAD``
     - Do not modify main thread's state

The ``IRQ_ISR_FORCE_MAINTHREAD`` may be required by devices needing some
highly responsive software. Because of the not so negligible impact
on the scheduling policy, using this value requires specific permissions.

Note that user ISRs are not executed synchronously:

   * ISR treatment is postponed
   * Acknowledgement of the hardware device's interrupt is not executed by the
     user ISR. It is done by the *posthooks*, described hereafter

Acknowledging interrupts with *posthooks*
"""""""""""""""""""""""""""""""""""""""""

*Posthook* mechanism allows to synchronously acknowledge external interrupts,
when they are handled by the kernel, before their management is postponed
to be managed by a user ISR handler.

Device interrupt acknowledgements may vary from one device to
another. They are usually a sequence of reads, writes or masks of some
device registers. 
EwoK provides a small API to make the kernel managing all these in generic and a safe way.
Posthook API is mostly used to acknowledge hardware device interrupts.  

.. list-table::
   :widths: 20 80
   :header-rows: 1

   * - Posthook action
     - Description
   * - ``IRQ_PH_NIL``
     -   No action
   * - ``IRQ_PH_READ``
     - Reading a value from a device's register
   * - ``IRQ_PH_WRITE``
     - Writing a value into a device's register 
   * - ``IRQ_PH_AND``
     - 
       #. Reads a value from a register (usually a status register)
       #. Mask that value to in order to write only active bits
       #. Might invert the bits
       #. Write the calculated value in a destination register (usually dedicated to acknowledge the interrupt)
   * - ``IRQ_PH_MASK``
     - 
       #. Reads a value from a register
       #. Reads a mask from a register
       #. Mask that value to in order to write only active bits
       #. Might invert the bits
       #. Write the obtained value in a destination register

A device's register is specified as an offset, calculated from the
base of the device's memory space.

.. hint::
   The posthook implementation keeps memory of the *read* in order to avoid
   multiple reads of the same register, which could lead to unexpected
   behaviors (e.g. ToCToU vulnerability) 


As we already see above, an IRQ handler takes three parameters: ::

   void my_irq_handler (uint8_t irq, uint32_t posthook_status, uint32_t posthook_data);

The ``posthook_status`` and ``posthook_data`` parameters may contain values
read during the *posthook* action, and ought to be transmitted to the user handler. 
Most of the time, ``posthook_status`` stores the value read from a status
register while the ``posthook_data`` stores a value read from another device's
register.
If the device declares a posthook
with (at least) two register read, it can also ask for getting back these
registers values as they were at the posthook execution time, by specifying the
very same register offset in the posthook ``status`` and ``data`` fields.

Below is an example for the USART driver: ::

    usart_dev.irqs[0].posthook.status = 0x0000; /* status register */
    usart_dev.irqs[0].posthook.data   = 0x0004; /* data register */

    usart_dev.irqs[0].posthook.action[0].instr = IRQ_PH_READ;
    usart_dev.irqs[0].posthook.action[0].read.offset = 0x0000; /* reading status register */

    usart_dev.irqs[0].posthook.action[1].instr = IRQ_PH_READ;
    usart_dev.irqs[0].posthook.action[1].read.offset = 0x0004; /* reading data register */

    usart_dev.irqs[0].posthook.action[2].instr = IRQ_PH_WRITE;
    usart_dev.irqs[0].posthook.action[2].write.offset = 0x0000; /* write to status register... */
    usart_dev.irqs[0].posthook.action[2].write.value  = 0x00;   /* ...the value 0x0 */
    usart_dev.irqs[0].posthook.action[2].write.mask   = 0x3 << 6; /* using the given write mask
                                                                     (clear TC & Tx status in SR register) */

.. caution::
      * When declaring posthooks, you can only use offsets based on current device base address
      * The offsets must be a part of the device address map
      * The posthook sanitation is done at device declaration time, posthooks cannot be modified

Declaring and initializing a DMA stream
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

A DMA controller is shared among several devices. Thus, its access
by the tasks is mediated by the kernel.

EwoK allows only *memory-to-peripheral* and *peripheral-to-memory* DMA usage.
*Memory-to-memory* is not safe enough and is forbidden in EwoK (since the DMA
controller bypasses the MPU controller, which is obviously very dangerous).

A task can request multiple DMA streams.
Note that it is possible to reconfigure the previously configured stream after
the initialization phase.

.. highlight:: c

The ``dma_t`` structure is the following: ::

    typedef struct {
        physaddr_t in_addr;       /* DMA input base address */
        physaddr_t out_addr;      /* DMA output base address */
        dma_prio_t in_prio;       /* DMA priority for memory to peripheral */
        dma_prio_t out_prio;      /* DMA priority for peripheral to peripheral */
        uint16_t size;            /* DMA buffer size to copy (in bytes) */
        uint8_t dma;              /* DMA controler identifier */
        uint8_t channel;          /* DMA channel to configure */
        uint8_t stream;           /* DMA stream to configure */
        dma_flowctrl_t flow_control; /* DMA Flow controller */
        dma_dir_t dir;            /* Current DMA direction */
        dma_mode_t mode;          /* Current DMA mode */
        bool mem_inc;             /* DMA incremental mode for memory */
        bool dev_inc;             /* DMA incremental mode for device */
        dma_datasize_t datasize;  /* data unit size */
        dma_burst_t mem_burst;    /* type of DMA burst mode */
        dma_burst_t dev_burst;    /* type of DMA burst mode */
        user_dma_handler_t in_handler;  /* DMA ISR for memory to pheripheral */
        user_dma_handler_t out_handler; /* DMA ISR for peripheral to memoryt */
    } dma_t;


A task declaring a ``dma_t`` structure does not have to fill all the fields.
The ``in_handler`, ``out_handler``, ``in_addr``, ``out_addr`` and ``size`` can be
set later, in *nominal mode*. The reason is that a single stream
can be used for sending or receiving data. 

Here is a typical declaration used in the SDIO stack: ::

   dma.channel = DMA2_CHANNEL_SDIO;
   dma.dir = MEMORY_TO_PERIPHERAL; /* write by default */
   dma.in_addr = (physaddr_t) 0;   /* to set later via DMA_RECONF */
   dma.out_addr = (volatile physaddr_t)sdio_get_data_addr();
   dma.in_prio = DMA_PRI_HIGH;
   dma.dma = DMA2;
   dma.size = 0; /* to set later via DMA_RECONF */

   dma.stream = DMA2_STREAM_SDIO_FD;

   dma.mode = DMA_FIFO_MODE;
   dma.mem_inc = 1;
   dma.dev_inc = 0;
   dma.datasize = DMA_DS_WORD;
   dma.mem_burst = DMA_BURST_INC4;
   dma.dev_burst = DMA_BURST_INC4;
   dma.flow_control = DMA_FLOWCTRL_DEV;
   dma.in_handler = (user_dma_handler_t) sdio_dmacallback;
   dma.out_handler = (user_dma_handler_t) sdio_dmacallback;

   ret = sys_init(INIT_DMA, &dma, &dmadesc);

When calling ``sys_init(INIT_DMA, &dma, &dmadesc)``, the ``dmadesc`` identifier
is updated with a unique identifier that can be used later by some syscalls.

Manipulating a DMA
^^^^^^^^^^^^^^^^^^

When calling ``sys_init(INIT_DONE)``, the DMA controller has its clock enabled
if it is not already, but the DMA stream is **not** activated.
To activate the DMA transfer, the task needs to call
``sys_cfg(CFG_DMA_RECONF)``. 
This syscall will configure all the fields involved in the transfer
and launch it if every required field is properly set.
This behavior allows the task to activate the DMA at will, e.g.
when the input buffer is ready, or after receiving a dedicated IPC.


Reconfiguring a DMA stream
""""""""""""""""""""""""""

Most of the time, reconfiguring a DMA stream requires to reconfigure
``in_addr``, ``out_addr`` and ``size`` fields, to set the input/output
addresses involved in the DMA transfer and the size of the transfer.

.. highlight:: c

Here is an example of a DMA reconfiguration: ::

   dma.out_addr = (physaddr_t)buffer;
   dma.size = buf_len;
   ret = sys_cfg(CFG_DMA_RECONF, (void*)&dma, DMA_RECONF_BUFOUT | DMA_RECONF_BUFSIZE);

The fields that can be reconfigured are the following:

   * ISR handlers ``in_handler`` and ``out_handler``
   * Input and output addresses ``in_addr`` and ``out_addr``
   * Transfer size ``size``
   * DMA mode (Circular, FIFO, Direct), ``mode``
   * DMA priority (between other DMA controller tasks), ``in_prio`` and
     ``out_prio``
   * DMA direction, ``dir``

.. note::
   The DMA circular mode does not require any action from 
   the task as the DMA is then fully autonomous (until the user task requires a
   DMA reset to stop the DMA action).


DMA direction is allowed to be reconfigured in the case of DMA streams that
are used for both device read and write access (e.g. SDIO device on
the STM32F4xx boards).

When passing in parameter the ``dma_t`` structure to the ``sys_cfg(CFG_DMA_RECONF)``
syscall, a mask is used to specify which fields are updated.


Reloading a DMA stream
""""""""""""""""""""""

In DMA circular mode, the controller never stops transferring data.  
It is possible to stop this active stream by using
the ``sys_cfg(CFG_DMA_DISABLE)`` syscall.

Then, the task may reactivate this very same stream by using the
``sys_cfg(CFG_DMA_RELOAD)`` syscall.


Declaring and initializing a DMA SHM
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Sometimes, a dataplane may be implemented using multiple tasks communicating
with each others. 
When the internal device dataplane is manipulating DMA
streams, the tasks may wish to optimize the data buffer transfer by using only
DMA transfers between them instead of using manual buffer copy through IPC.

For this case, EwoK allows tasks to voluntarily share a memory
buffer. One of the task, the caller, owns that memory buffer, mapped in its
address space.

The other task, the receiver, will then be able to request DMA transaction
*from* or *toward* this memory buffer, from a given hardware device (e.g. CRYP,
HASH, or any device that reads data stream through DMA requests as input). Note
that this memory buffer is not mapped in the receiver's memory space and
the receiver can therefore never read from or write to it.

Sharing a memory buffer by this mean is subject to specific permissions.

.. note::
   DMA SHM declaration is often associated with IPCs to let the *caller*
   inform the *receiver* of the buffer address and size

.. highlight:: c

Here is a typical usage of DMA SHM buffer: ::

   const uint32_t bufsize = 4096;
   buf[bufsize] = { 0 };

   dma_shm_t dmashm_rd;

   dmashm_rd.target = id_receiver;
   dmashm_rd.source = task_id;
   dmashm_rd.address = (physaddr_t)flash_buf;
   dmashm_rd.size = bufsize;
   /* Receiver can only create DMA request *from* this buffer (read only) */
   dmashm_rd.mode = DMA_SHM_ACCESS_RD;

   printf("Declaring DMA_SHM for read flow\n");
   ret = sys_init(INIT_DMA_SHM, &dmashm_rd);
   printf("sys_init returns %s !\n", strerror(ret));

   sys_init(INIT_DONE);


