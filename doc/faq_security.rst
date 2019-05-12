.. _faq_security:

Ewok Security
=============

.. contents::


Why flash is mapped RX and not Execute only for both user and kernel?
----------------------------------------------------------------------

This is a constraint due to .rodata (read only data sections).

Since .rodata must be readable, executable code and such data have to
live together in the same flash area. Using different MPU regions to split
them would have required too much MPU regions (and the number of regions
is very constrained by the hardware unit).

Another solution would be to copy .rodata content into RAM, but this
suffers from the same MPU limitations issues, with the additional drawback
of reducing the available task volatile memory.

Is the W^X principle supported?
--------------------------------

The EwoK kernel enforces the W^X mapping restriction principle, which is a
strong defense in depth mitigation against userland exploitable
vulnerabilities.

Moreover, the Ada kernel integrates SPARK proofs that verify at that there is
no region that can be mapped W and X at the same time.

Is there SSP mechanism?
-----------------------

Yes, the kernel handles KRNG source and generates seeds for each task stack
smashing protection mechanism. All functions (starting with the _main() one) are
protected.


Is there ASLR?
--------------

There is no ASLR as the amount of accessible memory is too small to generate
enough entropy for userspace task memory mapping randomization. Each task has
access to approximately 32KB of memory, which is too few for an effective
ASLR mechanism.

Are there any shared libraries?
-------------------------------

There is no such mechanism, as shared libraries require shared .text memory
including memory abstraction that only a real MMU can bring efficiently.

In microcontrollers, there is no memory abstraction, and as a consequence, no
shared executable content.


