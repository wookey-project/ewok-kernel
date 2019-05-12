.. _faq_syscalls:

Syscalls FAQ
============

.. contents::

What is the header to include to get the syscalls prototypes?
-------------------------------------------------------------

Syscalls are implemented as functions in userspace, in the libstd.
The header is ``syscalls.h``.

When I declare a device, I always get SYS_E_DENIED?
---------------------------------------------------

Denying may be the consequence of various causes:
   1. You are not in the initialization phase
   2. You don't have the permission to register this type of device (see
      :ref:`EwoK permissions <ewok-perm>`)
   3. If you use EXTI for one or more GPIO, you must have the corresponding
      permission
   4. If you require a forced execution of the main thread for one more more
      ISR, you must have the corresponding permission
   5. You have left a field non-configured with a value that means something not
      permitted in your case (for example EXTI access request for GPIO)

.. hint::
   It is a good idea to memset to 0 a device_t structure before configuring it
   and requesting a device to the kernel.


When I configure a device, I always get SYS_E_INVAL?
----------------------------------------------------

Returning invalid may be the consequence of various causes:
   1. Your ``device_t`` structure contains some invalid (unset) field(s). When
      using the Ada kernel, be sure to memset to 0 the structure before using
      it, the kernel is very strict with the user entries (for obvious security
      reasons)
   2. You try to map a device that is not in the supported device map
   3. You try to map a device with an invalid size
   4. You have set more IRQ or more GPIOs than the maximum supported in the
      ``device_t`` structure

.. hint::
   It is a good idea to memset to 0 a device_t structure before configuring it
   and requesting a device to the kernel, and highly recommended when using the
   Ada kernel


