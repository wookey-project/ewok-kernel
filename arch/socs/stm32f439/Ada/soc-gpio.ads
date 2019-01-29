--
-- Copyright 2018 The wookey project team <wookey@ssi.gouv.fr>
--   - Ryad     Benadjila
--   - Arnauld  Michelizza
--   - Mathieu  Renard
--   - Philippe Thierry
--   - Philippe Trebuchet
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
--     Unless required by applicable law or agreed to in writing, software
--     distributed under the License is distributed on an "AS IS" BASIS,
--     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--     See the License for the specific language governing permissions and
--     limitations under the License.
--
--

with system;
with soc.layout;

package soc.gpio
   with
      spark_mode     => on,
      abstract_state => -- Registers
       ((gpio_a   with external),
        (gpio_b   with external),
        (gpio_c   with external),
        (gpio_d   with external),
        (gpio_e   with external),
        (gpio_f   with external),
        (gpio_g   with external),
        (gpio_h   with external),
        (gpio_i   with external)),
      initializes    => -- Assumed as initialized
        (gpio_a, gpio_b, gpio_c, gpio_d,
         gpio_e, gpio_f, gpio_h, gpio_i)
is

   type t_gpio_pin_index is range 0 .. 15
      with size => 4;

   type t_gpio_port_index is
     (GPIO_PA, GPIO_PB, GPIO_PC,
      GPIO_PD, GPIO_PE, GPIO_PF,
      GPIO_PG, GPIO_PH, GPIO_PI) with size => 4;

   -------------------------------------------
   -- GPIO port mode register (GPIOx_MODER) --
   -------------------------------------------

   type t_pin_mode is (MODE_IN, MODE_OUT, MODE_AF, MODE_ANALOG)
      with size => 2;

   for t_pin_mode use
     (MODE_IN     => 0,
      MODE_OUT    => 1,
      MODE_AF     => 2,
      MODE_ANALOG => 3);

   type t_pins_mode is array (t_gpio_pin_index) of t_pin_mode
      with pack, size => 32;

   type t_GPIOx_MODER is record
      pin : t_pins_mode;
   end record
      with pack, size => 32, volatile_full_access;
      -- Note: volatile_full_access: the register is volatile and the full
      --       32-bits needs to be written at once.

   ---------------------------------------------------
   -- GPIO port output type register (GPIOx_OTYPER) --
   ---------------------------------------------------

   type t_pin_output_type is (PUSH_PULL, OPEN_DRAIN)
      with size => 1;

   for t_pin_output_type use
     (PUSH_PULL   => 0,
      OPEN_DRAIN  => 1);

   type t_pins_output_type is array (t_gpio_pin_index) of t_pin_output_type
      with pack, size => 16;

   type t_GPIOx_OTYPER is record
      pin : t_pins_output_type;
   end record
      with size => 32, volatile_full_access;

   for t_GPIOx_OTYPER use record
      pin at 0 range 0 .. 15;
   end record;

   -----------------------------------------------------
   -- GPIO port output speed register (GPIOx_OSPEEDR) --
   -----------------------------------------------------

   type t_pin_output_speed is
     (SPEED_LOW, SPEED_MEDIUM, SPEED_HIGH, SPEED_VERY_HIGH)
      with size => 2;

   for t_pin_output_speed use
     (SPEED_LOW         => 0,
      SPEED_MEDIUM      => 1,
      SPEED_HIGH        => 2,
      SPEED_VERY_HIGH   => 3);

   type t_pins_output_speed is array (t_gpio_pin_index) of t_pin_output_speed
      with pack, size => 32;

   type t_GPIOx_OSPEEDR is record
      pin : t_pins_output_speed;
   end record
      with pack, size => 32, volatile_full_access;

   --------------------------------------------------------
   -- GPIO port pull-up/pull-down register (GPIOx_PUPDR) --
   --------------------------------------------------------

   type t_pin_pupd is (FLOATING, PULL_UP, PULL_DOWN)
      with size => 2;

   for t_pin_pupd use
     (FLOATING    => 0,
      PULL_UP     => 1,
      PULL_DOWN   => 2);

   type t_pins_pupd is array (t_gpio_pin_index) of t_pin_pupd
      with pack, size => 32;

   type t_GPIOx_PUPDR is record
      pin : t_pins_pupd;
   end record
      with pack, size => 32, volatile_full_access;

   -----------------------------------------------
   -- GPIO port input data register (GPIOx_IDR) --
   -----------------------------------------------

   type t_pins_idr is array (t_gpio_pin_index) of bit
      with pack, size => 16;

   type t_GPIOx_IDR is record
      pin      : t_pins_idr;
   end record
      with size => 32, volatile_full_access;

   for t_GPIOx_IDR use record
      pin      at 0 range 0 .. 15;
   end record;

   ------------------------------------------------
   -- GPIO port output data register (GPIOx_ODR) --
   ------------------------------------------------

   type t_pins_odr is array (t_gpio_pin_index) of bit
      with pack, size => 16;

   type t_GPIOx_ODR is record
      pin      : t_pins_odr;
   end record
      with size => 32, volatile_full_access;

   for t_GPIOx_ODR use record
      pin      at 0 range 0 .. 15;
   end record;

   ---------------------------------------------------
   -- GPIO port bit set/reset register (GPIOx_BSRR) --
   ---------------------------------------------------

   type t_pins_bsrr is array (t_gpio_pin_index) of bit
      with pack, size => 16;

   type t_GPIOx_BSRR is record
      BS : t_pins_bsrr;
      BR : t_pins_bsrr;
   end record
      with pack, size => 32, volatile_full_access;

   --------------------------------------------------------
   -- GPIO port configuration lock register (GPIOx_LCKR) --
   --------------------------------------------------------

   type t_pin_lock is (NOT_LOCKED, LOCKED)
      with size => 1;

   for t_pin_lock use
     (NOT_LOCKED  => 0,
      LOCKED      => 1);

   type t_pins_lock is array (t_gpio_pin_index) of t_pin_lock
      with pack, size => 16;

   type t_GPIOx_LCKR is record
      pin      : t_pins_lock;
      lock_key : bit;
   end record
      with size => 32, volatile_full_access;

   for t_GPIOx_LCKR use record
      pin      at 0 range 0  .. 15;
      lock_key at 0 range 16 .. 16;
   end record;

   -------------------------------------------------------
   -- GPIO alternate function low register (GPIOx_AFRL) --
   -------------------------------------------------------

   type t_pin_alt_func is range 0 .. 15 with size => 4;

   -- See RM0090, p. 274
   GPIO_AF_USART1 : constant t_pin_alt_func := 7;
   GPIO_AF_USART2 : constant t_pin_alt_func := 7;
   GPIO_AF_USART3 : constant t_pin_alt_func := 7;
   GPIO_AF_UART4  : constant t_pin_alt_func := 8;
   GPIO_AF_UART5  : constant t_pin_alt_func := 8;
   GPIO_AF_USART6 : constant t_pin_alt_func := 8;
   GPIO_AF_SDIO   : constant t_pin_alt_func := 12;

   type t_pins_alt_func_0_7 is array (t_gpio_pin_index range 0 .. 7)
      of t_pin_alt_func
      with pack, size => 32;

   type t_pins_alt_func_8_15 is array (t_gpio_pin_index range 8 .. 15)
      of t_pin_alt_func
      with pack, size => 32;

   type t_GPIOx_AFRL is record
      pin  : t_pins_alt_func_0_7;
   end record
      with pack, size => 32, volatile_full_access;

   type t_GPIOx_AFRH is record
      pin  : t_pins_alt_func_8_15;
   end record
      with pack, size => 32, volatile_full_access;

   ---------------
   -- Utilities --
   ---------------

   -- enable the input RCC clock of the GPIO IP, given its index
   procedure enable_clock
     (port     : in  t_gpio_port_index);

   -- set the GPIO mode (input, output, alternate, analog)
   procedure set_mode
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      mode     : in  t_pin_mode)
      with
         global => (output => (gpio_a, gpio_b, gpio_c, gpio_d, gpio_e,
                               gpio_f, gpio_g, gpio_h, gpio_i));

   -- set the GPIO type (push-pull, open-drain)
   procedure set_type
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      otype    : in  t_pin_output_type)
      with
         global => (output => (gpio_a, gpio_b, gpio_c, gpio_d, gpio_e,
                               gpio_f, gpio_g, gpio_h, gpio_i));


   -- set the GPIO speed, from low to very high speed
   procedure set_speed
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      ospeed   : in  t_pin_output_speed)
      with
         global => (output => (gpio_a, gpio_b, gpio_c, gpio_d, gpio_e,
                               gpio_f, gpio_g, gpio_h, gpio_i));


   -- set the gpio pull mode (no pull, pull-up or pull-down mode)
   procedure set_pupd
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      pupd     : in  t_pin_pupd)
      with
         global => (output => (gpio_a, gpio_b, gpio_c, gpio_d, gpio_e,
                               gpio_f, gpio_g, gpio_h, gpio_i));


   -- set the GPIO behavior on the output data register bit write action
   -- (reset action)
   procedure set_bsr_r
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      bsr_r    : in  types.bit)
      with
         global => (output => (gpio_a, gpio_b, gpio_c, gpio_d, gpio_e,
                               gpio_f, gpio_g, gpio_h, gpio_i));


   -- set the GPIO behavior on the output data register bit write action
   -- (set action)
   procedure set_bsr_s
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      bsr_s    : in  types.bit)
      with
         global => (output => (gpio_a, gpio_b, gpio_c, gpio_d, gpio_e,
                               gpio_f, gpio_g, gpio_h, gpio_i));


   -- lock the GPIO configuration
   procedure set_lck
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      lck      : in  t_pin_lock)
      with
         global => (output => (gpio_a, gpio_b, gpio_c, gpio_d, gpio_e,
                               gpio_f, gpio_g, gpio_h, gpio_i));

   -- set the GPIO alternate function (see the SoC datasheet to get the
   -- list of available alternate functions)
   procedure set_af
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      af       : in  t_pin_alt_func)
      with
         global => (output => (gpio_a, gpio_b, gpio_c, gpio_d, gpio_e,
                               gpio_f, gpio_g, gpio_h, gpio_i));

   -- set the GPIO output value on GPIO in output mode
   procedure write_pin
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      value    : in  bit)
      with
         global => (in_out => (gpio_a, gpio_b, gpio_c, gpio_d, gpio_e,
                               gpio_f, gpio_g, gpio_h, gpio_i)),
         -- Each GPIO port depend on itself and the input value to set
         depends => (gpio_a =>+ value, gpio_b =>+ value, gpio_c =>+ value,
                     gpio_d =>+ value, gpio_e =>+ value, gpio_f =>+ value,
                     gpio_g =>+ value, gpio_h =>+ value, gpio_i =>+ value,
                     null   =>  (port, pin));


   -- set the GPIO input value on GPIO in input mode
   procedure read_pin
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      value    : out bit)
      with
         global => (in_out=> (gpio_a, gpio_b, gpio_c, gpio_d, gpio_e,
                              gpio_f, gpio_g, gpio_h, gpio_i)),
         depends => (gpio_a =>+ null, gpio_b =>+ null, gpio_c =>+ null,
                     gpio_d =>+ null, gpio_e =>+ null, gpio_f =>+ null,
                     gpio_g =>+ null, gpio_h =>+ null, gpio_i =>+ null,
                     value  => (gpio_a, gpio_b, gpio_c, gpio_d,
                                gpio_e, gpio_f, gpio_h, gpio_i),
                     null   =>  (port, pin));


private

   ---------------
   -- GPIO port --
   ---------------

   type t_GPIO_port is record
      MODER       : t_GPIOx_MODER;
      OTYPER      : t_GPIOx_OTYPER;
      OSPEEDR     : t_GPIOx_OSPEEDR;
      PUPDR       : t_GPIOx_PUPDR;
      IDR         : t_GPIOx_IDR;
      ODR         : t_GPIOx_ODR;
      BSRR        : t_GPIOx_BSRR;
      LCKR        : t_GPIOx_LCKR;
      AFRL        : t_GPIOx_AFRL;
      AFRH        : t_GPIOx_AFRH;
   end record
      with volatile;

   for t_GPIO_port use record
      MODER       at 16#00# range 0 .. 31;
      OTYPER      at 16#04# range 0 .. 31;
      OSPEEDR     at 16#08# range 0 .. 31;
      PUPDR       at 16#0C# range 0 .. 31;
      IDR         at 16#10# range 0 .. 31;
      ODR         at 16#14# range 0 .. 31;
      BSRR        at 16#18# range 0 .. 31;
      LCKR        at 16#1C# range 0 .. 31;
      AFRL        at 16#20# range 0 .. 31;
      AFRH        at 16#24# range 0 .. 31;
   end record;


   ----------------------
   -- GPIO peripherals --
   ----------------------

   GPIOA : aliased t_GPIO_port
      with import, volatile,
           address => system'to_address (soc.layout.GPIOA_BASE),
           part_of => gpio_a;

   GPIOB : aliased t_GPIO_port
      with import, volatile,
           address => system'to_address (soc.layout.GPIOB_BASE),
           part_of => gpio_b;

   GPIOC : aliased t_GPIO_port
      with import, volatile,
           address => system'to_address (soc.layout.GPIOC_BASE),
           part_of => gpio_c;

   GPIOD : aliased t_GPIO_port
      with import, volatile,
           address => system'to_address (soc.layout.GPIOD_BASE),
           part_of => gpio_d;

   GPIOE : aliased t_GPIO_port
      with import, volatile,
           address => system'to_address (soc.layout.GPIOE_BASE),
           part_of => gpio_e;

   GPIOF : aliased t_GPIO_port
      with import, volatile,
           address => system'to_address (soc.layout.GPIOF_BASE),
           part_of => gpio_f;

   GPIOG : aliased t_GPIO_port
      with import, volatile,
           address => system'to_address (soc.layout.GPIOG_BASE),
           part_of => gpio_g;

   GPIOH : aliased t_GPIO_port
      with import, volatile,
           address => system'to_address (soc.layout.GPIOH_BASE),
           part_of => gpio_h;

   GPIOI : aliased t_GPIO_port
      with import, volatile,
           address => system'to_address (soc.layout.GPIOI_BASE),
           part_of => gpio_i;

end soc.gpio;
