.. _syscalls_internals:

EwoK syscalls internals
=======================

About EwoK syscall gate
-----------------------

The EwoK syscall gate is based, for ARM cores, on the SVC (supervisor call)
interrupt.  Any EwoK kernel call is done using the special assembly instruction
``svc``. EwoK discriminates the kernel call request using the svc argument. In
the case of syscalls, the argument is 0. There are various other svc
identifiers used in EwoK:

   * end of task
   * end of interrupt service routine
   * etc.

The effective syscall gate is then performed in the SVC kernel IRQ handler, and
is executed when the svc identifier is identified as being a syscall.


Sycalls argument passing
------------------------

Nearly all sysalls require argument passing to the kernel. EwoK is using a
stack-based argument passing, like OpenBSD for example.  This means that the
user thread pushes all the argument on the stack, updates `r0`` with the
syscall svc number and executes the svc opcode to raise the SVC IRQ.


We have decided to use an easy stack-based argument passing using the standard
C convention for functions arguments. Here is a typical example::

   e_syscall_ret do_syscall(__attribute__((unused)) struct gen_syscall_args *args)
   {
       e_syscall_ret ret;

       asm volatile (
          "svc #0\n"
          "str  r0, %[ret]\n"
          : [ret] "=m"(ret));
       return ret;
   }


   e_syscall_ret my_syscall(uint32_t arg1, uint32_t arg2, void*arg3)
   {
       struct gen_syscall_args args = { arg1, arg2, (uint32_t)arg3, 0 };
       e_syscall_ret ret;

       ret = do_syscall(&args);

       return ret;
   }


In this typical example:

   * the syscall API shown to the user is ``my_syscall()``
   * my_syscall() generates a table of arguments which is passed to the
     ``do_syscall()`` function
   * The C convention saves the current frame state, sets r0, r1, r2, and r3
     with the values of the four cells and branches with link to do_syscall().
     The four registers are now correctly set
   * do_syscall() then executes the svc instruction

At that time, the SVC IRQ is triggered and the hardware automatically saves the
current context onto the stack before switching to the MSP stack (MSP stack is
the one used in IRQ mode, FIQ mode and various ARM Exception modes)

The kernel handler then gets back the address of the user thread saved frame
and is then able to get back all the previously saved registers (including r0,
r1, r2 and r3, containing all the syscall arguments).

At the end of the syscall execution, the kernel updates the r0 saved value on
the user stack with the syscall return value. When the user thread resumes its
execution, the r0 value is saved into the ret variable and returned by
``my_syscall()`` function.

.. note::
  This argument passing mechanism is very easy and does not use a complex
  argument structure with meta-information stored in the stack. By now, a basic
  argument list is still enough for EwoK usage.

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
