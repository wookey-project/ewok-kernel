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

with soc.gpio;

package ewok.exported.gpios
   with spark_mode => off
is

   type t_gpio_settings is record
      set_mode	   : bool;
      set_type	   : bool;
      set_speed	: bool;
      set_pupd	   : bool;
      set_bsr_r	: bool;
      set_bsr_s	: bool;
      set_lck	   : bool;
      set_af	   : bool;
      set_exti	   : bool;
   end record
      with size => 16;

   for t_gpio_settings use record
      set_mode	   at 0 range 0 .. 0;
      set_type	   at 0 range 1 .. 1;
      set_speed	at 0 range 2 .. 2;
      set_pupd	   at 0 range 3 .. 3;
      set_bsr_r	at 0 range 4 .. 4;
      set_bsr_s	at 0 range 5 .. 5;
      set_lck	   at 0 range 6 .. 6;
      set_af	   at 0 range 7 .. 7;
      set_exti	   at 0 range 8 .. 8;
   end record;

   type t_gpio_ref is record
      pin   : soc.gpio.t_gpio_pin_index;
      port  : soc.gpio.t_gpio_port_index;
   end record
      with pack, size => 8, convention => c_pass_by_copy;

   type t_interface_gpio_mode is (GPIO_IN, GPIO_OUT, GPIO_AF, GPIO_ANALOG);

   type t_interface_gpio_pupd is (GPIO_NOPULL, GPIO_PULLUP, GPIO_PULLDOWN);

   type t_interface_gpio_type is (GPIO_PUSH_PULL, GPIO_OPEN_DRAIN);

   type t_interface_gpio_speed is
     (GPIO_LOW_SPEED,
      GPIO_MEDIUM_SPEED,
      GPIO_HIGH_SPEED,
      GPIO_VERY_HIGH_SPEED);

   type t_interface_gpio_exti_trigger is
     (GPIO_EXTI_TRIGGER_NONE,
      GPIO_EXTI_TRIGGER_RISE,
      GPIO_EXTI_TRIGGER_FALL,
      GPIO_EXTI_TRIGGER_BOTH);

   type t_interface_gpio_exti_lock is
     (GPIO_EXTI_UNLOCKED,
      GPIO_EXTI_LOCKED);
   for t_interface_gpio_exti_lock use
      (GPIO_EXTI_UNLOCKED => 0,
       GPIO_EXTI_LOCKED   => 1);


   type t_gpio_config is record
      settings       : t_gpio_settings;  -- gpio_mask_t
      kref           : t_gpio_ref;
      mode           : t_interface_gpio_mode;
      pupd           : t_interface_gpio_pupd;
      otype          : t_interface_gpio_type;
      ospeed         : t_interface_gpio_speed;
      af             : unsigned_32;
      bsr_r          : unsigned_32;
      bsr_s          : unsigned_32;
      lck            : unsigned_32;
      exti_trigger   : t_interface_gpio_exti_trigger;
      exti_lock      : t_interface_gpio_exti_lock;
      exti_handler   : system_address;
   end record;

   type t_gpio_config_access is access all t_gpio_config;


end ewok.exported.gpios;
