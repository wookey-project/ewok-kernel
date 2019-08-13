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
   with spark_mode => on
is


   procedure get_exti_port
     (pin   : in  soc.gpio.t_gpio_pin_index;
      port  : out soc.gpio.t_gpio_port_index)
   is
   begin

      case pin is
         when 0 .. 3    =>
            port := SYSCFG.EXTICR1.exti(pin);
         when 4 .. 7    =>
            port := SYSCFG.EXTICR2.exti(pin);
         when 8 .. 11   =>
            port := SYSCFG.EXTICR3.exti(pin);
         when 12 .. 15  =>
            port := SYSCFG.EXTICR4.exti(pin);
      end case;

   end get_exti_port;


   procedure set_exti_port
     (pin   : in soc.gpio.t_gpio_pin_index;
      port  : in soc.gpio.t_gpio_port_index)
   is
   begin
      case pin is
         when 0 .. 3    => -- SYSCFG.EXTICR1.exti(pin) := port;
            declare
               exticr_list : t_exticr_list (0 .. 3) := SYSCFG.EXTICR1.exti;
            begin
               exticr_list(pin)     := port;
               SYSCFG.EXTICR1.exti  := exticr_list;
            end;
         when 4 .. 7    => -- SYSCFG.EXTICR2.exti(pin) := port;
            declare
               exticr_list : t_exticr_list (4 .. 7) := SYSCFG.EXTICR2.exti;
            begin
               exticr_list(pin)     := port;
               SYSCFG.EXTICR2.exti  := exticr_list;
            end;
         when 8 .. 11   => -- SYSCFG.EXTICR3.exti(pin) := port;
            declare
               exticr_list : t_exticr_list (8 .. 11) := SYSCFG.EXTICR3.exti;
            begin
               exticr_list(pin)     := port;
               SYSCFG.EXTICR3.exti  := exticr_list;
            end;
         when 12 .. 15  => -- SYSCFG.EXTICR4.exti(pin) := port;
            declare
               exticr_list : t_exticr_list (12 .. 15) := SYSCFG.EXTICR4.exti;
            begin
               exticr_list(pin)     := port;
               SYSCFG.EXTICR4.exti  := exticr_list;
            end;
      end case;
   end set_exti_port;

end soc.syscfg;
