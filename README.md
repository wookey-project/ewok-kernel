# About EwoK microkernel


[![Release](https://img.shields.io/github/release/wookey-project/ewok-kernel.svg)](https://github.com/wookey-project/ewok-kernel/releases/latest)
[![Travis CI Build Status](https://api.travis-ci.com/wookey-project/ewok-kernel.svg?branch=master)](https://travis-ci.com/wookey-project/ewok-kernel)


## What is EwoK ?

EwoK is a microkernel targeting micro-controllers and embedded systems. It aims to bring an efficient hardening of embedded devices with a reduced impact on the device performances.

EwoK has been designed to host complex drivers in userspace. Unlike most of other microkernels, the goal is to support complex software stacks (ISO7816, …) as well as high performance (USB, SDIO, CRYP) drivers. This makes EwoK valuable for multiple use cases, including high speed and security targeted devices.
Security properties

EwoK supports the following properties:

   * Strict memory partitioning
   * Strict partitioning of physical resources (devices, etc.)
   * Fixed permissions management, set at compile time and easily verifiable
   * Stack smashing protection
   * Heap/Stack smashing protection
   * Proved W⊕X memory mappings
   * Strict temporal separation between declarative phase and execution phase

Ewok provides to the userspace drivers a specific interface to allow them to use the DMA engines. It permits to achieve high performance, specifically with high speed buses.

Nevertheless, DMA registers are never directly accessible to user tasks and any DMA configuration implies a validation of all the inputs by the kernel before any modification of the controller is pushed at the hardware level.

## EwoK microkernel architecture

The Ewok kernel is divided into two main components: the libbsp and the kernel part.
Ework kernel architecture

The libbsp is the architecture-specific part of the kernel, hosting all the low level and arch-specific drivers (MPU, GPIOs, timers, DMAs, etc.). The libbsp is itself separated in two blocks:

        SoC-specific drivers, such as DMA or GPIO support for the STM32F407, STM32F429 and STM32F439 SoCs
        Core-specific drivers, such as MPU support for the Cortex-M4 ARMv7-m micro-architecture

The kernel part contains all specific high level content (scheduling, task management, syscalls, etc.) and uses the libbsp as a hardware abstraction for any low-level interaction.

## About the chosen programming languages

Most of microkernels have been written in C and assembly. Some use less error-prone languages such as Rust, and only a very few have been formally validated (SeL4, written in C and formally validated using Isabelle) or ProvenCore (using its own formal language). Another example is Muen, written in SPARK but which is a Separation Kernel (based on the hardware specific virtualization mechanisms) for x86/64.

Ewok is based on the following considerations:

   * A fully formalized microkernel is too costly for an Open-Source project
   * A C-based microkernel is clearly too error-prone and even with high level of compilation hardening and tests, C language is not that adapted to very low level safe development (no strict typing, unsafe bitfields management, too many compiler dependent behavior, etc.). Nevertheless, C is still a language highly understood by most of the developers community.

We first have implemented an EwoK prototype in full C with few Assembly. Then, to limit the risk associated with the C language, we have decided to replace all the safety critical or security critical part of the kernel by Ada and SPARK. Nevertheless, we have not deleted the corresponding C part but modified the compilation system to support file by file substitution between C and Ada reference implementations.

EwoK can then be compiled as a full C/ASM kernel or an hybrid Ada/SPARK - C/ASM kernel, reducing the C and ASM part to the most basic and easy part of the kernel. Any component requiring external inputs (like syscalls) or critical for the security (like memory management) is written in Ada or SPARK, depending on the level of formalism required.

## EwoK API

The EwoK API is tuned for embedded systems, targeting userspace drivers implementation with performance and security constraints in mind. The whole microkernel architecture and the API provided to the user tasks are specifically designed for such a purpose.

Note that despite being a microkernel, Ewok is not full-IPC driven like L4 family microkernels. Beyond this, and similarly to other kernels, EwoK interactions with the userspace are based on syscalls. In the particular case of EwoK, a main application has two execution contexts: standard thread mode and ISR thread mode. Some syscalls can be executed from any context while others cannot. This property is described in each syscall documentation, and the developer will have to refer to it and understand in which context a piece of code is executed before calling such a syscall.

## EwoK permission model

EwoK permission model is static. Permissions are set at configuration time, before building the firmware, and can’t be updated during the device life cycle. Each application permissions are stored in a .rodata part of the kernel, reducing the risk of any invalid modification.

As EwoK is a driver-oriented microkernel, permissions are also driver oriented.

For more information about the EwoK microkernel, the complete documentation is published [here](https://wookey-project.github.io/ewok.html)
