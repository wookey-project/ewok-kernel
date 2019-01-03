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

with types.c;
with ewok.exported.interrupts;
with ewok.exported.gpios;

package ewok.exported.devices
   with spark_mode => off
is

   MAX_INTERRUPTS    : constant := 4;
   MAX_GPIOS         : constant := 16;

   subtype t_device_name is types.c.c_string (1 .. 16);
   type t_device_name_access is access all t_device_name;

   type t_interrupt_config_array is
      array (unsigned_8 range <>) of
         aliased ewok.exported.interrupts.t_interrupt_config;

   type t_gpio_config_array is
      array (unsigned_8 range <>) of
         aliased ewok.exported.gpios.t_gpio_config;

   type t_dev_map_mode is
      (DEV_MAP_AUTO,
       DEV_MAP_VOLUNTARY);

   type t_user_device is record
      name           : t_device_name;
      base_addr      : system_address;
      size           : unsigned_32;
      interrupt_num  : unsigned_8 range 0 .. MAX_INTERRUPTS;
      gpio_num       : unsigned_8 range 0 .. MAX_GPIOS;
      map_mode       : t_dev_map_mode;
      interrupts     : t_interrupt_config_array (1 .. MAX_INTERRUPTS);
      gpios          : t_gpio_config_array (1 .. MAX_GPIOS);
   end record;

   type t_user_device_access is access all t_user_device;

end ewok.exported.devices;
