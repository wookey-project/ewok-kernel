.. _sys_exit:

sys_exit
--------

.. contents::

The sys_exit() syscall is used to handle thread termination.
Natural thread termination (userspace main thread and ISR thread termination) is handled
by the libstd using this syscall.
Although, a task can voluntary exit a given thread, by explicitely call this
syscall.

sys_exit()
^^^^^^^^^^

In EwoK, exiting the main thread and the ISR thread differs:
   * if the ISR thread voluntary exit, this will terminate the current ISR context
   * if the main thread exit, it is considered that the task terminates. The overall
     task threads and ressources are released and the task is no more runnable.

.. note::
   releasing a task does not allow to get back its memory slot for another use by now

The exit syscall has the following API::

   e_syscall_ret sys_exit()

