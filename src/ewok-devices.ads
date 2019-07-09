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

with ewok.tasks_shared;    use ewok.tasks_shared;
with ewok.devices_shared;  use ewok.devices_shared;
with ewok.exported.devices;
with ewok.exported.interrupts;
with soc.interrupts;
with soc.devmap;

package ewok.devices
   with spark_mode => off
is

   type t_device_type is (DEV_TYPE_USER, DEV_TYPE_KERNEL);

   type t_device_state is -- FIXME
     (DEV_STATE_UNUSED,
      DEV_STATE_RESERVED,
      DEV_STATE_REGISTERED,
      DEV_STATE_ENABLED);

   type t_checked_user_device is new ewok.exported.devices.t_user_device;
   type t_checked_user_device_access is access all t_checked_user_device;

   type t_device is record
      udev        : aliased t_checked_user_device;
      task_id     : t_task_id                := ID_UNUSED;
      periph_id   : soc.devmap.t_periph_id   := soc.devmap.NO_PERIPH;
      status      : t_device_state           := DEV_STATE_UNUSED;
   end record;

   registered_device : array (t_registered_device_id) of t_device;


   procedure get_registered_device_entry
     (dev_id   : out t_device_id;
      success  : out boolean);

   procedure release_registered_device_entry (dev_id : t_registered_device_id);

   function get_task_from_id(dev_id : t_registered_device_id)
      return t_task_id;

   function get_user_device (dev_id : t_registered_device_id)
      return t_checked_user_device_access;

   function get_device_size (dev_id : t_registered_device_id)
      return unsigned_32;

   function get_device_addr (dev_id : t_registered_device_id)
      return system_address;

   function is_device_region_ro (dev_id : t_registered_device_id)
      return boolean;

   function get_device_subregions_mask (dev_id : t_registered_device_id)
      return unsigned_8;

   function get_interrupt_config_from_interrupt
     (interrupt : soc.interrupts.t_interrupt)
      return ewok.exported.interrupts.t_interrupt_config_access;

   procedure register_device
     (task_id  : in  t_task_id;
      udev     : in  ewok.exported.devices.t_user_device_access;
      dev_id   : out t_device_id;
      success  : out boolean);

   procedure release_device
     (task_id  : in  t_task_id;
      dev_id   : in  t_registered_device_id;
      success  : out boolean);

   procedure enable_device
     (dev_id   : in  t_registered_device_id;
      success  : out boolean);

   function sanitize_user_defined_device
     (udev     : in  ewok.exported.devices.t_user_device_access;
      task_id  : in  t_task_id)
      return boolean;

   procedure map_device
     (dev_id   : in  t_registered_device_id;
      success  : out boolean);

   procedure unmap_device
     (dev_id   : in  t_registered_device_id);

end ewok.devices;
