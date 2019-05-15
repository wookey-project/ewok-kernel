.. _sys_get_systick:

sys_get_systick
---------------

Return elapsed time since the boot.

.. contents::

sys_get_systick()
^^^^^^^^^^^^^^^^^

Returns the current timestamp in a ``uint64_t`` value. The precision
might be: ::

   typedef enum {
      PREC_MILLI, /* milliseconds */
      PREC_MICRO, /* microseconds */
      PREC_CYCLE  /* CPU cycles */
   } e_tick_type;

Example: ::

    uint64_t dma_start_time;

    ret = sys_get_systick(&dma_start_time, PREC_MILLI);
    if (ret != SYS_E_DONE) {
        ...
    }

