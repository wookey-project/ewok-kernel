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

package body soc.gpio
   with spark_mode => off
is

   type t_GPIO_port_access is access all t_GPIO_port;

   function get_port_access
     (port : t_gpio_port_index) return t_GPIO_port_access
   is
   begin
      case port is
         when GPIO_PA => return soc.gpio.GPIOA'access;
         when GPIO_PB => return soc.gpio.GPIOB'access;
         when GPIO_PC => return soc.gpio.GPIOC'access;
         when GPIO_PD => return soc.gpio.GPIOD'access;
         when GPIO_PE => return soc.gpio.GPIOE'access;
         when GPIO_PF => return soc.gpio.GPIOF'access;
         when GPIO_PG => return soc.gpio.GPIOG'access;
         when GPIO_PH => return soc.gpio.GPIOH'access;
         when GPIO_PI => return soc.gpio.GPIOI'access;
      end case;
   end get_port_access;


   -- FIXME - Should be in soc.rcc package
   procedure enable_clock
     (port     : in  t_gpio_port_index)
   is
   begin
      case port is
         when GPIO_PA => soc.rcc.RCC.AHB1.GPIOAEN := true;
         when GPIO_PB => soc.rcc.RCC.AHB1.GPIOBEN := true;
         when GPIO_PC => soc.rcc.RCC.AHB1.GPIOCEN := true;
         when GPIO_PD => soc.rcc.RCC.AHB1.GPIODEN := true;
         when GPIO_PE => soc.rcc.RCC.AHB1.GPIOEEN := true;
         when GPIO_PF => soc.rcc.RCC.AHB1.GPIOFEN := true;
         when GPIO_PG => soc.rcc.RCC.AHB1.GPIOGEN := true;
         when GPIO_PH => soc.rcc.RCC.AHB1.GPIOHEN := true;
         when GPIO_PI => soc.rcc.RCC.AHB1.GPIOIEN := true;
      end case;
   end enable_clock;


   procedure set_mode
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      mode     : in  t_pin_mode)
      with
         refined_global => (output => (GPIOA, GPIOB, GPIOC,
                                       GPIOD, GPIOE, GPIOF,
                                       GPIOG, GPIOH, GPIOI))
   is
      gpio_port : constant t_GPIO_port_access := get_port_access (port);
   begin
      gpio_port.all.MODER.pin(pin)   := mode;
   end set_mode;


   procedure set_type
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      otype    : in  t_pin_output_type)
      with
         refined_global => (output => (GPIOA, GPIOB, GPIOC,
                                       GPIOD, GPIOE, GPIOF,
                                       GPIOG, GPIOH, GPIOI))
   is
      gpio_port : constant t_GPIO_port_access := get_port_access (port);
   begin
      gpio_port.all.OTYPER.pin(pin)   := otype;
   end set_type;


   procedure set_speed
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      ospeed   : in  t_pin_output_speed)
      with
         refined_global => (output => (GPIOA, GPIOB, GPIOC,
                                       GPIOD, GPIOE, GPIOF,
                                       GPIOG, GPIOH, GPIOI))
   is
      gpio_port : constant t_GPIO_port_access := get_port_access (port);
   begin
      gpio_port.all.OSPEEDR.pin(pin)  := ospeed;
   end set_speed;


   procedure set_pupd
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      pupd     : in  t_pin_pupd)
      with
         refined_global => (output => (GPIOA, GPIOB, GPIOC,
                                       GPIOD, GPIOE, GPIOF,
                                       GPIOG, GPIOH, GPIOI))
   is
      gpio_port : constant t_GPIO_port_access := get_port_access (port);
   begin
      gpio_port.all.PUPDR.pin(pin)  := pupd;
   end set_pupd;


   procedure set_bsr_r
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      bsr_r    : in  types.bit)
      with
         refined_global => (output => (GPIOA, GPIOB, GPIOC,
                                       GPIOD, GPIOE, GPIOF,
                                       GPIOG, GPIOH, GPIOI))
   is
      gpio_port : constant t_GPIO_port_access := get_port_access (port);
   begin
      gpio_port.all.BSRR.BR(pin) := bsr_r;
   end set_bsr_r;


   procedure set_bsr_s
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      bsr_s    : in  types.bit)
      with
         refined_global => (output => (GPIOA, GPIOB, GPIOC,
                                       GPIOD, GPIOE, GPIOF,
                                       GPIOG, GPIOH, GPIOI))
   is
      gpio_port : constant t_GPIO_port_access := get_port_access (port);
   begin
      gpio_port.all.BSRR.BS(pin) := bsr_s;
   end set_bsr_s;


   procedure set_lck
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      lck      : in  t_pin_lock)
      with
         refined_global => (output => (GPIOA, GPIOB, GPIOC,
                                       GPIOD, GPIOE, GPIOF,
                                       GPIOG, GPIOH, GPIOI))
   is
      gpio_port : constant t_GPIO_port_access := get_port_access (port);
   begin
      gpio_port.all.LCKR.pin(pin)  := lck;
   end set_lck;


   procedure set_af
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      af       : in  t_pin_alt_func)
      with
         refined_global => (output => (GPIOA, GPIOB, GPIOC,
                                       GPIOD, GPIOE, GPIOF,
                                       GPIOG, GPIOH, GPIOI))
   is
      gpio_port : constant t_GPIO_port_access := get_port_access (port);
   begin
      if pin < 8 then
         gpio_port.all.AFRL.pin(pin)  := af;
      else
         gpio_port.all.AFRH.pin(pin)  := af;
      end if;
   end set_af;


   procedure write_pin
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      value    : in  bit)
      with
         refined_global => (output => (GPIOA, GPIOB, GPIOC,
                                       GPIOD, GPIOE, GPIOF,
                                       GPIOG, GPIOH, GPIOI))
   is
      gpio_port : constant t_GPIO_port_access := get_port_access (port);
   begin
      gpio_port.all.ODR.pin (pin) := value;
   end write_pin;


   procedure read_pin
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      value    : out bit)
      with
         refined_global => (output => (GPIOA, GPIOB, GPIOC,
                                       GPIOD, GPIOE, GPIOF,
                                       GPIOG, GPIOH, GPIOI))
   is
      gpio_port : constant t_GPIO_port_access := get_port_access (port);
   begin
      value := gpio_port.all.IDR.pin (pin);
   end read_pin;

end soc.gpio;
