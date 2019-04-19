Permissions FAQ
===============

When using a library or a driver, are specific permissions required?
--------------------------------------------------------------------

There is no permission needed to link to a given userspace library or driver,
but they may require one ore more permission to work properly.

For example, the libconsole (managing a userspace serial console) requires
the Devices/Buses permission in order to use the libusart and configure the
specified U(S)ART correctly.

How to be sure of the requested permissions a driver needs?
-----------------------------------------------------------

When a driver is manipulating a hardware ressource (i.e. a device), the
associated permission is declared in the device list json file stored in
*layouts/arch/socs/soc-devmap-<projname>.json*.

Each device has a permission field which is a string value that can be compared
to the effective permission name as managed by EwoK, and configurable in the
configuration tool of the application using the driver.

.. hint::
   When writing a driver, it is usually a good idea to specify the requested
   permission(s) in a README file in the driver sources root path.

When manipulating devices or events that are not a part of the layout file
(e.g. external interrupts -EXTI) this should be done using dedicated permission
in the application permission list. Most of the permissions are device oriented
and, as is, should be not too hard to detect. If the permission is missing at
runtime, the kernel will explicitely indicate that the device registration is
not permitted.

.. hint::
   For EXTIs, they are usually a part of a bigger device which is globally
   refused if the permission is not set

May drivers require non-ressource related permissions?
------------------------------------------------------

This can happen depending on the driver implementation **and** usage.

A typical example is the *usart* driver. This driver can be used by an
application in two modes:

   * automatically mapped mode
   * manually mapped mode

In automatically mapped mode, there is no specific supplementary permission
needed. In manually mapped mode, the userspace task can voluntary map/unmap the
u(s)art device at will during its nominal phase. This behavior permits to
manage potentally big number of devices in a same application without mapping
all of them in the same time.

This capacity (i.e. to map and unmap devices) is associated to a permission
(PERM_RES_MEM_DYNAMIC_MAP), that is required if the application has configured
the driver is this very mode.

.. hint::
   Such non-device related permissions are most of the time dependent on the
driver API usage

Why is there a permission for time measurement?
-----------------------------------------------

Is there a real good reason for all the tasks to have the hability to precisely
measure the time ?

When a task has the hability to precisely measure time periods, it has
*de-facto* the hability to detect the behavior of other tasks (yield time,
scheduling behavior, IPC response time and so on), which permit to initiate
multiple side and covert channels between tasks.

In EwoK, we have decice:

   * To associate time measurement hability with a permission
   * To define three levels of time measurement permissions, from milliseconds
     to cycle count precision level

.. warning::
   take care to define only the adequate level of time measurement permissions
   for your tasks. They should not have (for nearly all nominal usage) access to
   cycle accurate time access

Why is there three level of crypto access permission?
-----------------------------------------------------

When there is a cryptographic coprocessor, there is various way to use it:

   * handling secrets (typically injecting secret keys in the device registers)
   * requesting cryptographic processing in black box mode (sending clear text
     or cyphered text and getting back the (un)cyphered content from the
     device, without knowing the secrets used
   * handling the both accesses

In the Wookey project, secrets handling and cryptogrphic dataplane are
separated in two tasks, requesting, for the secret handling, the
PERM_RES_CRYPTO_CFG permission, and for the crytographic requests, the
PERM_RES_CRYPTO_USER permission. This permits to lock any access to the
configuration registers (including the secrets registers) to the task handling
cryptographic processing.

If you whish to handle both access in the same task, you can use the
PERM_RES_CRYPTO_FULL permission, which permit to handle all the requested
actions, mapping all the needed device registers in the task memory layout.

What is PERM_RES_TSK_RNG?
-------------------------

EwoK handle a KRNG (Kernel-based Random Number Generator) mechanism. This
permits to initialize the SSP (Stack Smashing Protection) seed for each task
canaries.

When a task is requiring random data, it has two possibilities:

   * implement its own software-based RNG
   * ask the kernel for random content

When the hardware device hosts a (T)RNG (the STM32F339 hosts a certified True
Random Number Generator), the kernel is using it and is able to distribute
trusted randomness to userspace tasks. Why a permission then ? It is globally
not a good idea to request too much randomness from a RNG source, as it may
generate less random content, making the RNG source less efficient. To avoid
attacks based on RNG exhaustivity, only tasks that **really** requires
randomness should be able to require randomness from KRNG source, reducing the
attack surface of the KRNG.

.. hint::
   There is no permission needed to initialize the tasks SSP mechanism


