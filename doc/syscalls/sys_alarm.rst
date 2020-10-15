.. _sys_alarm:

sys_alarm
---------

.. contents::

It is possible to request the kernel to trigger an alarm that will execute 
a specific "alarm_handler". It's mainly used for implementing some timeout.

sys_alarm()
^^^^^^^^^^^

.. note::
   **Not** executable in ISR mode

The alarm syscall has the following API::

   e_syscall_ret sys_alarm(uint32_t duration_in_ms, alarm_handler);

The alarm duration is specified in milliseconds. There is no specific permission
required to alarm.

If the duration is set with 0 of if the alarm_handler address is null, the
alarm is removed.

