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

with soc.exti;             use soc.exti;
with soc.nvic;
with soc.syscfg;
with soc.gpio;
with ewok.exported.gpios;   use ewok.exported.gpios;
with ewok.exti.handler;

package body ewok.exti
   with spark_mode => off
is

   procedure init
   is
   begin
      ewok.exti.handler.init;
      soc.exti.init;
   end init;


   procedure enable
     (ref : in  ewok.exported.gpios.t_gpio_ref)
   is
      line : soc.exti.t_exti_line_index;
   begin

      line := soc.exti.t_exti_line_index'val
        (soc.gpio.t_gpio_pin_index'pos (ref.pin));

      soc.exti.enable (line);

      case ref.pin is
         when 0         => soc.nvic.enable_irq (soc.nvic.EXTI_Line_0);
         when 1         => soc.nvic.enable_irq (soc.nvic.EXTI_Line_1);
         when 2         => soc.nvic.enable_irq (soc.nvic.EXTI_Line_2);
         when 3         => soc.nvic.enable_irq (soc.nvic.EXTI_Line_3);
         when 4         => soc.nvic.enable_irq (soc.nvic.EXTI_Line_4);
         when 5 .. 9    => soc.nvic.enable_irq (soc.nvic.EXTI_Line_5_9);
         when 10 .. 15  => soc.nvic.enable_irq (soc.nvic.EXTI_Line_10_15);
      end case;

   end enable;


   procedure disable
     (ref : in  ewok.exported.gpios.t_gpio_ref)
   is
      line : soc.exti.t_exti_line_index;
   begin
      line := soc.exti.t_exti_line_index'val
        (soc.gpio.t_gpio_pin_index'pos (ref.pin));
      soc.exti.disable (line);
   end disable;


   function is_used
     (ref : ewok.exported.gpios.t_gpio_ref)
      return boolean
   is
      line : constant soc.exti.t_exti_line_index :=
         soc.exti.t_exti_line_index'val
           (soc.gpio.t_gpio_pin_index'pos (ref.pin));
   begin
      return exti_line_registered (line) or
             soc.exti.is_enabled (line);
   end is_used;


   procedure register
     (conf     : in  ewok.exported.gpios.t_gpio_config_access;
      success  : out boolean)
   is
      line : constant soc.exti.t_exti_line_index :=
         soc.exti.t_exti_line_index'val
           (soc.gpio.t_gpio_pin_index'pos (conf.all.kref.pin));
   begin

      -- Is EXTI setting required?
      if not conf.all.settings.set_exti then
         success := true;
         return;
      end if;

      -- Is EXTI line already registered?
      if exti_line_registered (line) then
         success := false;
         return;
      end if;

      -- If the line is already set, thus it's already used.
      -- We return in error.
      if soc.exti.is_enabled (line) then
         success := false;
         return;
      end if;

      -- Configuring the triggers
      case conf.all.exti_trigger is
         when GPIO_EXTI_TRIGGER_NONE =>
            success := true;
            return;

         when GPIO_EXTI_TRIGGER_RISE =>
            soc.exti.EXTI.RTSR.line(line) := TRIGGER_ENABLED;

         when GPIO_EXTI_TRIGGER_FALL =>
            soc.exti.EXTI.FTSR.line(line) := TRIGGER_ENABLED;

         when GPIO_EXTI_TRIGGER_BOTH =>
            soc.exti.EXTI.RTSR.line(line) := TRIGGER_ENABLED;
            soc.exti.EXTI.FTSR.line(line) := TRIGGER_ENABLED;
      end case;

      -- Configuring the SYSCFG register
      soc.syscfg.set_exti_port (conf.all.kref.pin, conf.all.kref.port);

      exti_line_registered (line) := true;
      success := true;

   end register;


   procedure release
     (conf     : in  ewok.exported.gpios.t_gpio_config_access)
   is
      line : constant soc.exti.t_exti_line_index :=
         soc.exti.t_exti_line_index'val
           (soc.gpio.t_gpio_pin_index'pos (conf.all.kref.pin));
   begin

      if not conf.all.settings.set_exti then
         return;
      end if;

      if not exti_line_registered (line) then
         return;
      end if;

      if not soc.exti.is_enabled (line) then
         return;
      end if;

      if conf.all.exti_trigger = GPIO_EXTI_TRIGGER_NONE then
         return;
      end if;

      soc.exti.disable (line);

      exti_line_registered (line) := false;

   end release;


end ewok.exti;
