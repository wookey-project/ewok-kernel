.. _sys_log:

sys_log
-------
EwoK serial interface logging API
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Synopsis
""""""""

EwoK provide a kernel-controlled logging facility on which any userspace task
can communicate. This kernel-controlled logging interface is used for debugging
and/or informational purpose and is accessible through the configured kernel
U(S)ART.

.. important::
  When the kernel is configured in KERNEL_NOSERIAL mode, the kernel doesn't
  print out any log. The U(S)ART line isn't even activated. Although, the
  sys_log() behavior stays unchanged.

sys_log()
"""""""""

.. note::
   Asynchronous syscall, not executable in ISR mode

This syscall permits to transmit a logging message on the kernel-handled serial
interface. The message must be short enought (less than 128 bytes). Any longer
message is truncated.

Message printing is not synchronous and is handled by a kernel thread. As a
consequence, message printing is not a reactive syscall and may take some time
before being executed if multiple IRQ and/or ISR are to be executed before.

The sys_log syscall has the following API::

   e_syscall_ret sys_log(logsize_t size, const char *msg);

.. important::
   The kernel logging facility is a debugging helper feature. It should not be
   used as a trusted console. For this, please use a dedicated task holding a
   userspace USART support with specific security properties instead
