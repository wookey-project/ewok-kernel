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

with soc.rcc;

-- About SPARK:
-- In this driver implementation, there is no such
-- complex algorithmic requiring effective SPARK prove,
-- as the package body is only composed on registers
-- fields setters and getters. Using SPARK in this
-- package body would be mostly useless in this very
-- case

package body soc.gpio
   with spark_mode => off
is

   -- Here we choose to use local accessors instead of
   -- a full switch case, in order to:
   --   1) reduce the generated asm
   --   2) avoid writting errors in switch/case write which
   --      can't be detected through SPARK rules

   type t_GPIO_port_access is access all t_GPIO_port;

   GPIOx : constant array (t_gpio_port_index) of t_GPIO_port_access :=
     (GPIOA'access, GPIOB'access, GPIOC'access, GPIOD'access, GPIOE'access,
      GPIOF'access, GPIOG'access, GPIOH'access, GPIOI'access);


   -- FIXME - Should be in soc.rcc package
   procedure enable_clock
     (port     : in  t_gpio_port_index)
   is
   begin
      case port is
         when GPIO_PA => soc.rcc.RCC.AHB1ENR.GPIOAEN := true;
         when GPIO_PB => soc.rcc.RCC.AHB1ENR.GPIOBEN := true;
         when GPIO_PC => soc.rcc.RCC.AHB1ENR.GPIOCEN := true;
         when GPIO_PD => soc.rcc.RCC.AHB1ENR.GPIODEN := true;
         when GPIO_PE => soc.rcc.RCC.AHB1ENR.GPIOEEN := true;
         when GPIO_PF => soc.rcc.RCC.AHB1ENR.GPIOFEN := true;
         when GPIO_PG => soc.rcc.RCC.AHB1ENR.GPIOGEN := true;
         when GPIO_PH => soc.rcc.RCC.AHB1ENR.GPIOHEN := true;
         when GPIO_PI => soc.rcc.RCC.AHB1ENR.GPIOIEN := true;
      end case;
   end enable_clock;


   procedure set_mode
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      mode     : in  t_pin_mode)
      with
         refined_global => (output => (gpio_a, gpio_b, gpio_c,
                                       gpio_d, gpio_e, gpio_f,
                                       gpio_g, gpio_h, gpio_i))
   is
   begin
      GPIOx(port).all.MODER.pin(pin)   := mode;
   end set_mode;


   procedure set_type
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      otype    : in  t_pin_output_type)
      with
         refined_global => (output => (gpio_a, gpio_b, gpio_c,
                                       gpio_d, gpio_e, gpio_f,
                                       gpio_g, gpio_h, gpio_i))
   is
   begin
      GPIOx(port).all.OTYPER.pin(pin)   := otype;
   end set_type;


   procedure set_speed
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      ospeed   : in  t_pin_output_speed)
      with
         refined_global => (output => (gpio_a, gpio_b, gpio_c,
                                       gpio_d, gpio_e, gpio_f,
                                       gpio_g, gpio_h, gpio_i))
   is
   begin
      GPIOx(port).all.OSPEEDR.pin(pin)  := ospeed;
   end set_speed;


   procedure set_pupd
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      pupd     : in  t_pin_pupd)
      with
         refined_global => (output => (gpio_a, gpio_b, gpio_c,
                                       gpio_d, gpio_e, gpio_f,
                                       gpio_g, gpio_h, gpio_i))
   is
   begin
      GPIOx(port).all.PUPDR.pin(pin)  := pupd;
   end set_pupd;


   procedure set_bsr_r
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      bsr_r    : in  types.bit)
      with
         refined_global => (output => (gpio_a, gpio_b, gpio_c,
                                       gpio_d, gpio_e, gpio_f,
                                       gpio_g, gpio_h, gpio_i))
   is
   begin
      GPIOx(port).all.BSRR.BR(pin) := bsr_r;
   end set_bsr_r;


   procedure set_bsr_s
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      bsr_s    : in  types.bit)
      with
         refined_global => (output => (gpio_a, gpio_b, gpio_c,
                                       gpio_d, gpio_e, gpio_f,
                                       gpio_g, gpio_h, gpio_i))
   is
   begin
      GPIOx(port).all.BSRR.BS(pin) := bsr_s;
   end set_bsr_s;


   procedure set_lck
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      lck      : in  t_pin_lock)
      with
         refined_global => (output => (gpio_a, gpio_b, gpio_c,
                                       gpio_d, gpio_e, gpio_f,
                                       gpio_g, gpio_h, gpio_i))
   is
   begin
      GPIOx(port).all.LCKR.pin(pin)  := lck;
   end set_lck;


   procedure set_af
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      af       : in  t_pin_alt_func)
      with
         refined_global => (output => (gpio_a, gpio_b, gpio_c,
                                       gpio_d, gpio_e, gpio_f,
                                       gpio_g, gpio_h, gpio_i))
   is
   begin
      if pin < 8 then
         GPIOx(port).all.AFRL.pin(pin)  := af;
      else
         GPIOx(port).all.AFRH.pin(pin)  := af;
      end if;
   end set_af;


   procedure write_pin
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      value    : in  bit)
      with
         refined_global => (in_out => (gpio_a, gpio_b, gpio_c,
                                       gpio_d, gpio_e, gpio_f,
                                       gpio_g, gpio_h, gpio_i))
   is
   begin
      GPIOx(port).all.ODR.pin (pin) := value;
   end write_pin;


   procedure read_pin
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      value    : out bit)
      with
         refined_global => (in_out => (gpio_a, gpio_b, gpio_c,
                                       gpio_d, gpio_e, gpio_f,
                                       gpio_g, gpio_h, gpio_i))
   is
   begin
      value := GPIOx(port).all.IDR.pin (pin);
   end read_pin;

end soc.gpio;
