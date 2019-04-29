.. _ewok_kernel:

EwoK microkernel
================

.. image:: img/ewok.png
   :height: 250px
   :width: 250 px
   :scale: 100 %
   :alt: ewok icon
   :align: center


.. contents::
   :depth: 2

What is Ewok ?
--------------

EwoK is a microkernel targeting micro-controllers and embedded systems.
It aims to bring an efficient hardening of embedded
devices with a reduced impact on the device performances.

EwoK has been designed to host complex drivers in userspace. Unlike most of
other microkernels, the goal is to support complex software stacks (ISO7816,
...) as well as high performance (USB, SDIO, CRYP) drivers. This makes EwoK
valuable for multiple use cases, including high speed and security targeted
devices.

Security properties
^^^^^^^^^^^^^^^^^^^

EwoK supports the following properties:

   * Strict memory partitioning
   * Strict partitioning of physical resources (devices, etc.)
   * Fixed permissions management, set at compile time and easily verifiable
   * Kernel Random Number Generation support (based on True RNG HW on STM32)
   * Stack smashing protection in both kernel and userspace tasks
   * Userspace Heap/Stack smashing protection
   * Proved W^X memory mappings
   * Strict temporal separation between declarative phase and execution phase

Ewok provides to the userspace drivers a specific interface to allow them to
use the DMA engines. It permits to achieve high performance, specifically with
high speed buses.

Nevertheless, DMA registers are never directly accessible to user tasks and any
DMA configuration implies a validation of all the inputs by the kernel before
any modification of the controller is pushed at the hardware level.

Performances
^^^^^^^^^^^^

TODO

EwoK architecture
-----------------

Kernel architecture
^^^^^^^^^^^^^^^^^^^

Ewok architecture is divided into two main components: the **libbsp** and the
**kernel** part.

.. image:: img/ewok_precise_arch.png
   :alt: Ework kernel architecture
   :align: center

The *libbsp* is the hardware abstraction layer, hosting all the low level and
arch-specific drivers (MPU, GPIOs, timers, DMAs, etc.).
The *libbsp* is itself separated in two blocks:

   1. *SoC-specific drivers*, such as DMA or GPIO support for the STM32F407 board
   2. *Core-specific drivers*, such as MPU support for the Cortex-M4 ARMv7m
      micro-architecture

The *kernel* part contains all specific high level content (scheduling, task
management, syscalls, etc.) and uses the libbsp as a hardware abstraction for
any low-level interaction.

Drivers architecture
^^^^^^^^^^^^^^^^^^^^

.. image:: img/ewok_stack.png
   :alt: Ework generic software architecture
   :align: center

The :ref:`lib_std` (*libstd*) is a C standard library that can be used
by the user tasks (and hence the userspace drivers).
Like the *libc* for *UNIX*-like systems, it implements some useful functions.

The **drivers** are written as userspace libraries. They depend on the *libstd*,
and may sometimes depend on each others. Here is the list of the existing
drivers.

**Libraries** are various userspace features, arch-independent
implementations.


EwoK API
--------

The EwoK API is tuned for embedded systems, targeting userspace drivers
implementation with performance and security constraints in mind. The whole
microkernel architecture and the API provided to the user tasks are
specifically designed for such a purpose.

Note that despite being a microkernel, Ewok is not full-IPC driven like L4
family microkernels.  Beyond this, and similarly to other kernels, EwoK
interactions with the userspace are based on syscalls.  In the particular case
of EwoK, a main application has two execution contexts: standard thread mode
and ISR thread mode.  Some syscalls can be executed from any context while
others cannot. This property is described in each syscall documentation, and
the developer will have to refer to it and understand in which context a piece
of code is executed before calling such a syscall.

Some syscalls require some specific permissions. Those permissions are
statically defined (set at build time).

The EwoK API is fully described in the following:

.. toctree::
   :maxdepth: 1

   EwoK syscalls in large <syscalls>
   EwoK syscalls complete guide <syscalls_complete>
   EwoK permissions model <perms>

EwoK internals
--------------

If you want to hack into the kernel, EwoK internals are described here:

.. toctree::
   :maxdepth: 1

   Ada/SPARK implementation <ada_spark>
   EwoK permissions <perms_internals>
   EwoK syscalls <syscalls_internals>
   EwoK IRQ & ISR <isr_internals>
   Ewok scheduler <debug_sched>


EwoK API FAQ
------------

Here are the answers to (we hope) the most common questions you may have when
using EwoK kernel. The EwoK FAQ will be regulary updated when new questions
arrises from the community.

.. toctree::
   :maxdepth: 1

    General FAQ <faq_general>
    Syscalls FAQ <faq_syscalls>
    Permissions FAQ <faq_perms>
    Security FAQ <faq_security>
    Build process FAQ <faq_build>

