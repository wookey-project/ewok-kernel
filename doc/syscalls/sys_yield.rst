.. _sys_yield:

sys_yield
---------
EwoK time slot releasing API
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Synopsis
""""""""

There is some time where yielding is an efficient way to optimize the
scheduling. Historically, yield() is a collaborative syscall requesting the end
of the current slot, asking for the scheduling of a new task. In embedded
system, such call may help the scheduler in optimize the task execution by
voluntary reduce a task's slot when no more execution is required.

sys_yield()
"""""""""""

.. note::
   Synchronous syscall, **not** executable in ISR mode as an ISR as no reason
   to yield

In EwoK, all tasks main thread can yield. When this happend, the task's thread
will not be scheduled again until an external event requires its execution.
Such external event can be:

   * An IRQ registered by the task. When the ISR is executed, the task main
     thread is runnable again
   * An IPC targeting the task is sent by another task

The yield syscall has the following API::

   e_syscall_ret sys_yield()

.. warning::
   Using sys_yield is a requirement when using RMA scheduling scheme, to avoid
   starvation.
