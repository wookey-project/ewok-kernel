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


with ewok.tasks_shared; use ewok.tasks_shared;
with ewok.devices_shared;
with config.applications; use config.applications; -- generated

package ewok.memory
   with spark_mode => on
is

   -- Initialize the memory backend
   procedure init
     (success : out boolean);

   -- Map task's code and data sections
   procedure map_code_and_data
     (id : in  t_real_task_id)
      with inline;

   -- Unmap the overall userspace content
   procedure unmap_user_code_and_data
      with inline;

   -- Return true if there is enough space in memory
   -- to map another element to the currently scheduled task
   function device_can_be_mapped return boolean
      with inline;

   -- Map/unmap a device into memory
   procedure map_device
     (dev_id   : in  ewok.devices_shared.t_registered_device_id;
      success  : out boolean)
      with inline;

   procedure unmap_device
     (dev_id   : in  ewok.devices_shared.t_registered_device_id)
      with inline;

   procedure unmap_all_devices
      with inline;

   -- Map the whole task (code, data and related devices) in memory
   procedure map_task (id : in t_task_id)
      with inline;

end ewok.memory;
