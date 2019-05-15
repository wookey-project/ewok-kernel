.. _sys_reset:

sys_reset
---------

.. contents::

There are some situations where an event may require a board reset. These events may be:

   * external: receiving an IRQ or an EXTI at a certain time of the execution
     phase
   * internal: reading a strange value or receiving an IPC/hang request from
     another task (case of a security monitor for e.g.)

In these cases, the application may require the board to reboot. This reboot
implies a full memory RAM reset of various application RAM slots and a complete
cleaning of the ephemeral values (e.g. locally duplicated cryptographic
information in SoC HW IP).

Doing such request is ensured by calling sys_reset() syscall.

sys_reset()
^^^^^^^^^^^

.. note::
   Synchronous syscall, executable in ISR mode

In EwoK, only tasks with TSK_RST permission can ask the kernel for board reset.
Reset is synchronous. Any current DMA transfer may be incomplete (and e.g. generate
mass-storage consistency errors when dealing with SCSI, and so on).

The reset syscall has the following API::

   e_syscall_ret sys_reset()

.. warning::
   sys_reset() is highly impacting the system behavior and should be used only
   by specific (at most one in a secure system) task(s). This permission should
   not be given to a task with a big attack surface. Ususally, only a trusted
   security monitor task is allowed to perform a board reset
