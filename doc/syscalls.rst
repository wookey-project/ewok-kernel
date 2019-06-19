.. _syscalls:

EwoK syscalls
=============


.. contents::

General principles
------------------

EwoK is designed to host userspace drivers and protocol stacks. Syscalls
are driver-oriented and mostly expose device management primitives. Some
more *usual* syscalls, like IPC, are also proposed.

Triggering a syscall from userland
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

In EwoK, syscall parameters are passed by a structure that resides on the
stack. The task writes the address of this structure in the ``r0`` register
and executes the ``svc`` instruction, which triggers the *SVC interrupt*.
The *SVC interrupt* automatically saves registers on the stack,
before switching to the MSP stack.
The ``r0`` register has a double function here. It is used to transmit the
address of the structure containing the syscalls parameters, but it also stores
the value returned by the syscall.

An example of a syscall implementation: ::

   e_syscall_ret sys_cfg_CFG_GPIO_GET(uint32_t cfgtype,
                                      uint8_t gpioref, uint8_t * value)
   {
       struct gen_syscall_args args = { gpioref, (uint32_t) value, 0, 0 };
       return do_syscall(SVC_GPIO_GET, &args);
   }

   e_syscall_ret do_syscall(e_svc_type svc, __attribute__ ((unused))
                            struct gen_syscall_args *args)
   {
       e_syscall_ret ret;

       switch (svc) {
   ...
        case SVC_GPIO_GET:
            asm volatile ("mov r0, %[args]; svc %[svc]; str  r0, %[ret]\n"
                          :[ret] "=m"(ret)
                          :[svc] "i"(SVC_GPIO_GET),[args] "g"(args)
                          :"r0");
   ...

Returned values
^^^^^^^^^^^^^^^

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
   unchecked errors in your code

Synchronous and asynchronous syscalls
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

EwoK kernel is not reentrant. As a consequence, syscalls
can be synchronously or asynchronously executed depending
on their expected duration.

Most of syscalls are synchronously executed by the kernel.
To avoid hindering the whole system, slow syscalls are asynchronously executed:
their execution is postponed and is ought to be accomplished by the *softirq*
kernel thread.

.. note:: Actually, :ref:`sys_log` is the sole asynchronous syscall

It is worth mentioning that as *Interrupt Service Routines (ISR)*
should be quickly executed, EwoK forbids asynchronous syscalls while
in this context.

Note also that some syscalls should require some specific permissions, which
are set at build time.

Syscalls and permissions
^^^^^^^^^^^^^^^^^^^^^^^^

A part of the syscalls require dedicated permissions. See :ref:`perms` section
for more information about EwoK permissions and their impact on the syscall API.

Syscall overview
----------------

.. toctree::
   :maxdepth: 1

   Declaring and initializing devices <syscalls/sys_init>
   Configuring a device <syscalls/sys_cfg>
   Logging information on kernel console <syscalls/sys_log>
   Inter-Process Communication (IPC) <syscalls/sys_ipc>
   Measuring time <syscalls/sys_get_systick>
   Releasing the CPU <syscalls/sys_yield>
   Terminating a thread <syscalls/sys_exit>
   Sleeping <syscalls/sys_sleep>
   Reseting the board <syscalls/sys_reset>
   Main thread locking mechanism <syscalls/sys_lock>
   Accessing the RNG <syscalls/sys_get_random>

