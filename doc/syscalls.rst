.. _syscalls:

EwoK syscalls
=============

Syscalls API is fully described, with all associated structures and enumerates,
in the :ref:`syscalls_internals`. This page is an introduction to
EwoK syscall usage and principles.

Some syscalls are executed synchronously, others asynchronously,
all synchronous syscalls can be executed in ISRs, other are restricted
to main thread only.

See each syscall property for more information.

.. sidebar:: About EwoK Syscalls phylosophy

   EwoK is designed to host userspace drivers and protocol stacks. Syscalls
   are driver-oriented and mostly propose device management. To these syscalls
   more *usual* syscalls are also proposed, for IPC and time measurement.


.. contents::


.. highlight:: c

General principles
------------------

Syscalls return values
^^^^^^^^^^^^^^^^^^^^^^

EwoK syscalls have all the same return values::

   typedef enum {
     /** Syscall has succesfully being executed */
      SYS_E_DONE = 0,
     /** Invalid input data */
      SYS_E_INVAL,
     /** Permission is denied */
      SYS_E_DENIED,
     /** Target is busy, not enough resources, resource is already used */
      SYS_E_BUSY,
   } e_syscall_ret;

.. danger::
   Never use a syscall without checking its return value, this may lead to
   invalid behavior


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

