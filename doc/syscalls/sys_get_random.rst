.. _sys_get_random:

sys_get_random
--------------
EwoK RNG accessor
^^^^^^^^^^^^^^^^^

Synopsis
""""""""

The random number generator (RNG) of the board is hold by the EwoK kernel as it
is use to initialize the user and kernel tasks canary seed value.  This entropy
source may be implemented in the kernel as:

   * a true random number generator (TRNG) when the corresponding IP exists and
     its driver is implemented in EwoK. This is the case of the STM32F4 SoCs
     for which a TRNG IP exists and is supported
   * a pseudo-random number generator, implemented as a full software
     algorithm. This entropy source can't be considered with the same security
     properties as the TRNG one

As the RNG support is hosted in the EwoK kernel, a specific syscall exists to
get back a random content from the kernel. This content can be used as a
source of entropy for various algorithms.

sys_get_random()
""""""""""""""""

.. note::
   Syncrhonous syscall,  executable in ISR mode

Get back some random content from the kernel is easy with EwoK and can be done
using a single, synchronous, syscall.

If the random content is okay, the syscall returns SYS_E_DONE. If the random
number generator fails to generate a strong and clean random content, the
syscall returns SYS_E_BUSY. If the task doesn't have the RES_TSK_RNG
permission, the syscall returns SYS_E_DENIED and the buffer is not modified.

The sys_get_random() syscall has the following API::

   e_syscall_ret sys_get_random(char *buffer, uint16_t buflen)

.. warning::
   Using sys_get_random requires the RES_TSK_RNG permission, as requiring too
   much random from a pseudo-rng implementation may lead to predictable
   values. This permission is not needed for initializing the task's canaries.
