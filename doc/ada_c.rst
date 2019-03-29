Ada/C integration
=================

General principle
-----------------

The EwoK microkernel is an hybrid C/Ada kernel. It can be compiled as a
full-C kernel or as a better certified C/Ada/SPARK microkernel using
a single configuration option in the Tataouine SDK menuconfig.

.. image:: img/mc_ada.png
   :width: 500 px
   :alt: Ework Ada/Spark mode activation
   :align: center


When activating this option, the following elements are setup:

   * For the kernel sources:

      * a complete libada for the kernel (named libkernel) is built, using all Ada packages in the kernel/Ada directory
      * all C files named <module>.c in kernel/ directory for which an Ada file named 'ewok-<module>.adb' exists in kernel/Ada directory are removed from the list of compiled C files
   * For the libbsp

      * a complete Ada bsp lib (named libabsp) is build, using all Ada packages in arch/ directory
      * all C files named <module>.c in various arch directories for which an Ada file named 'arch-<module>.adb' exists in the Ada directory of the same place are removed from the list of compiled C files
   * libkernel and libabsp are linked together. As it is still a full Ada code, SPARK checks and Ada type checking between the two libraries are still operational
   * The residual C code of arch/ is linked into a smaller libbsp
   * The residual C code of the kernel is compiled to generate the remaining C object files
   * Everything is linked into one single ELF binary, symbols are resolved and C and Ada code can call each-other

.. highlight:: make

Deleting the C equivalent of Ada files is done in various Makefiles using the same GNU Make code::

   # deleting C files having their Ada equivalent from the C/obj list
   ADACEQ = $(patsubst Ada/ewok-%.adb,%.c,$(ASRC))
   SRC_TMP = $(filter-out $(ADACEQ),$(SRC))
   SRC := $(SRC_TMP)
   OBJ := $(patsubst %.c,$(APP_BUILD_DIR)/%.o,$(SRC))


All the autonomous Ada implementations help to guarantee higher safety and security thanks to the Ada language properties. However, all the interactions with the residual C code loose these properties,
this is why such interactions between C and Ada are kept to a minimum.

From C to Ada paradigm
----------------------

Development paradigms between Ada and C may be quite different. To allow an implementation of interchangeable Ada and C modules, Ada modules are decomposed in two main blocks:

   * A small interface design pattern which helps to abstract the Ada part of the module and serves the same API as the equivalent C module

       * This interface has nearly no intelligence at all and export all its types, functions and procedures to C code
   * The Ada module itself, which is free to use an Ada-oriented paradigm

The EwoK kernel supports a dual implementation (C & Ada). Each module Ada/Spark implementation replaces the C implementation in the Ada version of the kernel.
The Ada/Spark port with API compatible support of each module has been done progressively, by integrating the first Ada/Spark modules as exceptions, then
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


Importing C symbols
"""""""""""""""""""

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

.. highlight:: vhdl

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

Current state of Ada port
-------------------------

The following table is generated by tools/genlist.sh of Tataouine and shows, for each
C file, if there is an Ada or Spark equivalent. If there is, the hybrid EwoK kernel
is using the Ada implementation instead when the ADAKERNEL option is set to *yes*
in the menuconfig.


================================================  ================================================  =========
C                                                 Ada                                               SPARK
================================================  ================================================  =========
Ada/libgnat/gnat/last_chance_handler.c                                                              
arch/boards/shared.c                                                                                
arch/cores/armv7-m/m4-fpu.c                                                                         
arch/cores/armv7-m/m4-mpu.c                       arch/cores/armv7-m/Ada/m4-mpu.adb                 **yes**
arch/cores/armv7-m/m4-systick.c                   arch/cores/armv7-m/Ada/m4-systick.adb             **yes**
arch/debug.c                                                                                        
arch/get_random.c                                                                                   
arch/libc.c                                                                                         
arch/socs/stm32f439/default_handlers.c            arch/socs/stm32f439/Ada/default_handlers.adb      no
arch/socs/stm32f439/postpone.c                                                                      
arch/socs/stm32f439/soc-devmap.c                                                                    
arch/socs/stm32f439/soc-dma.c                     arch/socs/stm32f439/Ada/soc-dma.adb               no
arch/socs/stm32f439/soc-dwt.c                     arch/socs/stm32f439/Ada/soc-dwt.adb               **yes**
arch/socs/stm32f439/soc-exti.c                    arch/socs/stm32f439/Ada/soc-exti.adb              no
arch/socs/stm32f439/soc-gpio.c                    arch/socs/stm32f439/Ada/soc-gpio.adb              no
arch/socs/stm32f439/soc-init.c                                                                      
arch/socs/stm32f439/soc-interrupts.c              arch/socs/stm32f439/Ada/soc-interrupts.adb        **yes**
arch/socs/stm32f439/soc-iwdg.c                                                                      
arch/socs/stm32f439/soc-rcc.c                                                                       
arch/socs/stm32f439/soc-rng.c                                                                       
arch/socs/stm32f439/soc-usart.c                                                                     
arch/stack_check.c                                                                                  
devices.c                                         Ada/ewok-devices.adb                              no
dma.c                                             Ada/ewok-dma.adb                                  no
exti.c                                            Ada/ewok-exti.adb                                 no
exti-handler.c                                    Ada/ewok-exti-handler.adb                         no
gpio.c                                            Ada/ewok-gpio.adb                                 no
init.c                                                                                              
ipc.c                                             Ada/ewok-ipc.adb                                  no
isr.c                                             Ada/ewok-isr.adb                                  no
led.c                                                                                               
mpu.c                                             Ada/ewok-mpu.adb                                  **yes**
mpu-handler.c                                     Ada/ewok-mpu-handler.adb                          no
perm.c                                            Ada/ewok-perm.adb                                 **yes**
posthook.c                                        Ada/ewok-posthook.adb                             no
sanitize.c                                        Ada/ewok-sanitize.adb                             **yes**
sched.c                                           Ada/ewok-sched.adb                                **yes**
sleep.c                                           Ada/ewok-sleep.adb                                no
softirq.c                                         Ada/ewok-softirq.adb                              no
syscalls-handler.c                                Ada/ewok-syscalls-handler.adb                     no
syscalls/syscalls-cfg.c                           Ada/syscalls/ewok-syscalls-cfg.adb                no
syscalls/syscalls-cfg-gpio.c                      Ada/syscalls/ewok-syscalls-cfg-gpio.adb           no
syscalls/syscalls-cfg-mem.c                       Ada/syscalls/ewok-syscalls-cfg-mem.adb            no
syscalls/syscalls-dma.c                           Ada/syscalls/ewok-syscalls-dma.adb                no
syscalls/syscalls-gettick.c                       Ada/syscalls/ewok-syscalls-gettick.adb            no
syscalls/syscalls-init.c                          Ada/syscalls/ewok-syscalls-init.adb               no
syscalls/syscalls-ipc.c                           Ada/syscalls/ewok-syscalls-ipc.adb                no
syscalls/syscalls-lock.c                          Ada/syscalls/ewok-syscalls-lock.adb               no
syscalls/syscalls-reset.c                         Ada/syscalls/ewok-syscalls-reset.adb              no
syscalls/syscalls-sleep.c                         Ada/syscalls/ewok-syscalls-sleep.adb              no
syscalls/syscalls-yield.c                         Ada/syscalls/ewok-syscalls-yield.adb              no
tasks.c                                           Ada/ewok-tasks.adb                                no
usart.c                                                                                             
================================================  ================================================  =========

