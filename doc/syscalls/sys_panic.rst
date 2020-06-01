.. _sys_panic:

sys_panic
---------

.. contents::

The sys_panic() syscall is used to handle vollunatry task termination on abnormal event.
This syscall has been made to permit self-protection mechanisms from userspace tasks
against fault-injection or various corruption attacks.

sys_panic()
^^^^^^^^^^^

If a task detect a corruption of its data (function pointers, stack, etc.) it can request
a "panic behavior" from the kernel, through which the task is stopped, all its devices
and interrupts deactivated.

Depending on the configuration, the kernel car reset the board or schedule another task.

.. note::
   if the device is not reset, the task keeps its memory locked, and none of its thread is
   ever rescheduled.

The panic syscall has the following API::

   e_syscall_ret sys_panic()

This syscall doesn't require any specific permissions.
