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


   procedure config
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      mode     : in  t_pin_mode;
      otype    : in  t_pin_output_type;
      ospeed   : in  t_pin_output_speed;
      pupd     : in  t_pin_pupd;
      af       : in  t_pin_alt_func)
   is
      gpio : soc.gpio.t_GPIO_port_access;
   begin

      -- Enable RCC
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

      gpio := soc.gpio.get_port_access (port);

      gpio.all.MODER.pin(pin)    := mode;
      gpio.all.OTYPER.pin(pin)   := otype;
      gpio.all.OSPEEDR.pin(pin)  := ospeed;
      gpio.all.PUPDR.pin(pin)    := pupd;

      if pin < 8 then
         gpio.all.AFRL.pin(pin)  := af;
      else
         gpio.all.AFRH.pin(pin)  := af;
      end if;

   end config;


end soc.gpio;
