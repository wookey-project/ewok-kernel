.. _sys_log:

sys_log
-------

.. contents::

EwoK provides a kernel-controlled logging facility with which any userspace task
can communicate. This kernel-controlled logging interface is used for debugging
and/or informational purpose and is accessible through the configured kernel
U(S)ART.

.. important::
  When the KERNEL_SERIAL option is not enabled, the kernel doesn't
  print out any log. The U(S)ART line isn't even activated. Although, the
  sys_log() behavior stays unchanged. This is particularly useful in a paranoid
  mode when generating 'production' firmwares: we are ensured that no information
  leak through serial debug can be exploited by an attacker.

sys_log()
^^^^^^^^^

.. note::
   Asynchronous syscall, not executable in ISR mode

This syscall permits to transmit a logging message on the kernel-handled serial
interface. The message must be short enough (less than 128 bytes). Any longer
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
