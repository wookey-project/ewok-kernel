The EwoK microkernel
=====================

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

EwoK has been designed to host complex drivers in userspace. Unlike most of other
microkernels, the goal is to support complex software stacks (ISO7816, ...)
as well as high performance (USB, SDIO, CRYP) drivers. This makes EwoK valuable for multiple
use cases, including high speed and security targeted devices.

Security properties
^^^^^^^^^^^^^^^^^^^

EwoK supports the following properties:
   * Strict memory partitioning
   * Strict partitioning of physical resources (devices, etc.)
   * Fixed permissions management, set at compile time and easily verifiable
   * Kernel Random Number Generation support (based on True RNG HW on STM32)
   * Stack smashing protection in both kernel and userspace tasks
   * Userspace Heap/Stack smashing protection
   * Proved W⊕X memory mappings
   * Strict temporal separation between declarative phase and execution phase

Ewok provides to the userspace drivers a specific interface to allow them to use the DMA engines.
It permits to achieve high performance, specifically with high speed buses.

Nevertheless, DMA registers are never directly accessible to user tasks and any DMA configuration implies a
validation of all the inputs by the kernel before any modification of the controller is
pushed at the hardware level.

Performances
^^^^^^^^^^^^

EwoK architecture
-----------------

Kernel architecture
^^^^^^^^^^^^^^^^^^^

The Ewok kernel is divided into two main components: the **libbsp** and the **kernel** part.

.. image:: img/ewok_precise_arch.png
   :alt: Ework kernel architecture
   :align: center

The **libbsp** is the hardware abstraction layer, hosting all the low level and
arch-specific drivers (MPU, GPIOs, timers, DMAs, etc.).
The **libbsp** is itself separated in two blocks:

   1. *SoC-specific drivers*, such as DMA or GPIO support for the STM32F407 board
   2. *Core-specific drivers*, such as MPU support for the Cortex-M4 ARMv7m micro-architecture

The **kernel** part contains all specific high level content (scheduling, task management,
syscalls, etc.) and uses the libbsp as a hardware abstraction for any low-level
interaction.

Drivers architecture
^^^^^^^^^^^^^^^^^^^^

.. image:: img/ewok_stack.png
   :alt: Ework generic software architecture
   :align: center

The **libstd** is the only requested userspace library. libstd hosts the syscall
user part (i.e. abstraction of the *svc*, aka *supervisor call*, assembly instruction) and some
general purpose utility functions such as libstring and logging utility
functions such as printf.

The **drivers** are written as userspace libraries. They depend on the libstd,
and may sometimes depend on each others. Here is the list of the existing drivers.

**Libraries** are various userspace features, arch-independent
implementations.

.. note::
   Other drivers and libraries will be published regulary

About the chosen programming languages
--------------------------------------

Most of microkernels have been written in C and assembly. Some use
less error-prone languages such as Rust, and only a very few have been
formally validated (SeL4, written in C and formally validated using Isabelle) or
ProvenCore (using its own formal language).

Ewok is based on the following considerations:

   * A fully formalized microkernel is too costly for an Open-Source project
   * A C-based microkernel is clearly too error-prone and even with high level
     of compilation hardening and tests, C language is not that adapted to
     very low level safe development (no strict typing, unsafe bitfields management,
     too many compiler dependent behavior, etc.). Nevertheless, C is still a language
     highly understood by most of the developers community.

We first have implemented an EwoK prototype in full C with few Assembly. Then, to
limit the risk associated with the C language, we have decided to replace all
the safety critical or security critical part of the kernel by Ada and SPARK.
Nevertheless, we have not deleted the corresponding C part but modified the
compilation system to support file by file substitution between C and Ada
reference implementations.

EwoK can then be compiled as a full C/ASM kernel or an hybrid Ada/SPARK - C/ASM kernel,
reducing the C and ASM part to the most basic and easy part of the kernel. Any
component requiring external inputs (like syscalls) or critical for the security
(like memory management) is written in Ada or SPARK, depending on the level of
formalism required.

.. note::
   The Ada/SPARK kernel is based on about 10 Klines of Ada and
   about 500 lines of C and assembly.

The methodology we used to create an hybrid kernel is described in the
following sections:

.. toctree::
   :maxdepth: 1

   Ada/C integration <ada_c>
   Ada code architecture <ada_arch>
   About SPARK <ada_spark>

EwoK API
--------

The EwoK API is tuned for embedded systems, targeting userspace drivers implementation
with performance and security constraints in mind. The whole microkernel architecture and
the API provided to the user tasks are specifically designed for such a purpose.

Note that despite being a microkernel, Ewok is not full-IPC driven like L4 family microkernels.
Beyond this, and similarly to other kernels, EwoK interactions with the userspace are based on syscalls.
In the particular case of EwoK, a main application has two execution contexts: standard thread mode and ISR thread mode.
Some syscalls can be executed from any context while others cannot. This property is described in each syscall
documentation, and the developer will have to refer to it and understand in which context a piece of code
is executed before calling such a syscall.

Some syscalls require some specific permissions. Those permissions are statically defined (set at build time).

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

   EwoK permissions internals <perms_internals>
   EwoK syscalls internals <syscalls_internals>
   EwoK IRQ & ISR internals <isr_internals>


EwoK API FAQ
------------

Here are the answers to (we hope) the most common questions you may have when using EwoK kernel. The EwoK FAQ will be regulary updated when new questions arrises from the community.

.. toctree::
   :maxdepth: 1

    General FAQ <faq_general>
    Syscalls FAQ <faq_syscalls>
    Permissions FAQ <faq_perms>
    Security FAQ <faq_security>
    Build process FAQ <faq_build>

