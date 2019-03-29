sys_get_systick
---------------
EwoK time measurement API
^^^^^^^^^^^^^^^^^^^^^^^^^

Synopsis
""""""""

It is possible to get information on time in EwoK. Though, the time-measurement
precision depends on the task permissions using the sys_get_systick() syscall.

sys_get_systick()
"""""""""""""""""

.. note::
   Synchronous syscall, executable in ISR mode

EwoK returns the current timestamp in a uint64_t value, with one of the following unit:

   * milliseconds
   * microseconds
   * cycles

The uint depend on the second argument, an enumerate, specifying the precision
requested.

The time measurement syscall has the following API::

   typedef enum {
      PREC_MILLI,
      PREC_MICRO,
      PREC_CYCLE
   } e_tick_type;

   e_syscall_ret sys_get_systick(uint64_t *val, e_tick_type mode);

.. important::
  The time measurement access and permission is restricted to EwoK time permissions, as high precision time measurement is an efficient tool for side channel attacks
