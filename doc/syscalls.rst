.. _syscalls:

EwoK syscalls
=============

.. sidebar:: Syscalls for managing devices

   EwoK is designed to host userspace drivers and protocol stacks. Syscalls
   are driver-oriented and mostly propose device management. To these syscalls
   more *usual* syscalls are also proposed, for IPC and time measurement.

.. contents::

Overview
--------

In Ewok, syscall parameters are passed by a structure that resides on the
stack. The use task updates ``r0`` register with the address of that structure,
and executes the ``svc`` opcode, which trigger the *SVC* interrupt ::

   e_syscall_ret sys_cfg_CFG_GPIO_GET(uint32_t cfgtype, uint8_t gpioref,
                                      uint8_t * value)
   {
       struct gen_syscall_args args =
           { SYS_CFG, cfgtype, gpioref, (uint32_t) value, 0 };
       return do_syscall(&args);
   }

   e_syscall_ret do_syscall(__attribute__((unused)) struct gen_syscall_args *args)
   {
     e_syscall_ret ret;
     asm volatile (
           "svc #0\n"
           "str  r0, %[ret]\n"
           : [ret] "=m"(ret) :: "r0");
     return ret;
   }

SVC interrupt automatically saves some registers onto the stack,
before switching to the MSP stack.
The ``r0`` register has a double function here. It's used to transmit the
address of the structure containing the syscalls parameters, but it also stores
the value returned by the syscall.

Syscalls return values
^^^^^^^^^^^^^^^^^^^^^^

Syscalls return values may be the following:

.. list-table::
   :widths: 20 80

   * - ``SYS_E_DONE``
     - Syscall has succesfully being executed
   * - ``SYS_E_INVAL``
     - Invalid input data
   * - ``SYS_E_DENIED``
     - Permission is denied
   * - ``SYS_E_BUSY``
     - Target is busy, not enough resources, resource is already used

.. danger::
   Never use a syscall without checking its return value, this may lead to
   invalid behavior




Synchronous and asynchronous syscalls
-------------------------------------

EwoK supports a **wise syscall repartition** in its configuration. This
repartition allows to execute only some specific syscalls in handler mode, as
others are postponed in thread mode and executed by a kernel thread: softirq.

The goal is to reduce as much as possible the duration of handler mode
execution. When the core is being executed in handler mode, there are some
restrictions:

   * If the kernel does not support nested interrupts (this is the case of
     EwoK), the execution can't be preempted by any event (including hardware
     interrupts)
   * If the kernel supports nested interrupts, only IRQ of higher priority can
     preempt the current interrupt execution

When the handler mode duration is too long, this may lead to IRQ shadowing
(multiple interrupts of the same IRQ number, but not detected as the interrupt
controller is temporary freezed) and may generate latency problems (reactivity
impacts for devices without flow control like smartcard on IS7816-3 USART based
buses for example).

In the same time, postponing all syscalls may lead to performance problems when
the syscall itself requires high reactivity. A typical example is
``sys_get_systick()``, which requires a high level of precision.

As a consequence, the EwoK kernel has separated its various syscalls depending
on:

   * their execution cost
   * their reactivity constraints


All synchronous syscalls are explicitly declared as synchronous in this documentation.


Almost all syscalls can be executed in main tread and in ISR context.
The exception concerns asynchronously executed syscalls which can't be
used in ISR context (and thus can only be executed in main thread). 
The developer must understand in which context a piece
of code is executed before using a syscall.

Some syscalls require also specific permissions, which are statically defined,
set at build time.

See each syscall property for more information.


General principles
------------------


Syscalls and the task lifecycle
-------------------------------

Ewok follows a specific life cycle for userspace tasks, based on two sequential
states:

   * an initialization state
   * a nominal state

About the initialization state
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

All resources declaration is performed during the initialization state. During
this state, the task is able to:

   * declare devices
   * declare DMA channels
   * ask for other task's identifier
   * requesting a DMA shared memory with another task
   * log messages into the kernel log console

All these actions are conditioned on EwoK permissions as defined in :ref:`Ewok
pemission model <ewok-perm>`.

During the initialization phase, no physical resource (devices, DMA) is
enabled.  The link between the task and the resource is stored in the kernel
task context and the resource is reserved, but the task is not able to use the
resource yet. Any memory-mapped resource (like memory mapped devices) are **not
yet** mapped in the task memory space.

.. danger::
   Don't try to access any registered device memory during the initialization
   phase, this will result into a memory fault

All the declarations of the initialization phase are done using the sys_init()
syscall family.

.. danger::
   No other syscall (IPCs, configuration, etc.) is allowed during this state,
   they will return SYS_E_DENIED.

The end of the initialization phase is asked by a specific syscall of the
sys_init() family::

   sys_init(INIT_DONE);

.. note::
   Keeping a strict separation between an initialization and a nominal state is
   an efficient way of avoiding any invalid resource request until the task is
   connected to potentially unsafe external elements (e.g. through an USB
   channel, etc.)

.. note::
   When the task has started its nominal phase, it has no way to modify its
   profile (list of devices, informations about other tasks, etc.)


About the nominal state
^^^^^^^^^^^^^^^^^^^^^^^

When the task executes the ``sys_init(INIT_DONE)`` syscall, the task is
rescheduled and all declared resources are configured and enabled. From now
one, all memory mapped devices are mapped with the correct MPU permissions in
order to allow direct memory access.

.. warning::
   If the task has declared devices as voluntary mapped
   the device is not mapped. The task needs to
   voluntary map it before using it.  This is a way of limiting the usage of some
   devices to the strict minimum.

From now on, the task is no more authorized to execute any of the
``sys_init()`` syscalls family. Other syscalls can be used:

   * ``sys_log()`` to transmit a message on the kernel logging facility
   * ``sys_ipc()`` syscalls family, to communicate through kernel IPC with
     other tasks
   * ``sys_cfg()`` syscalls family, to (re)configure previously declared
     devices and DMA
   * ``sys_get_systick()`` to get time stamping information
   * ``sys_yield()`` to voluntary release the CPU core and sleep until an
     external event arises (IRQ or IPC targeting the task)
   * ``sys_sleep()`` to voluntary release the CPU core and sleep for a given
     number of milliseconds
   * ``sys_reset()`` to voluntary reset the SoC
   * ``sys_lock()`` to voluntary lock a critical section and postpone the
     task's ISR for some time

.. warning::
   Most of these syscalls are associated to permissions. See below for more
   information.

Overview of the syscalls
---------------------------

Initializing and declaring content
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. include:: syscalls/sys_init.rst
   :start-line: 4

Logging information on kernel console
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. include:: syscalls/sys_log.rst
   :start-line: 4

(Re)configuration requests
^^^^^^^^^^^^^^^^^^^^^^^^^^

.. include:: syscalls/sys_cfg.rst
   :start-line: 4

Inter-Process Communication (IPC)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. include:: syscalls/sys_ipc.rst
   :start-line: 4


Time measurement
^^^^^^^^^^^^^^^^

.. include:: syscalls/sys_get_systick.rst
   :start-line: 4

Collaborative scheduling
^^^^^^^^^^^^^^^^^^^^^^^^

.. include:: syscalls/sys_yield.rst
   :start-line: 4


.. include:: syscalls/sys_sleep.rst
   :start-line: 4

Reactive actions
^^^^^^^^^^^^^^^^

.. include:: syscalls/sys_reset.rst
   :start-line: 4

Lock actions
^^^^^^^^^^^^

.. include:: syscalls/sys_lock.rst
   :start-line: 4

RNG access
^^^^^^^^^^

.. include:: syscalls/sys_get_random.rst
   :start-line: 4

