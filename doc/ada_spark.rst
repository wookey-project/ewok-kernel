.. _ada_spark:

Ada/SPARK for a secure kernel
=============================

The EwoK microkernel is an Ada/SPARK kernel with a bit of assembly.

Why implementing Ewok in Ada?
-----------------------------

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
However, there are very few alternatives and we made the choice of
`Ada <https://www.adacore.com/>`_, designed for building high-confidence and
safety-critical applications in embedded systems.

.. note::
   The Ada/SPARK kernel is based on about 10 Klines of Ada and
   about 500 lines of C and assembly.

From C to Ada
-------------

Interoperability between C and Ada is facilitated
by GNAT providing a
`full interface to C <https://docs.adacore.com/gnat_rm-docs/html/gnat_rm/gnat_rm/interfacing_to_other_languages.html#>`_.

Importing C symbols in Ada
""""""""""""""""""""""""""

.. highlight:: vhdl

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

A typical usage would be, for the following C code::

   uint8_t nvic_get_pending_irq()
   {
      ... // return the IRQ number as an uint8_t
   }

.. highlight:: ada

An Ada interface that could look like the following::

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

Exporting Ada symbols to C is done using the same philosophy::

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
types. Here is an example of a C compatible boolean implementation::

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

   * kernel packages belong to the `ewok` package
   * SoC-related packages belong to the `soc` package
   * Core-related packages belong to the core-relative package (e.g. `m4` for
     Cortex-M4)

Preprocessing in Ada
--------------------

Ada does support preprocessing and the configuration options sometime
use the preprocessing principle to enable or not some specific functions.
The preprocessing usage is quite similar to C::

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

The scripts generating these files are hosted in the tools/ directory of the
SDK:

   * tools/gen_ld: generates the global layout and the application layout header
   * tools/gen_symhdr.pl: generates the applications section mapping. Used to
     map .data and zeroify .bss of each application at boot time
   * tools/apps/permissions.pl: generates the application permissions header


Static verification with SPARK
------------------------------

SPARK allows to prove the lack of *Run Time Errors* in some code.

.. highlight:: ada

EwoK uses `SPARK <https://www.adacore.com/about-spark>`_ in the modules
requiring formal validation and proofs. Example::

   function ipc_is_granted
      (from    : in t_real_task_id;
       to      : in t_real_task_id)
       return boolean
          with
             Global         => (Input => ewok.perm_auto.com_ipc_perm),
             Post           => (if (from = to) then ipc_is_granted'Result = false),
             Contract_Cases => (ewok.perm_auto.com_ipc_perm(from,to) => ipc_is_granted'Result,
                                others                               => not ipc_is_granted'Result);

This specification uses various SPARK *contracts*:

   * ``Contract_Case`` describes the contract that must be satisfied by
     the subprogram
   * ``Global`` describes the global variables used by a subprogram
   * ``Postcondition`` indicates conditions that must be satisfied
     when the program has completed.

SPARK in Ewok
"""""""""""""

With SPARK, we proved that the kernel never maps a memory region which
can be both writable and executable (*W^X* security principle).

