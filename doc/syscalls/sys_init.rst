sys_init
--------
EwoK ressource registration API
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Synopsis
""""""""

Initialization request is done by the sys_init() syscall familly.
The sys_init() familly support the following prototypes::

   e_syscall_ret sys_init(INIT_DEVACCESS, device_t*dev, int devfd);
   e_syscall_ret sys_init(INIT_DMA, dma_t*dma, int dmafd);
   e_syscall_ret sys_init(INIT_DMA_SHM, dma_shm_t* dma_shm);
   e_syscall_ret sys_init(INIT_GETTASKID, char*name, uint8_t*id);
   e_syscall_ret sys_init(INIT_DONE);


sys_init(INIT_GETTASKID)
""""""""""""""""""""""""

In order to allow tasks to communicate, they have to be able to uniquely
determine which task is which. This is done by asking the kernel for each
peer identifier during the init sequence (and only during this period).
A task then use the task name (i.e. using a string) to get back the unique
identifier of the target task.

This is done using a specific sys_init familly syscall: INIT_GETTASKID.

Getting a peer task id is done with the following API::

   e_syscall_ret sys_init(INIT_GETTASKID, const char *peername, uint8_t *id);

The id argument is updated with the peer id if it exists and if the task is
authorized to request the peer's id. Otherwise it will be set to 0 and the
syscall will return SYS_E_INVAL;

.. important::
  About permissions: If IPC domains are supported in the kernel, only tasks
  of the same IPC domain can request identifiers of each others.
  See Ewok pemission model.

sys_init(INIT_DEVACCESS)
""""""""""""""""""""""""
This syscall is used to declare a device. A device is composed of:

   * a base address (or 0 if not memory mapped)
   * a size (or 0 if not memory mapped)
   * 0 up to 4 IRQ lines
   * 0 up to 16 GPIOs

Requiring a given device is done with the following API::

   e_syscall_ret sys_init(INIT_DEVACCESS, device_t *dev, int *devdesc);


This syscall is used to declare devices such as:

   * USARTs: memory mapped, one IRQ line, two GPIOs
   * LEDs, Buttons: not memory mapped, no IRQ, one GPIO with possible EXTI line
     (for button)
   * SPI bus: memory mapped, one IRQ line, no GPIO

The number of memory mapped devices is limited due to the MPU constraint. The
maximum of devices (any type) per task is limited to 4. It is possible, for
basic devices such as GPIO, to aggregate them into a single device_t structure.

A typical exemple is a LED driver managing four LEDs. The four GPIOs can be
declared in the very same device_t struct and considered by the kernel as a
single device.

When a device contains one or more GPIO, each GPIO get back in the ``kref``
field of the GPIO structure a unique identifier for the GPIO. This identifier
is uint8_t typed and permit to identify the GPIO for all future configuration
action targetting this very GPIO.

For each IRQ, an ISR should be declared. Although ISR are not executed
synchronously to IRQ handler mode, but are executed in thread mode, in their
own thread in their parent task context. This behavior has been implemented to
disallow any user implementation to be executed in supervisor mode. In the
other hand, there is some counterparts to that:

   * The ISR is postponed a little time after the IRQ handler mode execution
   * All actions usually done in the ISR to acknowledge the hardware device
     interrupt(s) in any of the hardware device registers can't be executed in
     the ISR context. If so, the hardware device generates an IRQ burst leading
     to a deny of service. This problematic is resolved by EwoK posthooks (see
     posthooks in global Ewok documentation)
   * The ISR can execute syncrhonous (only synchronous) syscalls, as ISR are
     user threads with highest priority

For each device, a device descriptor (devdesc), local to the task context, is
set by the kernel. This device descriptor is returned in the devdesc third
argument. This descriptor has the same goal as file descriptors for bigger
kernel such as Linux.

.. hint::
  If the device registration fails, the device descriptor is set to -1.
  Otherwise, the device file descriptor is always a positive value.

.. hint::
  device_t struct may not be keeped by the task after init phase, but when
  using GPIOs, it is important to keep at least the kref value in
  a well-known place for future configuration action

.. important::
  About permissions: Depending on the declared device, the corresponding
  Device ressource permission is required.
  See Ewok pemission model.

.. warning::
  You can't map any devices you wish. Only devices already registered in the
  kernel devmap will be authorized. The kernel devmap is local to the current
  SoC and board. By now it is a C header file hosted in
  *arch/socs/<socname>/soc-devmap.h*. The goal is to use a formal
  representation of it in order to generate this file

sys_init(INIT_DMA)
""""""""""""""""""

Devices declared by the ``sys_init(INIT_DEVACCESS)`` are considered as generic
by the kernel.  DMA are controlled by the kernel and the task has no direct
access on them. As a consequence, they have their own API.

Requiring a DMA channel is done with the following API::

   e_syscall_ret sys_init(INIT_DMA, dma_t *dma, int *dmadesc);

The DMA API (init phase included) is not device oriented but DMA oriented. the
``dma_t`` structure contains fields such as:

   * DMA controller id
   * DMA channel id
   * input and output buffers
   * DMA mode (FIFO, DIRECT, etc.)
   * DMA priority
   * etc...

The kernel checks all the fields and is highly vigilant on the usage of source
and destination buffers in comparison with the task memory map.

For each dma, a dma descriptor (dmadesc), local to the task context, is set by
the kernel. This dma descriptor is returned in the dmadesc third argument.

.. hint::
  If the dma registration fails, the dma descriptor is set to -1. Otherwise,
  the dma file descriptor is always a positive value.
  There is no link between device descriptors and dma descriptors.

.. caution::
  The EwoK DMA implementation deny memory-to-memory copy, reducing DMA usage to
  memory-to-peripheral and peripheral-to-memory only.

.. important::
  About permissions: The Device DMA ressource permission is required. See Ewok
  pemission model.

sys_init(INIT_DMA_SHM)
""""""""""""""""""""""

When multiple tasks take part in a complex data flow with multiple DMA copies
from one device to another (e.g. from a USB high speed device to a SDIO
interface), it may be efficient to support pipelined DMA transfers with low
latency between tasks.

As task have no rights to request a DMA transfer from another task's buffer
toward a device they own, this syscall permit to explicitely declare this
right, based on the Ewok permission model.

Using such mechanism, the task can initiate a DMA transfer from a memory buffer
without any direct access to it, but only toward a given peripheral (e.g. a
CRYP device or an SDIO device).

Sharing a DMA buffer with another task is done with the following API::

   e_syscall_ret sys_init(INIT_DMA_SHM, dma_shm_t *dma_shm);

Declaring a DMA SHM does not create a mapping of the other task's buffer in the
current task memory map. Only the DMA controller is able to access the other
task buffer, as a source or destination of the transaction. The current task is
not able to read or write directly into the buffer. As the MEMORY_TO_MEMORY DMA
transaction is also forbidden, the task is not able to use the DMA to get back
its content from the DMA controller by requesting a copy into its own memory
map.

.. danger::
  Even if this method keep some contermeasures, if not used wisely, this
  mechanism can lead to data leak. That's why there is a full DMA SHM permission
  matrix in the Ewok pemission model. Take a great care with this permission
  and use it only if you know what you do.

.. important::
  About permissions: The IPC_DMA_SHM IPC permission is required between
  the task and its target.


sys_init(INIT_DONE)
"""""""""""""""""""

As previously described, this syscall lock the initialization phase and start
the nominal phase of the task. From now on, the task can execute all syscalls
but the ``sys_init()`` syscalls under its own permission condition.

Finalizing the initialization phase is done with the following API::

   e_syscall_ret sys_init(INIT_DONE);

