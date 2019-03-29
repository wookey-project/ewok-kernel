EwoK syscalls: the complete API explanation
===========================================

.. _ewok-devices:

.. contents::


.. highlight:: c


Declaring and manipulating resources
-------------------------------------

Declaring a device
^^^^^^^^^^^^^^^^^^

Declaring a device is required for any device type other than DMA controllers.
.. highlight:: c

The device structure is the following::

    typedef struct {
       char            name[16];          /**< device name */
       physaddr_t      address;           /**< device base address */
       uint16_t        size;              /**< device size (in bytes) */
       uint8_t         irq_num;           /**< number of device IRQs */
       uint8_t         gpio_num;          /**< number of device associated GPIOs */
       dev_irq_info_t  irqs[MAX_IRQS];    /**< table of IRQ management infos */
       dev_gpio_info_t gpios[MAX_GPIOS];  /**< table of GPIO configurations */
    } device_t;


A device is composed of:

   * A name, recommended to define for console pretty printing
   * A base address, as defined in the datasheet
   * A size, as defined in the datasheet (some exceptions exist, e.g. for the CRYP engine, see the EwoK device map)
   * a list of IRQs and GPIOs, described bellow

All fields of a device are checked at declaration time. The device is activated (including the RCC line(s)) when
the task finishes its initialization section (when calling sys_init(INIT_DONE)). A task cannot declare any other devices
after and cannot modify the device mapping or associated resources list. Nonetheless, the device is directly mapped in
the task memory map and the task and its ISRs can directly access the device's register in RW mode.

.. note::
   Devices can't be mapped by more than one task. They can't be declared two times, even by the same task

.. warning::
   Ada kernel is very strict with the syscall arguments types conformance. When passing structures, it is highly recommended to memset them to 0 before setting their content, otherwise the kernel will probably return SYS_E_INVAL

Declaring a device GPIO
"""""""""""""""""""""""
GPIOs are usually at the heart of embedded devices boards, since they connect the SoC to the outside world. They are sometimes directly accessible to the
user in the form of buttons or leds.

Even if GPIOs are specific devices per se (they are memory mapped, with their own registers), EwoK never allows to directly
map them in the userspace memory layout. The rationale behind this design choice is to avoid wasting memory regions for mapping GPIOs as they are most of
the time only a part of a more complex device block.

Instead, each device requiring them has to declare all the needed GPIOs and their associated configuration, and the microkernel
will enable and configure the GPIO itself.
.. highlight:: c

The device gpio table hosts the following structure::

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

The GPIO structure configuration is GPIO-centric. The device driver defines the usual information about a GPIO such as its mode, speed and type, the potential
alternate function and can use a configuration mask to configure only a subset of the properties (e.g. if there is no alternate function to configure).

The GPIO structure holds a ``kref`` field. This field encodes the GPIO PORT/PIN couple.

Here is an example of a GPIO declaration example::

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


.. note::
   You can declare up to 16 GPIOs per device


**GPIOS and EXTI**

GPIOs can be associated to external interrupts (EXTI). This is
required to asynchronously detect some external events based on GPIOs such as smartcard
insertion/deletion, events on touchscreens, etc.

In this case, it is possible to declare a GPIO as associated to a given EXTI
(External Interrupt) line.
The GPIO structure of the device abstracts the complexity of the EXTI integration
and only requires two fields:

   * exti_trigger: which type of EXTI trigger implies the execution of the handler
   * exti_lock: specify wether the EXTI line has to be muted each time an EXTI interrupt arrises (see sys_cfg(SYS_CFG_UNLOCK_EXTI) syscall manual)
   * exti_handler: the ISR handler to execute

There is no need to declare an IRQ line for the EXTI IRQ as it is fully managed by
the microkernel.

The EXTI trigger is one of the following:

   * GPIO_EXTI_TRIGGER_NONE: no trigger, no external event, default is device_t is memset to 0x0
   * GPIO_EXTI_TRIGGER_RISE: trigger only on rising GPIO (value rising from 0 to 1)
   * GPIO_EXTI_TRIGGER_FALL: trigger only on falling GPIO (value rising from 1 to 0)
   * GPIO_EXTI_TRIGGER_BOTH: trigger each time the GPIO value varies

The EXTI_lock is one of the following:

   * GPIO_EXTI_UNLOCKED: the EXTI line is not muted, the ISR is called each time a new EXTI interrupt arrises
   * GPIO_EXTI_LOCKED: the EXTI line is muted at the first interrupt. There is no more EXTI interrupt on this line while the userspace task doesn't voluntary unlock the associated EXTI line (see sys_cfg(SYS_CFG_UNLOCK_EXTI) syscall manual)

Declaring a device IRQ
""""""""""""""""""""""

The device IRQ declaration structure is the following::

   typedef struct {
       user_handler_t            handler;
       uint8_t                   irq;
       dev_irq_isr_scheduling_t  mode;
       dev_irq_ph_t              posthook;
   } dev_irq_info_t;


When a device driver declares a device, it usually declares how it manages its associated IRQs.
For each IRQ, the user task must use a function as IRQ handler.

This function has three parameters:

   * the IRQ number, given by the kernel
   * the first register read by the IRQ posthooks, if configured (see later)
   * the second register read by the IRQ posthooks, if configured (see later)

with the following prototype::

   void handler(uint8_t irq, uint32_t sr, uint32_t dr);

The IRQ handler is executed with its own stack in ISR mode.
This handler will have access to the task content (variables, functions, etc.) but can't modify
the task's context (task's main thread stack or processor state). IRQ handlers can only execute
synchronous syscalls (meaning mostly sys_cfg(), sys_reset() and sys_get_systick() syscalls, syscalls documentation
describes for each syscall if they can be executed in this context). Others are
denied and will return SYS_E_DENIED.

.. note::
   It is possible to use the same function for multiple IRQs, as the IRQ number is passed as first argument of the function

By default, ISR execution awakes the task's main thread (make it runnable). This behavior can
be modified by modifying the ``mode`` field of the IRQ declaration. This
flag is based on the following enumerate::

   typedef enum {
     IRQ_ISR_STANDARD = 0,           /**< make main thread runnable */
     IRQ_ISR_FORCE_MAINTHREAD = 1,   /**< next slot will execute main thread */
     IRQ_ISR_WITHOUT_MAINTHREAD = 2, /**< no impact on main thread state */
   } dev_irq_isr_scheduling_t;


.. note::
   By default, when a task ISR is executed, the task main thread is awaken if it is idle. It is
   nevertheless possible to deactivate this feature and work on full ISR mode (without any main
   thread execution)

Sometimes, there is a need for high reactivity between the ISR execution and the
main thread execution. This is the case when the device driver hosts the main device automaton in
its main thread and uses the ISR handlers only for flags management (i.e. to notify states transitions).

Forcing the main thread execution happens one time per ISR execution. Until the main thread yields
or is scheduled, there is no more forced execution before the next ISR execution.
As this behavior is highly impacting, its is associated to a specific permission (see EwoK permissions).
Only tasks with this permissions are allowed to declare forced execution for some of their ISRs.

ISRs are not executed synchronously to IRQ handler mode, but
in thread mode, in their own thread in their parent task context. This behavior has been implemented to disallow any user implementation
to be executed in supervisor mode. On the other hand, there are some drawbacks to this design choice:

   * The ISR is postponed a little time after the IRQ handler mode execution
   * All actions usually done in the ISR to acknowledge the hardware device interrupt(s) in any of the hardware device registers can't
     be executed in the ISR context. If so, the hardware device generates an IRQ burst leading to a denial of service. This is
     resolved by EwoK posthooks, described hereafter

**About Posthooks**

Posthooks are mechanisms to execute controlled actions in handler mode
in order to replace a synchronously executed ISRs. It mostly acknowledges hardware devices interrupts.
Device interrupts acknowledges vary from one device to another, but are classically a sequence of reads, writes or masks of
some device registers. As a consequence, EwoK provides a small programming interface in order to explain to the kernel which
read/write or mask needs to be done on the device registers. These actions are easy to check in term of security
and provide a way to encode elaborated sequences of registers access at the end of the IRQ handler execution.

The user device driver can declare four types of action:

   * IRQ_PH_NIL:   no action
   * IRQ_PH_READ:  reading a register of the device
   * IRQ_PH_WRITE: writing a register of the device
   * IRQ_PH_AND:   executing a boolean AND between two register of the device, with a possible 32bit mask
   * IRQ_PH_MASK:  executing a mask between one register and another, and executing a boolean AND with a third one

All register addresses are specified as an offset starting at the beginning of the specific device memory map (i.e. the address provided in the device datasheet).

.. note::
   Posthook declaration complexity may vary from very easy (e.g. USART devices, which require only IRQ_PH_READ) to very complex (e.g. USB devices, requiring multiple READ, AND and MASK)

.. hint::
   It is advised to declare read actions first, as the posthook implementation keeps the memory of all read registers and avoids any multiple read of the same register to avoid ToCToU (Time of Check - Time of Use) invalid behavior

.. caution::
   The posthook field hosts an action table. The number of actions is not explicitly set, as it is fully parsed. It is wise to memset the device_t structure to 0 to default all posthook actions to IRQ_PH_NIL by default before setting the device. Any invalid content will be rejected by the kernel at device registering time.

ISR Handlers have three arguments, passed by the kernel:

   * The IRQ number
   * The sr (most of the time status register) value, passed by the kernel and read at IRQ handler time
   * the dr (most of the time a data register, a mask register or any other) value, passed by the kernel and read at IRQ handler time

Without posthooks, sr and dr values are 0x0. If the device declares a posthook with (at least) two register read, it can also ask for getting back these registers
values as they were at the posthook execution time, by specifying the very same register offset in the poshook ``status`` (for sr) and ``data`` (for dr) fields.

This allows to get back values from registers having their content changing when they are read or that may dynamically change between posthooks time (during handler mode) and ISR time (in thread mode, a little later).

.. hint::
   The proper way to implement an ISR handler is to ask the kernel to read the usual registers such as status and mask registers during posthooks. These
   registers should not be read again after, using sr and dr local variables instead, to avoid ToCToU risks.

Here is the example of posthook declaration for an USART driver. USART requires that the device DR register is read to
stop sending IRQs. SR gives the current device state. Posthook is then easy to declare::

    usart_dev.irqs[0].posthook.status = 0x0000; /* SR register */
    usart_dev.irqs[0].posthook.data   = 0x0004; /* DR register */

    usart_dev.irqs[0].posthook.action[0].instr = IRQ_PH_READ;
    usart_dev.irqs[0].posthook.action[0].read.offset = 0x0000; /* reading SR register */

    usart_dev.irqs[0].posthook.action[1].instr = IRQ_PH_READ;
    usart_dev.irqs[0].posthook.action[1].read.offset = 0x0004; /* reading DR register */

    usart_dev.irqs[0].posthook.action[2].instr = IRQ_PH_WRITE;
    usart_dev.irqs[0].posthook.action[2].write.offset = 0x0000; /* write to SR register... */
    usart_dev.irqs[0].posthook.action[2].write.value  = 0x00;   /* ...the value 0x0 */
    usart_dev.irqs[0].posthook.action[2].write.mask   = 0x3 << 6; /* using the given write mask
                                                                     (clear TC & Tx status in SR register) */

For the USB Full-Speed device, the device IRQ multiplexes various events that need to be checked against the
status registers. Some events require specific masking to avoid IRQ bursts. Posthook declaration is more complex::

    /* getting back SR and MSK */
    dev.irqs[0].posthook.status = 0x0014; /* SR register */
    dev.irqs[0].posthook.data   = 0x0018;   /* Interrupt mask register */

    dev.irqs[0].posthook.action[0].instr = IRQ_PH_READ;
    dev.irqs[0].posthook.action[0].read.offset = 0x0014; /* reading SR register */

    dev.irqs[0].posthook.action[1].instr = IRQ_PH_READ;
    dev.irqs[0].posthook.action[1].read.offset = 0x0018; /* reading interrupt msk register */

    /* Masking currently activated interrupt(s) in SR */
    dev.irqs[0].posthook.action[2].instr = IRQ_PH_MASK;
    dev.irqs[0].posthook.action[2].mask.offset_src = 0x14;  /* read SR register... */
    dev.irqs[0].posthook.action[2].mask.offset_dest = 0x14; /* and write it to itself... */
    dev.irqs[0].posthook.action[2].mask.offset_mask = 0x18; /* using a binary mask based on MASK register value */
    dev.irqs[0].posthook.action[2].mask.mode = 0;           /* with binary inversion (write 1 if status bit is 1) */

    /* Some specific interrupts need masking in interrupt MSK too */
    dev.irqs[0].posthook.action[3].instr = IRQ_PH_AND;
    dev.irqs[0].posthook.action[3].and.offset_src = 0x14;   /* read SR register... */
    dev.irqs[0].posthook.action[3].and.offset_dest = 0x18;  /* writing to MASK register... */
    dev.irqs[0].posthook.action[3].and.mask = USB_FS_GINTMSK_RXFLVLM_Msk; /* Using a fixed 1 bit mask */
    dev.irqs[0].posthook.action[3].and.mode = 1; /* with binary inversion (write 0 if status bit is 1) */

    dev.irqs[0].posthook.action[4].instr = IRQ_PH_AND;
    dev.irqs[0].posthook.action[4].and.offset_src = 0x14; /* read SR register... */
    dev.irqs[0].posthook.action[4].and.offset_dest = 0x18; /* writing to MASK register... */
    dev.irqs[0].posthook.action[4].and.mask = USB_FS_GINTMSK_IEPINT_Msk; /* Using another fixed 1 bit mask */
    dev.irqs[0].posthook.action[4].and.mode = 1; /* with binary inversion (write 0 if status bit is 1) */

    dev.irqs[0].posthook.action[5].instr = IRQ_PH_AND;
    dev.irqs[0].posthook.action[5].and.offset_src = 0x14; /* read SR register... */
    dev.irqs[0].posthook.action[5].and.offset_dest = 0x18; /* writing to MASK register... */
    dev.irqs[0].posthook.action[5].and.mask = USB_FS_GINTMSK_OEPINT_Msk; /* Using another fixed 1 bit mask */
    dev.irqs[0].posthook.action[5].and.mode = 1; /* with binary inversion (write 0 if status bit is 1) */

.. caution::
      * When declaring posthooks, you can only use offsets based on current device base address
      * The offsets must be a part of the device address map
      * The posthook sanitation is done at device declaration time, posthooks can't be modified

Declaring a DMA
^^^^^^^^^^^^^^^

When using EwoK, DMA are not considered as general purpose devices.
A userspace driver:

   * is not allowed to map a DMA controller (or any part of it)
   * has no way other than syscalls to (re)configure the DMA stream
   * uses a DMA oriented specific interface to declare the DMA as a
     specific resource, when it has the associated permission (see :ref:`EwoK permissions <ewok-perm>`)

EwoK allows only memory to peripheral and peripheral to memory DMA usage. Memory-to-memory, even with a fully controlled slot filtering, is a dangerous usage
of DMA controllers. This reduces the usage of DMA streams that are
hard-linked to System On Chip devices in the DMA controllers hardware design.

A task can declare multiple DMA if the channel and stream couple is not already used.
It can reconfigure some parts of the previously configured stream after the
initialization phase but is not able to reconfigure elements such as the
controller, the stream or the channel identifier.
.. highlight:: c

The DMA structure is the following::

   typedef struct {
   	  physaddr_t in_addr;	    /**< DMA input base address */
      physaddr_t out_addr;	    /**< DMA output base address */
   	  dma_prio_t in_prio;	    /**< DMA priority for memory to peripheral */
   	  dma_prio_t out_prio;	    /**< DMA priority for peripheral to peripheral */
   	  uint16_t size;		    /**< DMA buffer size to copy (in bytes) */
   	  uint8_t dma;		        /**< DMA controler identifier */
      uint8_t channel;	        /**< DMA channel to configure */
   	  uint8_t stream;		    /**< DMA stream to configure */
      dma_flowctrl_t flow_control; /**< DMA Flow controller */
   	  dma_dir_t dir;		    /**< Current DMA direction */
   	  dma_mode_t mode;	        /**< Current DMA mode */
   	  bool mem_inc;		        /**< DMA incremental mode for memory */
   	  bool dev_inc;		        /**< DMA incremental mode for device */
   	  dma_datasize_t datasize;  /**< data unit size */
   	  dma_burst_t mem_burst;	/**< type of DMA burst mode */
   	  dma_burst_t dev_burst;	/**< type of DMA burst mode */
   	  user_dma_handler_t in_handler;  /**< DMA ISR for memory to pheripheral */
   	  user_dma_handler_t out_handler; /**< DMA ISR for peripheral to memoryt */
   } dma_t;


Most of the time, a task declaring a DMA does not fill all the fields of the
DMA structure. Usually, the ISR handlers and buffers are set later in the
application implementation, as they can vary during the application execution.

Here is a typical declaration used in the SDIO stack::

   dma.channel = DMA2_CHANNEL_SDIO;
   dma.dir = MEMORY_TO_PERIPHERAL; /* write by default */
   dma.in_addr = (physaddr_t) 0; /* to set later via DMA_RECONF */
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

When calling sys_init(INIT_DMA, &dma, &dmadesc), the dmadesc identifier is
updated with a unique identifier that can be used later for the sys_init(CFG_DMA_RELOAD) syscall.

At that time, if the DMA stream is not already used and the task have the
necessary permissions and space in its task structure to map it, the DMA
is registered. There is no specific hardware event associated to this
syscall.

Manipulating a DMA
^^^^^^^^^^^^^^^^^^

When calling sys_init(INIT_DONE), the DMA controller has its clock enabled if
it is not already, but the DMA stream is **not** activated. There is still
some missing fields in this structure:

   * in_addr is not set
   * size is not set

To effectively activate the DMA (and launch it in the same time), the task
needs to call sys_cfg(CFG_DMA_RECONF). This syscall will configure all the
missing fields and activate the DMA stream if everything is there.

This behavior allows the task to activate the DMA at will, e.g.
when the input buffer is ready, or after receiving a dedicated IPC.


Reconfiguring a DMA stream
""""""""""""""""""""""""""

Reconfiguring a DMA stream most of the time requires to reconfigure
the buffer address and size (when using flip/flop buffers, or FIFO mode).
Only the DMA circular mode does not require any action as the DMA is fully
autonomous until the user task requires a DMA reset to stop the DMA action.
.. highlight:: c

Here is a typical, easy, DMA reconfiguration::

   dma.out_addr = (physaddr_t)buffer;
   dma.size = buf_len;
   ret = sys_cfg(CFG_DMA_RECONF, (void*)&dma, DMA_RECONF_BUFOUT | DMA_RECONF_BUFSIZE);

The fields that can be reconfigured at sys_cfg time are the following:

   * ISR handlers address
   * buffers address
   * buffers size
   * DMA mode (Circular, FIFO, Direct)
   * DMA priority (between other DMA controller tasks)
   * DMA direction

DMA direction is allowed to be reconfigured in the case of DMA streams that
are used for both device read and write access. This is the case for example
for SDIO device on STM32F4xx, where the same DMA stream is used for both directions.

As the entire dma structure is passed at CFG_DMA_RECONF time, a mask is used to
specify which fields in all the reconfigurable ones need to be updated.

This mask is defined in the ``dma_reconf_mask_t`` enumeration. This also reduces
the cost of the DMA reconfiguration syscall.

A task can only reconfigure a DMA controller it already holds. The DMA fixed fields must not be modified by the task, or
any reconfiguration of the DMA will be refused.

Reloading a DMA stream
""""""""""""""""""""""

For some specific DMA usage like circular DMA streams, the task doesn't need
to reconfigure the input or output buffer and size. The DMA controller is
looping on the content of a given buffer without stopping.
In this case, the user task would require to stop the DMA when executing
the Transfer Complete ISR, and reloading it later.

It is then possible to stop the DMA by simply disabling the stream.
This is done using the sys_cfg(CFG_DMA_DISABLE) syscall::

   ret = sys_cfg(CFG_DMA_DISABLE, dmadesc);

This syscall stops the current DMA transfer by clearing the DMA stream enable bit.

.. caution::
   Most of the time, DMAs require a reload or reconf action each time the Transfer Complete interrupt is executed, as the DMA is waiting for a software intruction to continue


.. hint::
   Only exceptions to explicit DMA reconf/reload at each end of DMA transfer happen when:
      * DMA is not its own flow controller (when another device manages the DMA transfers)
      * DMA is in circular mode (the DMA is looping on a buffer content)


When the task needs to restart the DMA without modifying the content of the
dma_t structure, it can use the DMA identifier without passing the overall
DMA structure to the kernel.

It can then use the CFG_DMA_RELOAD syscall::

   ret = sys_cfg(CFG_DMA_RELOAD, dma->id);

The associated DMA stream is then re-enabled.

Declaring a DMA SHM
^^^^^^^^^^^^^^^^^^^

Sometimes, a dataplane may be implemented using multiple tasks communicating with
each others. When the internal device dataplane is manipulating DMA streams, the
tasks may whish to optimize the data buffer transfer by using only DMA transfer
between them instead of using manual buffer copy through IPC. This is the case
in the Wookey project in which data buffers are transmitted through the CRYP device
(in order to en(de)crypt data on the go, without requiring manual data copy between
tasks.

For this case, EwoK permits to a given tasks couple to voluntary share a memory buffer.
One of the task (the caller) is the owner of the memory buffer region and has it mapped
in its own slot.

The other task (the receiver), will then be able to request DMA transaction *from* or
*toward* this memory buffer and a given hardware device (e.g. CRYP, HASH, or any device
that read data stream through DMA requests as input).
The receiver can never access to the memory buffer directly, and the memory buffer is
never mapped in the receiver memory slots.

Sharing a memory buffer as a DMA SHM is controlled by the DMA SHM permission matrix.
This permission matrix works in the same way the IPC matrix does, by creating one way
communication channels between two tasks.

.. note::
   As DMA SHM memory buffer address is usually not fixed at compile or build time,
   DMA SHM declaration is often associated to an IPC which inform the receiver of the
   buffer address and size

Here is a typicall usage of DMA SHM buffer::

   const uint32_t bufsize = 4096;
   buf[bufsize] = { 0 };

   dma_shm_t dmashm_rd;

   dmashm_rd.target = id_receiver;
   dmashm_rd.source = task_id;
   dmashm_rd.address = (physaddr_t)flash_buf;
   dmashm_rd.size = bufsize;
   /* receiver can only create DMA request *from* this buffer (read only) */
   dmashm_rd.mode = DMA_SHM_ACCESS_RD;

   printf("Declaring DMA_SHM for read flow\n");
   ret = sys_init(INIT_DMA_SHM, &dmashm_rd);
   printf("sys_init returns %s !\n", strerror(ret));

   sys_init(INIT_DONE);

   /* [...] */
   /* Sending an IPC to the receiver giving it buf addr and size */
   // sys_ipc(IPC_SEND_SYNC, id_receiver, ...);
