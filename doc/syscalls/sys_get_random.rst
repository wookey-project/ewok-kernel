.. _sys_get_random:

sys_get_random
--------------

.. contents::

The random number generator (RNG) is hold by the EwoK kernel as it
is used to initialize the user and kernel tasks canary seed values. This entropy
source may be implemented in the kernel as:

   * a true random number generator (TRNG) when the corresponding IP exists and
     its driver is implemented in EwoK. This is the case of the STM32F4 SoCs
     for which a TRNG IP exists and is supported
   * a pseudo-random number generator (PRNG), implemented as a full software
     algorithm. This entropy source can't be considered with the same security
     properties as the TRNG one
   * a mix of the two sources (i.e. a TRNG as one of the entropy sources of
     a PRNG)

As the RNG support is hosted in the EwoK kernel, a specific syscall exists to
get back a random content from the kernel. This content can be used as a
source of entropy for various algorithms, and the userland can also implement
its own PRNG processing based on this entropy.

sys_get_random()
^^^^^^^^^^^^^^^^

.. note::
   Synchronous syscall,  executable in ISR mode

Get back some random content from the kernel is easy with EwoK and can be done
using a single, synchronous, syscall.

If the random content is okay, the syscall returns SYS_E_DONE. If the random
number generator fails to generate the asked random content, the
syscall returns SYS_E_BUSY. If the task doesn't have the RES_TSK_RNG
permission, the syscall returns SYS_E_DENIED and the buffer is not modified.

The sys_get_random() syscall has the following API::

   e_syscall_ret sys_get_random(char *buffer, uint16_t buflen)

.. warning::
   Using sys_get_random requires the specific RES_TSK_RNG permission for security
   reasons (e.g. avoid entropy source exhaustion by an untrusted task). 
   This permission is not needed for initializing the task's canaries as this is
   automatically performed when creating the tasks.
