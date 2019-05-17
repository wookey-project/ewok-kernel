.. _sys_init:

*sys_init*, initializing devices
--------------------------------

Devices declaration, initialization and configuration is done with the help of
the ``sys_init()`` syscall family.

.. contents::

sys_init(INIT_GETTASKID)
^^^^^^^^^^^^^^^^^^^^^^^^

If a task *A* wants to communicate with another task *B*, task *A* needs
to retrieve task's *B* identifier.

.. note::
   * Each running task is identified by a unique identifier: its *task id*.
     A task have also a name, given by the implementor, to ease its
     identification.
   * If IPC *domains* are supported by the kernel, only tasks
     in the same *domain* can identify each other.

Getting a *task id* is done with ``sys_init(INIT_GETTASKID)`` syscall: ::

    uint8_t        peer_id;
    e_syscall_ret  ret;

    ret = sys_init(INIT_GETTASKID, "task_b", &peer_id);
    if (ret != SYS_E_DONE) {
        ...
    }

In the example above, if the call is succesful, the ``peer_id`` parameter is
updated with the *task id*.


sys_init(INIT_DEVACCESS)
^^^^^^^^^^^^^^^^^^^^^^^^

If a task wants to use a device, it must request it to the kernel
using the ``sys_init(INIT_DEVACCESS)`` syscall.

.. warning::
   DMA streams are not initialized with ``sys_init(INIT_DEVACCESS)``
   but with ``sys_init(INIT_DMA)``

To make that request, a ``device_t`` structure,
whose prototype is defined in ``kernel/src/C/exported/devices.h``, must be
filled. That structure describes the requested device.
Its content is:

.. code-block:: C

    typedef struct {
        char          	  name[16];
        physaddr_t    	  address;
        uint32_t      	  size;
        uint8_t       	  irq_num;
        uint8_t       	  gpio_num;
        dev_map_mode_t    map_mode;
        dev_irq_info_t    irqs[MAX_IRQS];
        dev_gpio_info_t   gpios[MAX_GPIOS];
    } device_t;

The fields of the ``device_t`` structure are explained here:

   * ``name`` contains a name, useful for debugging purposes
   * ``address`` is the base address of the device in memory (0 if the device
     is not mapped in memory)
   * ``size`` is the size of the mapping in memory (0 if the device is not
     mapped in memory)
   * ``irq_num`` is the number of configured IRQs in the ``irqs[]`` array
   * ``gpio_num`` is the number of configured GPIOs in the ``gpios[]`` array
   * ``map_mode`` tell if the device must be automatically mapped in task's
     address space.
   * 0 up to 4 *IRQ lines* are defined in ``irqs[]`` array
   * 0 up to 16 *GPIOs* are defined in ``gpios[]`` array

Below is an example, excerpt from the :ref:`blinky` demo:

.. code-block:: C

    device_t    leds;
    int         desc_leds;

    memset (&leds, 0, sizeof (leds));

    strncpy (leds.name, "LEDs", sizeof (leds.name));
    leds.gpio_num = 4; /* Number of configured GPIO */

    leds.gpios[0].kref.port = GPIO_PD;
    leds.gpios[0].kref.pin = 12;
    leds.gpios[0].mask     = GPIO_MASK_SET_MODE | GPIO_MASK_SET_PUPD |
                             GPIO_MASK_SET_TYPE | GPIO_MASK_SET_SPEED;
    leds.gpios[0].mode     = GPIO_PIN_OUTPUT_MODE;
    leds.gpios[0].pupd     = GPIO_PULLDOWN;
    leds.gpios[0].type     = GPIO_PIN_OTYPER_PP;
    leds.gpios[0].speed    = GPIO_PIN_HIGH_SPEED;

    leds.gpios[1].kref.port = GPIO_PD;
    leds.gpios[1].kref.pin = 13;
    leds.gpios[1].mask     = GPIO_MASK_SET_MODE | GPIO_MASK_SET_PUPD |
                             GPIO_MASK_SET_TYPE | GPIO_MASK_SET_SPEED;
    ...

    ret = sys_init(INIT_DEVACCESS, &leds, &desc_leds);

In this example:

   * ``leds`` parameter is a ``device_t`` structure that describes the
     requested device. Here, the leds on the *stm32f407* board.
   * ``desc_leds`` is a *device id* returned by the syscall. It's not
     very useful here as the *device id* is used only in
     some few syscalls (``sys_cfg(CFG_DEV_MAP)`` and ``sys_cfg(CFG_DEV_UNMAP)``)

Mapping devices in memory
"""""""""""""""""""""""""
Due to MPU constraints on Cortex-M, a task can not map simultaneously more than
4 devices in memory.

If a task needs to manage more than 4 devices, it should use the
syscalls ``sys_cfg(CFG_DEV_MAP)`` and ``sys_cfg(CFG_DEV_UNMAP)`` to voluntary
map and unmap the desire devices. Those syscalls can be used only if:

  * ``map_mode`` field of the ``device_t`` structure is set to ``DEV_MAP_VOLUNTARY``
  * the task is granted with a specific permission to do this (set in the
    *menuconfig* kernel menu).

Using GPIOs
"""""""""""
Each GPIO port/pin pair is identified by a ``kref`` value. That value
must be filled in when using the ``sys_cfg(CFG_GPIO_GET)`` and
``sys_cfg(CFG_GPIO_GET)`` syscalls (see :ref:`sys_cfg`).

IRQ handler
"""""""""""
For each IRQ, an *Interrupt Service Routine* (ISR) should be declared.
Here is an example excerpt from the :ref:`demo` :

.. code-block:: C

    memset (&button, 0, sizeof (button));
    strncpy (button.name, "BUTTON", sizeof (button.name));

    button.gpio_num = 1;
    button.gpios[0].kref.port   = button_dev_infos.gpios[BUTTON].port;
    button.gpios[0].kref.pin    = button_dev_infos.gpios[BUTTON].pin;
    button.gpios[0].mask        = GPIO_MASK_SET_MODE | GPIO_MASK_SET_PUPD |
                                  GPIO_MASK_SET_TYPE | GPIO_MASK_SET_SPEED |
                                  GPIO_MASK_SET_EXTI;
    button.gpios[0].mode        = GPIO_PIN_INPUT_MODE;
    button.gpios[0].pupd        = GPIO_PULLDOWN;
    button.gpios[0].type        = GPIO_PIN_OTYPER_PP;
    button.gpios[0].speed       = GPIO_PIN_LOW_SPEED;
    button.gpios[0].exti_trigger = GPIO_EXTI_TRIGGER_RISE;
    button.gpios[0].exti_lock    = GPIO_EXTI_UNLOCKED;
    button.gpios[0].exti_handler = (user_handler_t) exti_button_handler;

    /* Now that the button device structure is filled, use sys_init to
     * initialize it */
    ret = sys_init(INIT_DEVACCESS, &button, &desc_button);


sys_init(INIT_DMA)
^^^^^^^^^^^^^^^^^^

If a task wants to use a DMA stream, it must request it to the kernel
using the ``sys_init(INIT_DMA)`` syscall.
To make that request, a ``dma_t`` structure,
whose prototype is defined in ``kernel/src/C/exported/dma.h``, must be
filled. That structure describes the requested DMA stream.
Its content is:

.. code-block:: C

    typedef struct {
        uint8_t dma;            /* DMA controler identifier (1 for DMA1, 2 for DMA2, etc.) */
        uint8_t stream;
        uint8_t channel;
        uint16_t size;          /* Transfering size in bytes */
        physaddr_t in_addr;     /* Input base address */
        dma_prio_t in_prio;     /* Priority */
        user_dma_handler_t in_handler;  /* ISR with one argument (irqnum), see types.h */
        physaddr_t out_addr;    /* Output base address */
        dma_prio_t out_prio;    /* Priority */
        user_dma_handler_t out_handler; /* ISR with one argument (irqnum), see types.h */
        dma_flowctrl_t flow_control;    /* Flow controller */
        dma_dir_t dir;          /* Transfert direction */
        dma_mode_t mode;        /* DMA mode */
        dma_datasize_t datasize;    /* Data unit size (byte, half-word or word) */
	bool mem_inc;           /* Increment for memory */
	bool dev_inc;           /* Increment for device */
        dma_burst_t mem_burst;  /* Memory burst size */
        dma_burst_t dev_burst;  /* Device burst size */
    } dma_t;

Example:

.. code-block:: C

    dma.dma = DMA2;
    dma.stream = DMA2_STREAM_SDIO_FD;
    dma.channel = DMA2_CHANNEL_SDIO;
    dma.size = 0;                   /* Set later with DMA_RECONF */
    dma.in_addr = (physaddr_t) 0;   /* Set later with DMA_RECONF */
    dma.in_prio = DMA_PRI_HIGH;
    dma.in_handler = (user_dma_handler_t) sdio_dmacallback;
    dma.out_addr = (volatile physaddr_t)sdio_get_data_addr();
    dma.out_handler = (user_dma_handler_t) sdio_dmacallback;
    dma.flow_control = DMA_FLOWCTRL_DEV;
    dma.dir = MEMORY_TO_PERIPHERAL;
    dma.mode = DMA_FIFO_MODE;
    dma.datasize = DMA_DS_WORD;
    dma.mem_inc = 1;
    dma.dev_inc = 0;
    dma.mem_burst = DMA_BURST_INC4;
    dma.dev_burst = DMA_BURST_INC4;

    ret = sys_init(INIT_DMA, &dma, &dma_descriptor);

In this example, the ``dma_descriptor`` is an identifier returned by the
syscall and used by the ``sys_cfg(CFG_DMA_RECONF)`` and
``sys_cfg(CFG_DMA_RELOAD)`` syscalls.

.. note::
  For the sake of security, the EwoK DMA implementation denies
  *memory-to-memory* transfers.

sys_init(INIT_DMA_SHM)
^^^^^^^^^^^^^^^^^^^^^^

When multiple tasks take part in a complex data flow with multiple DMA copies
from one device to another (e.g. from a USB High Speed device to the SDIO
interface), it may be efficient to support pipelined DMA transfers with low
latency between tasks.

As tasks have no rights to request a DMA transfer from another task's buffer
toward a device they own, this syscall allows to explicitly declare this
right, based on the Ewok permission model.

Using such a mechanism, the task can initiate a DMA transfer from a foreign
memory buffer without any direct access to it, but only toward a given peripheral (e.g. a
CRYP device or an SDIO device).

Sharing a DMA buffer with another task is done with the following API::

   e_syscall_ret sys_init(INIT_DMA_SHM, dma_shm_t *dma_shm);

Declaring a DMA SHM does not create a mapping of the other task's buffer in the
current task memory map. Only the DMA controller is able to access the other
task's buffer, as a source or destination of the transaction. The current task is
not able to read or write directly into the buffer. As the MEMORY_TO_MEMORY DMA
transaction is also forbidden, the task is not able to use the DMA to get back
its content from the DMA controller by requesting a copy into its own memory
map.

sys_init(INIT_DONE)
^^^^^^^^^^^^^^^^^^^

As previously described, this syscall locks the initialization phase and starts
the nominal phase of the task. From now on, the task can execute all syscalls
but the ``sys_init()`` one under its own permission condition.

Finalizing the initialization phase is done with the following API::

   e_syscall_ret sys_init(INIT_DONE);

