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

with debug;
with ewok.exported.gpios; use ewok.exported.gpios;
with soc.gpio;           use type soc.gpio.t_GPIO_port_access;
                         use type soc.gpio.t_gpio_pin_index;
with soc.rcc;

package body ewok.gpio
   with spark_mode => off
is


   function to_pin_alt_func
     (u : unsigned_32) return soc.gpio.t_pin_alt_func
   is
      pragma warnings (off);
      function conv is new ada.unchecked_conversion
        (unsigned_32, soc.gpio.t_pin_alt_func);
      pragma warnings (on);
   begin
      if u > 15 then
         raise program_error;
      end if;
      return conv (u);
   end to_pin_alt_func;


   function is_used
     (ref : ewok.exported.gpios.t_gpio_ref)
      return boolean
   is
   begin
      return gpio_points(ref.port, ref.pin).used;
   end is_used;


   procedure register
     (task_id     : in  ewok.tasks_shared.t_task_id;
      device_id   : in  ewok.devices_shared.t_device_id;
      conf_a      : in  ewok.exported.gpios.t_gpio_config_access;
      success     : out boolean)
   is
      ref : constant ewok.exported.gpios.t_gpio_ref := conf_a.all.kref;
   begin
      if gpio_points(ref.port, ref.pin).used then
         debug.log (debug.WARNING, "Registering GPIO: port" &
            soc.gpio.t_gpio_port_index'image (ref.port) & ", pin" &
            soc.gpio.t_gpio_pin_index'image (ref.pin) & " is already used.");
         success := false;
      else
         gpio_points(ref.port, ref.pin).used       := true;
         gpio_points(ref.port, ref.pin).task_id    := task_id;
         gpio_points(ref.port, ref.pin).device_id  := device_id;
         gpio_points(ref.port, ref.pin).config     := conf_a;
         success := true;
      end if;
   end register;


   procedure config
     (conf     : in  ewok.exported.gpios.t_gpio_config_access)
   is
      gpio : soc.gpio.t_GPIO_port_access;
   begin

      -- Enable RCC
      case conf.all.kref.port is
         when soc.gpio.GPIO_PA => soc.rcc.RCC.AHB1.GPIOAEN := true;
         when soc.gpio.GPIO_PB => soc.rcc.RCC.AHB1.GPIOBEN := true;
         when soc.gpio.GPIO_PC => soc.rcc.RCC.AHB1.GPIOCEN := true;
         when soc.gpio.GPIO_PD => soc.rcc.RCC.AHB1.GPIODEN := true;
         when soc.gpio.GPIO_PE => soc.rcc.RCC.AHB1.GPIOEEN := true;
         when soc.gpio.GPIO_PF => soc.rcc.RCC.AHB1.GPIOFEN := true;
         when soc.gpio.GPIO_PG => soc.rcc.RCC.AHB1.GPIOGEN := true;
         when soc.gpio.GPIO_PH => soc.rcc.RCC.AHB1.GPIOHEN := true;
         when soc.gpio.GPIO_PI => soc.rcc.RCC.AHB1.GPIOIEN := true;
      end case;

      gpio := soc.gpio.get_port_access (conf.all.kref.port);

      if conf.all.settings.set_mode then
         gpio.all.MODER.pin (conf.all.kref.pin) :=
            soc.gpio.t_pin_mode'val
              (t_interface_gpio_mode'pos (conf.all.mode));
      end if;

      if conf.all.settings.set_type then
         gpio.all.OTYPER.pin (conf.all.kref.pin) :=
            soc.gpio.t_pin_output_type'val
              (t_interface_gpio_type'pos (conf.all.otype));
      end if;

      if conf.all.settings.set_speed then
         gpio.all.OSPEEDR.pin (conf.all.kref.pin) :=
            soc.gpio.t_pin_output_speed'val
              (t_interface_gpio_speed'pos (conf.all.ospeed));
      end if;

      if conf.all.settings.set_pupd then
         gpio.all.PUPDR.pin (conf.all.kref.pin) :=
            soc.gpio.t_pin_pupd'val
              (t_interface_gpio_pupd'pos (conf.all.pupd));
      end if;

      if conf.all.settings.set_bsr_r then
         gpio.all.BSRR.BR (conf.all.kref.pin) := types.to_bit (conf.all.bsr_r);
      end if;

      if conf.all.settings.set_bsr_s then
         gpio.all.BSRR.BS (conf.all.kref.pin) := types.to_bit (conf.all.bsr_s);
      end if;

      -- FIXME - Writing to LCKR register requires a specific sequence
      --         describe in section 8.4.8 (RM 00090)
      if conf.all.settings.set_lck then
         gpio.all.LCKR.pin (conf.all.kref.pin) :=
            soc.gpio.t_pin_lock'val (conf.all.lck);
      end if;

      if conf.all.settings.set_af then
         if conf.all.kref.pin < 8 then
            gpio.all.AFRL.pin (conf.all.kref.pin) :=
               to_pin_alt_func (conf.all.af);
         else
            gpio.all.AFRH.pin (conf.all.kref.pin) :=
               to_pin_alt_func (conf.all.af);
         end if;
      end if;

   end config;


   procedure write_pin
     (ref      : in  ewok.exported.gpios.t_gpio_ref;
      value    : in  bit)
   is
      port : soc.gpio.t_GPIO_port_access;
   begin
      port := soc.gpio.get_port_access (ref.port);
      port.all.ODR.pin (ref.pin) := value;
   end write_pin;


   function read_pin
     (ref      : ewok.exported.gpios.t_gpio_ref)
      return bit
   is
      port : soc.gpio.t_GPIO_port_access;
   begin
      port := soc.gpio.get_port_access (ref.port);
      return port.all.IDR.pin (ref.pin);
   end read_pin;


   function belong_to
     (task_id     : ewok.tasks_shared.t_task_id;
      ref         : ewok.exported.gpios.t_gpio_ref)
      return boolean
   is
   begin
      if gpio_points(ref.port, ref.pin).used and
         gpio_points(ref.port, ref.pin).task_id = task_id
      then
         return true;
      else
         return false;
      end if;
   end belong_to;


   function get_task_id
     (ref      : in  ewok.exported.gpios.t_gpio_ref)
      return ewok.tasks_shared.t_task_id
   is
   begin
      return gpio_points(ref.port, ref.pin).task_id;
   end get_task_id;


   function get_device_id
     (ref      : in  ewok.exported.gpios.t_gpio_ref)
      return ewok.devices_shared.t_device_id
   is
   begin
      return gpio_points(ref.port, ref.pin).device_id;
   end get_device_id;


   function get_config
     (ref      : in  ewok.exported.gpios.t_gpio_ref)
      return ewok.exported.gpios.t_gpio_config_access
   is
   begin
      return gpio_points(ref.port, ref.pin).config;
   end get_config;

end ewok.gpio;
