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
with applications; use applications; -- generated

package ewok.memory
   with spark_mode => off
is

   ---------------
   -- Functions --
   ---------------

   -- Initialize the memory backend (MPU only by now)
   procedure init
     (success : out boolean);


   -- map the given task id. This function map the data and code sections
   -- of the given task id, including:
   --   the task flash content
   --   the task RAM content (stack, bss, heap...)
   --
   -- CAUTION:
   --    this function does NOT handle specific mapping or unmapping
   --    (memory devices or ISR map, etc.)
   --    this function does not handle memory space swith neither
   --    See belowing API for theses actions.
   -- 
   procedure map_task(id        : in  t_real_task_id);
   pragma Inline (map_task);

   -- unmap the currently scheduled task id. This is a basic implementation
   -- no more userspace task is mapped.
   -- This function unmap the data and code sections of the given task id,
   -- including:
   --   the task flash content
   --   the task RAM content (stack, bss, heap...)
   --
   -- CAUTION: this function does NOT handle specific mapping or unmapping
   -- (memory devices or ISR map, etc.)
   -- See belowing API for theses actions.
   procedure unmap_task;
   pragma Inline (unmap_task);


   -- Map a given device into the task memory space
   procedure map_device
     (dev_id   : in  ewok.devices_shared.t_registered_device_id;
      success  : out boolean);
   pragma Inline (map_device);


   -- Unmap the currently scheduled task id
   procedure unmap_device
     (dev_id   : in  ewok.devices_shared.t_registered_device_id);
   pragma Inline (unmap_device);


   -- Unmap the overall userspace content
   procedure unmap_userspace;
   pragma Inline (unmap_userspace);


   -- Unmap the dynamic content from the currently scheduled task
   -- This include:
   --   - IOMapped device(s)
   --   - ISR stack
   procedure unmap_dynamics;
   pragma Inline (unmap_dynamics);


   -- Return true if there is enough space in the memory backend
   -- to map another element to the currently scheduled task
   function can_be_mapped return boolean;
   pragma Inline (can_be_mapped);


   -- Handle a memory backend switch, from one task to another.
   -- This function handle the following:
   --   - Unmapping the previously mapped task
   --   - Map the newly elected task
   --   - In the case of ISR mode, map the ISR stack and the
   --     associated device
   --   - In standard thread mode, map the task's devices
   procedure switch
     (id : in t_task_id);
   pragma Inline (switch);

end ewok.memory;
