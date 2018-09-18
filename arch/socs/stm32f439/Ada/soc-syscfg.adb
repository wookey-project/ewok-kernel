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


package body soc.syscfg
   with spark_mode => off
is


   function get_exti_port
     (pin : soc.gpio.t_gpio_pin_index)
      return soc.gpio.t_gpio_port_index
   is
   begin

      case pin is
         when 0 .. 3    =>
            return SYSCFG.EXTICR1.exti(pin);
         when 4 .. 7    =>
            return SYSCFG.EXTICR2.exti(pin);
         when 8 .. 11   =>
            return SYSCFG.EXTICR3.exti(pin);
         when 12 .. 15  =>
            return SYSCFG.EXTICR4.exti(pin);
      end case;

   end get_exti_port;


   procedure set_exti_port
     (pin   : in soc.gpio.t_gpio_pin_index;
      port  : in soc.gpio.t_gpio_port_index)
   is
   begin
      case pin is
         when 0 .. 3    =>
            SYSCFG.EXTICR1.exti(pin) := port;
         when 4 .. 7    =>
            SYSCFG.EXTICR2.exti(pin) := port;
         when 8 .. 11   =>
            SYSCFG.EXTICR3.exti(pin) := port;
         when 12 .. 15  =>
            SYSCFG.EXTICR4.exti(pin) := port;
      end case;
   end set_exti_port;

end soc.syscfg;
