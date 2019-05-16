.. _sys_cfg:

*sys_cfg*, configuring devices
------------------------------

The resources (GPIOs, DMA, etc.) reconfiguration request is done by the
sys_cfg() syscall family.

.. contents::


sys_cfg(CFG_GPIO_SET)
^^^^^^^^^^^^^^^^^^^^^

GPIOs are not directly mapped in the task's memory. As a consequence, setting
the GPIO output value is done using a syscall. 
The GPIO must be registered as output for the syscall to succeed.
Only the GPIO kref is needed by this syscall, see the ``sys_init(INIT_DEVACCESS)``
explanations about kref for further details.

Setting an output GPIO is done with the following API::

   e_syscall_ret sys_cfg(CFG_GPIO_SET, uint8_t gpioref, uint8_t value);

The value set is the third argument.

.. important::
  The GPIO to set must have been previously declared as output in the initialization phase.

sys_cfg(CFG_GPIO_GET)
^^^^^^^^^^^^^^^^^^^^^

Getting a GPIO value for a GPIO configured in input mode is done using a syscall.
Only the GPIO kref is needed by this syscall, see the ``sys_init(INIT_DEVACCESS)``
explanations about kref for further details.

Getting an input value of a GPIO is done with the
following API::

   e_syscall_ret sys_cfg(CFG_GPIO_GET, uint8_t gpioref, uint8_t *val);

The value read is put in the third argument.

.. important::
  The GPIO queried must have been previously declared as input in the
  initialization phase.

sys_cfg(CFG_GPIO_UNLOCK_EXTI)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. note::
   Synchronous syscall, executable in ISR mode

There are times when external interrupts may:
   * Arise only one time and need to be muted voluntarily for a given amount of
     time
   * Be unstable and generate uncontrolled bursts, when the external IP is not
     clean and has hardware bugs

For these two cases, the EwoK kernel supports a specific GPIO
configuration which allows, when an EXTI interrupt is configured, to choose
whether:

   * The EXTI line is masked at handler time, by the kernel. The user ISR will be
     executed but there will be no more EXTI interrupts pending on the
     interrupt line
   * The EXTI line is not masked, and the EXTI is only acknowledged. The EXTI
     source can continue to emit other interrupts and the userspace ISR handler
     will be executed for each of them

The choice is done using the `exti_lock` field of the gpio structure, using
either:

   * GPIO_EXTI_UNLOCKED value: the EXTI line is not masked and will continue to
     arise when the external HW IP emits events
   * GPIO_EXTI_LOCKED value: the EXTI line is masked once the interrupt
     has been scheduled for beeing serviced. The userspace task needs to 
     unmask it voluntarily using the apropriate syscall. No other EXTI will 
     be received without unmasking.

Unmasking a given EXTI interrupt is done using the ``sys_cfg(CFG_GPIO_UNLOCK_EXTI)``
syscall. This syscall has the following API::

   e_syscall_ret sys_cfg(CFG_GPIO_EXTI_UNLOCK, uint8_t gpioref);
  
The gpioref parameter is the kref identifier of the GPIO, like the one used in the
other GPIO manipulation syscalls. Unlocking the EXTI line is a synchronous
syscall.


sys_cfg(CFG_DMA_RECONF)
^^^^^^^^^^^^^^^^^^^^^^^

.. note::
   Synchronous syscall, executable in ISR mode

DMA operations are performed by EwoK microkernel on the behalf of userspace tasks.
After completion of a DMA transfert the DMA channel is disable until it is either reloaded or reconfigurated.
For allowing the user to change the input/output buffers of a DMA channel, it is permittd to reconfigure part
of the DMA channel information. 

Only some fields of the ``dma_t`` can be reconfigured :

   * ISR handlers address
   * Input buffer address (for memory to peripheral mode)
   * Output buffer address (for peripheral to memory mode)
   * Buffer size
   * DMA mode (direct, FIFO or circular)
   * DMA priority

Reconfiguring a part of a DMA stream is done with the following API::

   e_syscall_ret sys_cfg(CFG_DMA_RECONF, dma_t*dma, dma_reconf_mask_t
   reconfmask);

The mask parameter allows the user to specify which field(s) need(s) to be 
reconfigured.

As these fields are a part of the ``dma_t`` structure (see Ewok kernel API
technical reference documentation), the syscall requires this entire structure.


.. hint::
   The easiest way to use this syscall is to keep the dma_t structure used
   during the initialization phase and to update it during the nominal phase

.. important::
   The DMA that needs to be reconfigured must have been previously declared in
   the initialization phase.

sys_cfg(CFG_DMA_RELOAD)
^^^^^^^^^^^^^^^^^^^^^^^

.. note::
   Synchronous syscall, executable in ISR mode

When a DMA tranfert is finished, the corresponding DMA channel is disable until
it is either reloaded or reconfigurated.
A reload can be performed when the DMA controller is requested to redo exactly
the same action, without any modification of the DMA channel properties. 
Reloading a DMA channel is faster than reconfiguring it.
The kernel only needs to identify the DMA controller and stream, and does not
need a whole DMA structure. The task can then use only the ``id`` field of the
``dma_t`` structure.

Reloading a DMA stream is done with the following API::

   e_syscall_ret sys_cfg(CFG_DMA_RELOAD, uint32_t dma_id);

.. important::
  The DMA that needs to be reloaded must have been previously declared in the
  initialization phase.

sys_cfg(CFG_DMA_DISABLE)
^^^^^^^^^^^^^^^^^^^^^^^^

.. note::
   Synchronous syscall, executable in ISR mode

It is possible to disable a DMA stream. In this case, the DMA channel is stopped and
can be re-enabled by calling one of sys_cfg(CFG_DMA_RELOAD) or
sys_cfg(CFG_DMA_RECONF) syscalls.

This is useful for DMA streams in circular mode, as they never stop unless the
software asks them to.

Disabling a DMA stream is done with the following API::

   e_syscall_ret sys_cfg(CFG_DMA_DISABLE, uint32_t dma_id);

.. important::
  The DMA that needs to be disabled must have been previously declared in the
  initialization phase.

sys_cfg(CFG_DEV_MAP)
^^^^^^^^^^^^^^^^^^^^

.. note::
   Synchronous syscall, executable only in main thread mode

Ewok Microkernel allows a task to map only a restricted number of devices at a time.
Voluntary mapped devices permit to map, configure and unmap in a task more
than the maximum number of concurrently mapped devices. It also allows us to avoid
mapping devices whose concurrent mapping is dangerous (e.g. concatenated
mappings).

It is possible to declare a device as voluntary mapped (field ``map_mode`` of
the *device_t* structure.  This field can be set to the following values:

   * DEV_MAP_AUTO
   * DEV_MAP_VOLUNTARY

When using DEV_MAP_AUTO, the device is automatically mapped in the task address
space when finishing the initialization phase, and is kept mapped until the
end of the task life-cycle.

When using DEV_MAP_VOLUNTARY, the device is not mapped by the kernel and the
task has to map the device itself (later in the life-cycle). In that case,
the device is mapped using this very syscall.


Mapping a device is done using the device id, hosted in the ``id`` field of the
*device_t* structure, which is set by the kernel at registration time.

Mapping a device is done with the following API::

   e_syscall_ret sys_cfg(CFG_DEV_MAP, uint8_t dev_id);

.. important::
   Declaring a voluntary mapped device requires a specific permission:
   PERM_RES_MEM_DMAP

.. note::
   Mapping a device requires a call to the scheduler, in order to reconfigure
   the MPU, this action is costly

sys_cfg(CFG_DEV_UNMAP)
^^^^^^^^^^^^^^^^^^^^^^

.. note::
   Synchronous syscall, executable only in main thread mode

When using DEV_MAP_VOLUNTARY, a previously voluntary mapped device can be unmapped
by the task.  Unmapping a device frees the corresponding MPU slot, this is useful e.g. when the task requires more
than the maximum number of concurrently devices.

.. important::
   While the device is configured, device's ISR still maps the device, even if
   it is unmapped from the main thread

.. important::
   Unmapping a device does not mean disabling it, the hardware device still works
   and emits IRQs that are handled by the task's registered ISR. It is the task's
   responsibility to properly disable the device before unammping it if necessary

.. note::
   Unmapping a device requires a call to the scheduler, in order to reconfigure
   the MPU, this action is costly

Unmapping a device is done using the device id, stored in the ``id`` field of
the *device_t* structure, which is set by the kernel at registration time.

Unmapping a device is done with the following API::

   e_syscall_ret sys_cfg(CFG_DEV_UNMAP, uint8_t dev_id);


sys_cfg(CFG_DEV_RELEASE)
^^^^^^^^^^^^^^^^^^^^^^^^

.. note::
   Synchronous syscall, executable only in main thread mode

A task may want to revoke its accesses to a given
device. This can be done by requesting the kernel to release the device using
its device descriptor.  The device is then fully deactivated (including
associated RCC clock and interrupts) and fully removed from the task's context.

.. warning::
   **This action cannot be undone**. The device is released until reboot

A released device shall never be
allocated by another task. This can only happen if the device is released by a
given task before another task has finished its initialization phase.

.. danger::
   You should **not** interleave nominal and initializing phases between
   tasks to avoid potential unwanted device reallocation. 
   Take care to synchronize init sequences correctly.  The kernel
   **does not** clear the device registers at release time

Releasing a device is done with the following API::

   e_syscall_ret sys_cfg(CFG_DEV_RELEASE, uint8_t dev_id);
