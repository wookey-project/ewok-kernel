.. _sys_lock:

sys_lock
--------
EwoK kernel-based locking mechanism
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Synopsis
""""""""

Most of the time, using pure userspace semaphores is enough to lock an access to
a given shared variable. Semaphores are implemented in the libstd. Nonetheless,
there might be some specific cases where pure userspace implementations are not enough.

sys_lock()
""""""""""

Imagine you manipulate a variable in both read and write in the main thread and
in an ISR. When accessing this variable in the ISR, you may detect a userspace
lock but you don't have any easy way to postpone the potential work required on
this variable in the ISR context, as ISR are executed on external events. In
that case, an easy way would be to slow down the ISR execution while the
userspace thread is keeping the lock.

This is what this syscall is doing: while a lock is set by the main thread, all
the ISR of the task are postponed in the ISR queue, waiting for the lock to be
release. This efficiently creates a critical section in the main thread with regard
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
