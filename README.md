# EwoK, a secure microkernel for building secure embedded systems


[![Release](https://img.shields.io/github/release/wookey-project/ewok-kernel.svg)](https://github.com/wookey-project/ewok-kernel/releases/latest)
[![Travis CI Build Status](https://api.travis-ci.com/wookey-project/ewok-kernel.svg?branch=master)](https://travis-ci.com/wookey-project/ewok-kernel)


## What is EwoK ?

EwoK is a highly secure microkernel targeting micro-controllers and embedded systems.
It aims to bring an efficient hardening of embedded devices with a reduced impact on
the device performances.

EwoK has been designed to host complex drivers in userspace. Unlike most of
other microkernels, the goal is to support complex software stacks (ISO7816, …)
as well as high performance (USB, SDIO, CRYP) drivers. This makes EwoK valuable
for multiple use cases, including high speed and security targeted devices.
Security properties

EwoK is a microkernel enforcing strict isolation between tasks and device
drivers and providing strict access control to physical resources (devices,
etc.) and strong enforcement of the least privilege principle.

EwoK is also implemented in Ada/SPARK, a strongly typed language often used
in highly critical domains (avionic, railway systems, space, etc.) to build
safe and secure software.

Some other security features provided by EwoK:

   * Strict memory partitioning
   * Strict partitioning of physical resources (devices, etc.)
   * Fixed permissions management, set at compile time and easily verifiable
   * Stack smashing protection
   * Heap/Stack smashing protection
   * Proved W⊕X memory mappings
   * Strict temporal separation between declarative phase and execution phase

Ewok provides to the userspace drivers a specific interface to allow them to
use the DMA engines. It permits to achieve high performance, specifically with
high speed buses.

Nevertheless, DMA registers are never directly accessible to user tasks and any
DMA configuration implies a validation of all the inputs by the kernel before
any modification of the controller is pushed at the hardware level.

## EwoK architecture

The Ewok kernel is divided into two main components: the *libbsp* and the *kernel*
part.

The libbsp is the architecture-specific part of the kernel, hosting all the low
level and arch-specific drivers (MPU, GPIOs, timers, DMAs, etc.). The libbsp is
itself separated in:

   * *SoC-specific drivers*, such as DMA or GPIO support for the STM32F407, STM32F429 and STM32F439 SoCs
   * *Core-specific drivers*, such as MPU support for the Cortex-M4 ARMv7-m micro-architecture

The kernel part contains all specific high level content (scheduling, task
management, syscalls, etc.) and uses the libbsp as a hardware abstraction for
any low-level interaction.

## About the chosen programming languages

C is a language highly understood by most of the developers community.
Therefore, most of microkernels have been written in C and assembly.
However, because of our experience in security, we are convinced that C is
too error-prone. Its loose typing, its unsafe bitfields management, too many
compiler dependent behaviors, etc. easily lead to vulnerabilities.

An easy alternative is to use a language that enforces strong typing
and that prevent "classical" vulnerabilities (buffer overflows, dangling
pointers, etc.). However, we found that very few languages enforce strong
typing while being suitable for bare metal programming. We choosed to gave a
try to Ada/SPARK. That language exceeded our expectations, by being simple
to use and by gaving us a tremendous help in the debugging process.

Therefore, EwoK is almost entirely implemented in Ada/SPARK (with a little bit
of assembly).

## EwoK API

The whole microkernel architecture and the API provided to the user tasks are
specifically designed for helping developpers to implement highly secure and
performant drivers.

Note that despite being a microkernel, Ewok is not full-IPC driven like L4
family microkernels. Beyond this, and similarly to other kernels, EwoK
interactions with the userspace are based on syscalls. In the particular case
of EwoK, a main application has two execution contexts: standard thread mode
and ISR thread mode. Some syscalls can be executed from any context while
others cannot. This property is described in each syscall documentation, and
the developer will have to refer to it and understand in which context a piece
of code is executed before calling such a syscall.

## EwoK permission model

EwoK permission model is static. Permissions are set at configuration time,
before building the firmware, and can’t be updated during the device life
cycle. Each application permissions are stored in a .rodata part of the kernel,
reducing the risk of any invalid modification.

As EwoK is a driver-oriented microkernel, permissions are also driver oriented.

For more information about the EwoK microkernel, the complete documentation is
published [here](https://wookey-project.github.io/ewok/index.html)
