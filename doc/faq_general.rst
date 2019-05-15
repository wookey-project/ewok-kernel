.. _faq_general:

General FAQ
===========

.. contents::

.. highlight:: c

Why applications main function is named _main?
-----------------------------------------------

EwoK applications entry points have the following prototype: ::

   int function(uint32_t task_id):

There is an unsigned int argument passed to the main function, giving it the
current task identifier.

When using the ``main`` symbol, the compiler requires one of the
following prototypes ::

  int main(void);
  int main(int argc, char **argv);

As EwoK doesn't generate such a prototype, the ``main`` symbol cannot be used,
explaining why ``_main`` is used instead. The generated ldscript automatically
uses it as the application entry point and the application developer has
nothing to do other than to name its main function properly.

What is a typical generic task's main() function?
-------------------------------------------------

A basic main function should have the following content:

   * An initialization phase
   * A call to sys_init(INIT_DONE) to finish the initialization phase
   * A nominal phase

A basic, generic main function looks like the following: ::

   int _main(uint32_t task_id)
   {
     /* Local variables declaration */
     uint8_t syscall_ret;

     /* Initialization phase */
     printf("starting initialization phase\n");

     /* any sys_init call is made here */

     /* End of initialization sequence */
     sys_init(INIT_DONE);

     /* Nominal sequence */
     printf("starting nominal phase\n");

     /*
      * If any post-init configuration is needed, do it here
      * This is the case if memory-mapped devices need to be configured
      */

     /*
      * Start the main loop or main automaton
      */
     do_main_loop();

     return 0;
   }

Syscall API is complex: why?
----------------------------

EwoK syscalls is a fully driver-oriented API. Efforts have been made in
providing various userspace abstractions to help application developers in
using generic devices through a higher level API.

These abstractions are separated in:

   * userspace drivers

       These drivers supply a higher level, easier API to applications
       and manage a given device by using the syscall API and configuring
       the corresponding registers for memory-mapped devices. Drivers API
       abstract most of the complexity of the hardware devices (such as USARTs,
       CRYP, USB, SDIO, etc.)

   * userspace libraries

       These libraries implement various hardware-independent features, but
       may depend on a given userspace driver. They supply a functional API
       for a given service (serial console, AES implementation, etc.), and
       in case of a dependency with a userspace driver, manage the driver
       initialization and configuration.


Why should I define a stack size?
---------------------------------

This is due to the way EwoK handles the userspace layout. In EwoK userspace
mapping, the userspace stack is on the bottom of the user memory map. If
the userspace task overflows its own stack, it immediately generates a memory
exception error.

This behavior is due to the fact that on MPU-based systems, the page-guard mechanism
cannot be used to detect heap/stack smashing, making it harder to detect stack overflow or
heap overflow events. Such a layout, pushing the heap on the top addresses
and the stack on the bottom helps in detecting such overflows (the heap grows
upwards and the stacks grows downwards).

.. hint::
   You can use your compiler to detect the amount of stack needed, as most
   compilers are able to calculate the effective used stack size based on the
   compiled code

.. danger::
   Do **not** use recursive code in userspace applications. Embedded systems
   are not friendly with recursion, as the amount of stack memory is highly reduced

What is NUMSLOTS and how to know the number of slots an application needs?
--------------------------------------------------------------------------

The NUMSLOTS option of an application specifies the number of memory slots of the
flash section dedicated to userspace applications that are required by the
application.

In both DFU and FW mode, there are 8 memory slots, as the MPU is able to handle
8 subregions for a given memory region.  As a consequence, the total number of
slots of the total number of applications of a given mode (DFU or FW) must not
exceed 8.

.. hint::
   This is specific to STM32 MPU and may vary on other SoCs MPU

The slot size depends on the selected SoC (as the amount of accessible flash
memory may vary) and the mode in which your application is executed (nominal
-aka FW- or DFU).

This information can be found in the following file:

kernel/src/arch/soc/<target_soc>/soc-layout.h

The slot size values are the following: ::

   #define  FW_MAX_USER_SIZE   64*KBYTE
   #define  DFU_MAX_USER_SIZE  32*KBYTE

FW_MAX_USER_SIZE defines the slot size for FW mode and DFU_MAX_USER_SIZE defines
the slot size for DFU mode.

Memory slots hold .text, .got, .rodata and .data content of the application.
.data section will be copied into RAM in the application memory layout later at
boot time.


As a consequence, depending on the size of these sections, the number of
required slots may vary. You can use objdump or readelf tools to get back the
effective size of your application and calculate the effective number of slots
needed: ::

   $ arm-none-eabi-objdump -h build/armv7-m/wookey/apps/myapp/myapp.elf
   build/armv7-m/wookey/apps/sdio/sdio.fw1.elf:     file format elf32-littlearm
   Sections:
   Idx Name          Size      VMA       LMA       File off  Algn
    0 .text         00002b68  080a0000  080a0000  00010000  2**2
                     CONTENTS, ALLOC, LOAD, READONLY, CODE
    1 .got          00000024  080a2b68  080a2b68  00012b68  2**2
                     CONTENTS, ALLOC, LOAD, DATA
    2 .stacking     00001a90  20008000  20008000  00028000  2**0
                     ALLOC
    3 .data         00000010  20009a90  080a2b8c  00019a90  2**2
                     CONTENTS, ALLOC, LOAD, DATA
    4 .bss          0000428c  20009aa0  00000000  00009aa0  2**2
                     ALLOC

Here, the application requires 0x2b68 + 0x24 + 0x10 = 0x2b9c, which means 11.164
bytes. For this task, one slot is enough in both modes.

.. hint::
   The Tataouine SDK helps when a task is too big for its configured number of
   slots, and specifies which section is problematic. You can let it detect slots
   overlap if needed

.. hint::
   The Tataouine SDK calculates both flash memory and RAM consumption of each
   task, which also allows to detect RAM overlap

