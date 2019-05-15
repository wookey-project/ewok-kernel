.. _sys_yield:

sys_yield
---------

.. contents::

In some situations, yielding is an efficient way to optimize the
scheduling. Historically, yield() is a collaborative syscall requesting the end
of the current slot, asking for the scheduling of a new task. In embedded
systems, such a call may help the scheduler in optimizing the tasks execution by
voluntarily reducing a task's slot when no more execution is required.

sys_yield()
^^^^^^^^^^^

.. note::
   Synchronous syscall, **not** executable in ISR mode as an ISR as no reason
   to yield

In EwoK, all tasks main threads can yield. When this happens, the task's thread
will not be scheduled again until an external event requires its execution.
Such external events can be:

   * An IRQ registered by the task. When the ISR is executed, the task's main
     thread becomes runnable again
   * An IPC targeting the task is sent by another task

The yield syscall has the following API::

   e_syscall_ret sys_yield()

.. warning::
   Using ``sys_yield()`` should be a requirement when using MLQ_RR scheduling scheme with asynchronous
   communication mechanisms, to avoid starvation
