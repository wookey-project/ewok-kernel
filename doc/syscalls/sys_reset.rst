sys_reset
---------
EwoK SoC software reset API
^^^^^^^^^^^^^^^^^^^^^^^^^^^

Synopsis
""""""""

There is some time where an event may require a board reset. This event may be

   * external: receiving an IRQ or an EXTI at a certain time of the execution phase
   * internal: reading a strange value or receiving an IPC/hang request for another
     task (case of a security monitor for e.g.)

In that case, the application may require the board to reboot. This reboot implies
a full memory RAM reset of various application RAM slot and a complete cleaning of
the ephemeral values (e.g. locally duplicated cryptographic informations in SoC
HW IP).

Doing such request is done by calling sys_reset() syscall.

sys_reset()
"""""""""""

.. note::
   Synchronous syscall, executable in ISR mode

In EwoK, only task with TSK_RST permission can ask kernel for board reset. Reset
is synchronous. Any current DMA transfer may be incomplete and generate mass-storage
consistency errors.

The reset syscall has the following API::

   e_syscall_ret sys_reset()

.. warning::
   sys_reset() is highly impacting the system behavior and should be used only by
   specific (at most one in a secure system) task(s). This permission should not
   be given to a task with a big attack surface.
