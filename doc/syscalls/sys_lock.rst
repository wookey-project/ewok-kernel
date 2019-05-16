.. _sys_lock:

sys_lock
--------

Pure userspace semaphore, as proposed in ``libstd.h``, do not permit easy handling
of variable shared between ISR and main threads. ISR treatments do not allow to sleep
or wait for the main thread to release semaphores. The solution to this problem is to instruct Ewok
not to schedule the ISR routine while the shared variable is in use in the main thread.
Of course such a situation ought to be short.

.. contents::

sys_lock()
^^^^^^^^^^

``sys_lock``: postpone the ISR while a lock is set by the main thread.
This efficiently creates a critical section in the main thread with respect
to the ISR thread.

.. note::
   Synchronous syscall, executable in main thread mode only

In EwoK, all tasks main threads can lock one of their variables without
requesting any specific permission.

The lock syscall has the following API::

   e_syscall_ret sys_lock(LOCK_ENTER);
   e_syscall_ret sys_lock(LOCK_EXIT);

.. warning::
   Locking the task should be done for a very short amount of time, as associated ISR are
   postponed, which may generate big slowdown on the associated devices performance.

