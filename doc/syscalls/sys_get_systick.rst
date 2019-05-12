.. _sys_get_systick:

sys_get_systick
---------------
EwoK time measurement API
^^^^^^^^^^^^^^^^^^^^^^^^^

Synopsis
""""""""

It is possible to get information on time in EwoK. Though, the time-measurement
precision depends on the task permissions using the sys_get_systick() syscall.
Limiting the time precision measurement with specific permissions allows to
limit side and covert channels of untrusted tasks, and more generally to
enforce least privilege level paradigm (if a task only needs a millisecond
precision for its drivers, no need to provide more).

sys_get_systick()
"""""""""""""""""

.. note::
   Synchronous syscall, executable in ISR mode

EwoK returns the current timestamp in a uint64_t value, with one of the
following units:

   * milliseconds
   * microseconds
   * cycles

The unit depends on the second argument, an enumerated type, specifying the precision
requested.

The time measurement syscall has the following API::

   typedef enum {
      PREC_MILLI,
      PREC_MICRO,
      PREC_CYCLE
   } e_tick_type;

   e_syscall_ret sys_get_systick(uint64_t *val, e_tick_type mode);

.. important::
  The time measurement access and permission are restricted to EwoK time
  permissions, as high precision time measurement is an efficient tool for side
  channel attacks and covert channels
