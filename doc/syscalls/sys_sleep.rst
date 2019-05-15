.. _sys_sleep:

sys_sleep
---------

.. contents::

It is possible to request a temporary period during which the task is not
schedulable anymore. This period is fixed and the task is awoken at the end of
it. This is a typical sleep behavior.

sys_sleep()
^^^^^^^^^^^

.. note::
   Synchronous syscall, but **not** executable in ISR mode, as there is no
   reason for an ISR to sleep

EwoK supports too sleep modes:

   * deep, non-preemptive sleep: the task is requesting a sleep period during
     which its main thread is not awoken, even by its ISR or external IPC
   * preemptive sleep: the task is requesting a sleep period that can be
     shortened if an external event (ISR, IPC) arises

The sleep syscall has the following API::

   typedef enum {
       SLEEP_MODE_INTERRUPTIBLE,
       SLEEP_MODE_DEEP
   } sleep_mode_t;

   e_syscall_ret sys_sleep(uint32_t duration, sleep_mode);

The sleep duration is specified in milliseconds. There is no specific permission
required to sleep.

.. warning::
   The sleep time is always a scheduler period multiple and is rounded to the
   next scheduler execution
