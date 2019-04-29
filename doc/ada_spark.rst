.. _ada_spark:

Ewok Ada/SPARK kernel
=====================

The EwoK microkernel is an Ada/SPARK kernel with very few lines of C.

Why implementing Ewok in Ada ?
------------------------------

Most kernels and microkernels are written in C.
The major drawback of the C language is its proneness to
coding errors. Out-of-bound array accesses, integer overflows and dangling
pointers are difficult to avoid due to the weakly enforced typing. Such
bugs can become nonetheless devastating when exploited in a privileged
context.
A way to prevent such vulnerabilities is to use a safe language or to
use formal methods to prove the lack of runtime error.

Using a safe language for implementing low-level kernel code is an
approach that goes back to the early 1970’s.
However, there are very few alternative and we made the choice of
`Ada <https://www.adacore.com/>`_, designed for building high-confidence and
safety-critical applications and embedded systems.

.. note::
   The Ada/SPARK kernel is based on about 10 Klines of Ada and
   about 500 lines of C and assembly.

From C to Ada
-------------

Developing in C and in Ada is quite different.
However, interoperability between these two languages is very facilitated
by the GNAT providing a
`full interface to C <https://docs.adacore.com/gnat_rm-docs/html/gnat_rm/gnat_rm/interfacing_to_other_languages.html#>`_.

To allow an
implementation of interchangeable Ada and C modules, Ada modules are decomposed
in two main blocks:

   * A small interface design pattern which helps to abstract the Ada part of
     the module and serves the same API as the equivalent C module

       * This interface has nearly no intelligence at all and export all its
         types, functions and procedures to C code
   * The Ada module itself, which is free to use an Ada-oriented paradigm

.. note::
   See also, this `website <https://learn.adacore.com/>`_ is a really valuable resource
   for learning Ada.

The EwoK kernel supports a dual implementation (C & Ada). Each module Ada/Spark
implementation replaces the C implementation in the Ada version of the kernel.
The Ada/Spark port with API compatible support of each module has been done
progressively, by integrating the first Ada/Spark modules as exceptions, then
reducing the C interface to the residual C modules only.

*initial Ada/Spark integration*

.. image:: img/ada_c.png
   :width: 400 px
   :alt: Ework Ada/C integration
   :align: center

*Finalization of Ada/Spark integration*

.. image:: img/ada_c_2.png
   :width: 400 px
   :alt: Ework Ada/C integration
   :align: center


Importing C symbols in Ada
""""""""""""""""""""""""""

.. highlight:: ada

Importing a C symbol in an Ada program is done using the following directive::

   function my_ada_function ( myarg : unsigned_8) return unsigned_32
   with
      convention     => c,
      import         => true,
      external_name  => "my_c_function",
      global         => null;

Using this directive, the symbol resolved by ``my_c_function`` in the C object
file can be used using ``my_ada_function`` in the Ada implementation.

When importing a C function, it is required to comply with less restrictive
types such as unsigned_32, unsigned_8 or bit-length boolean (Ada booleans
are bigger types).

To do so, writing a C types specification for Ada is highly recommended.
EwoK keeps its C types for Ada in the Ada types.c unit of the libbsp.

As using C symbols makes Ada strict typing and SPARK inefficient, their usage
must be reduced to a **small and controlled subset of the Ada code**.

In the EwoK case, using C symbols is reduced to the Ada/C interface unit only.
This interface has no algorithmic intelligence but must take care of the
overtyped C arguments when using C symbols.

.. highlight:: c

A typical usage would be, for the following C code ::

   uint8_t nvic_get_pending_irq()
   {
      ... // return the IRQ number as an uint8_t
   }

.. highlight:: ada

An Ada interface that could look like the following ::

   with ada.unchecked_conversion;
   pragma warnings (off);
   function to_t_interrupt is new ada.unchecked_conversion
      (unsigned_8, t_interrupt);
   pragma warnings (on);

   -- t_interrupt is an Ada type listing only the effective existing
   -- IRQs (IRQ 1 to IRQ 96 for e.g.)
   function get_interrupt(irq : out t_interrupt)
   is
     local_irq : unsigned_8;
   begin
       local_irq := nvic_get_pending_irq();
       if local_irq in t_interrupt'range then
          irq = to_t_interrupt(local_irq);
       else
          -- raise exception or react in any way
       end if;
   end

Exporting Ada symbols to C
""""""""""""""""""""""""""

Exporting Ada symbols to C is done using the same philosophy ::

   -- initialize the DWT module
   -- This procedure is called by the kernel main() function, and as
   -- a consequence exported to C
   procedure init
    with
      convention => c,
      export => true,
      external_name => "soc_dwt_init";

Nevertheless, there are some cases that require extra care and attention:
**when specific types are handled differently in Ada and C**.
This is the case of strings, which are more complex and **not**
null-terminated in Ada, or boolean, which are encoded on 8-bits fields.

To solve such an issue, we define for the Ada code some C-compatible
types. Here is an example of a C compatible boolean implementation ::

   type bool is new boolean with size => 1;
   for bool use (true => 1, false => 0);

Ada sources
-----------

EwoK Ada sources are hosted in the following directories:

   * kernel/Ada for the kernel, arch-independent Ada code
   * kernel/Ada/generated hosts the generated Ada files, like kernel/generated
     hosts the generated C files
   * arch-specific Ada content (BSP) is hosted in the Ada subdirectory of each SoC and
     core source directory

Ada has a hierarchical scoping principle, based on packages. In the case of
EwoK, various packages and subpackages are used.

   * kernel pacakges belong to the `ewok` package
   * SoC-related packages belong to the `soc` package
   * Core-related packages belong to the core-relative package (e.g. `m4` for
     Cortex-M4)

As the EwoK kernel is an hybrid C/Ada/SPARK kernel, some packages require
an external interface with the C code. For a given package *foo* interacting
with external C code, a *foo_interface* package must exist.

In the same way, as some various C types (structures, union, enumerates, etc.)
have to be used in the interfaces packages, the following C-specific packages
exist, containing only specifications:

   * c package containing all C types and API that are arch-independent
   * c_soc package, containing all C types and API that are SoC-specific

Preprocessing in Ada
--------------------

Ada does support preprocessing and the configuration options sometime
use the preprocessing principle to enable or not some specific functions.
The preprocessing usage is quite similar to C ::

   #if CONFIG_KERNEL_DOMAIN
      function is_same_domain
        (from    : in t_real_task_id;
         to      : in t_real_task_id)
      return boolean
      with
         Global    => null,
         Post      => (if (from = to) then is_same_domain'Result = false);
   #end if;


Generated files
---------------

Generated files are not created by the microkernel internal tools, but by the
SDK. The reason is that the generated files contain information about the
applications list, associated permissions and layout. All these information
are stored by the SDK configuration mechanism, not by the kernel itself.

The scripts generating these files (and the C equivalent) are hosted in the
tools/ directory of the SDK:

   * tools/gen_ld: generates the global layout and the application layout header
   * tools/gen_symhdr.pl: generates the applications section mapping. Used to
     map .data and zeroify .bss of each application at boot time
   * tools/apps/permissions.pl: generates the application permissions header



SPARK in EwoK
=============

.. highlight:: ada

EwoK uses SPARK in the modules requiring formal validation and proofs.

Here is an example of such usage ::

   function ipc_is_granted
      (from    : in t_real_task_id;
       to      : in t_real_task_id)
       return boolean
          with
             Global         => (Input => ewok.perm_auto.com_ipc_perm),
             Post           => (if (from = to) then ipc_is_granted'Result = false),
             Contract_Cases => (ewok.perm_auto.com_ipc_perm(from,to) => ipc_is_granted'Result,
                                others                               => not ipc_is_granted'Result);

This specification uses various SPARK properties:

   * Global usage declaration, which allows to specify that the function is
     using a global variable of the ewok.perm_auto package as read only.
   * Postcondition specification, requiring that for the specific use case
     where from and to are equal, the result of the function must be false,
     whatever the table content is.
   * A contract case, that describes the contract of the function as a fixed
     length list of possible values. This list is the exhaustive list of the
     possible results.

Impact of SPARK
---------------

Spark helps to prove the absence of RTE (Run Time Errors) on the blocks of
code that has been correctly proven. We also use it to validate some specific
security-oriented behaviors.

A typical example is to prove that the kernel never maps a memory region which
can be both writeable and executable (aka W^X proof).

For this, we use ghost functions and preconditions. The ghost function checks
the wanted properties, the precondition is checked at build time by the prover.
If the prover can't prove it at build time (e.g. when inputs depend on dynamic
content, lazy checks, etc.) the prover refuses to validate the precondition.

Here is the ghost function checking the W^X conditions on the STM32 MPU ::

   -- Only used by SPARK prover
   function region_not_rwx(region : t_region_config) return boolean
       is (region.xn = true or region.access_perm = REGION_AP_RO_RO or
           region.access_perm = REGION_AP_NO_NO)
       with ghost;


