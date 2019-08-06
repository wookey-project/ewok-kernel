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


with ada.unchecked_conversion;
with ewok.mpu;
with ewok.tasks; use ewok.tasks;
with ewok.debug;
with ewok.layout;
with ewok.devices; use ewok.devices;
with ewok.devices_shared; use ewok.devices_shared;

package body ewok.memory
   with spark_mode => off
is

   -----------------
   -- Local types --
   -----------------

   type t_mask is array (unsigned_8 range 1 .. 8) of bit
      with pack, size => 8;

   -----------------
   -- Local API   --
   -----------------

      
   function to_unsigned_8 is new ada.unchecked_conversion
      (t_mask, unsigned_8);


   procedure map_isr
      with inline
   is
      ok       : boolean;
   begin
      ewok.mpu.map
        (addr           => ewok.layout.STACK_BOTTOM_TASK_ISR,
         size           => 4096,
         region_type    => ewok.mpu.REGION_TYPE_ISR_STACK,
         subregion_mask => 0,
         success        => ok);

      if not ok then
         debug.panic ("mpu_switching(): mapping ISR stack failed!");
      end if;
   end map_isr;


   ------------------------
   -- Exported Functions --
   ------------------------

   -- Initialize the memory backend (MPU only by now)
   procedure init
     (success : out boolean)
   is
   begin
      ewok.mpu.init(success);
   end init;


   -- Map the given task id
   procedure map_task(id        : in  t_real_task_id)
   is
      new_task : t_task renames ewok.tasks.tasks_list(id);
      mask     : t_mask := (others => 1);
   begin
      for i in 0 .. new_task.num_slots - 1 loop
         mask(new_task.slot + i) := 0;
      end loop;

      ewok.mpu.update_subregions
         (region_number  => ewok.mpu.USER_CODE_REGION,
         subregion_mask => to_unsigned_8 (mask));

      ewok.mpu.update_subregions
         (region_number  => ewok.mpu.USER_DATA_REGION,
         subregion_mask => to_unsigned_8 (mask));

   end map_task;


   -- Unmap the currently scheduled task id
   procedure unmap_task
   is
      mask     : constant t_mask := (others => 1);
   begin

      ewok.mpu.update_subregions
         (region_number  => ewok.mpu.USER_CODE_REGION,
         subregion_mask => to_unsigned_8 (mask));

      ewok.mpu.update_subregions
         (region_number  => ewok.mpu.USER_DATA_REGION,
         subregion_mask => to_unsigned_8 (mask));

   end unmap_task;


   -- Map a given device into the task memory space
   procedure map_device
     (dev_id   : in  ewok.devices_shared.t_registered_device_id;
      success  : out boolean)
   is
      region_type       : ewok.mpu.t_region_type;
   begin

      if is_device_ro (dev_id) then
         region_type := ewok.mpu.REGION_TYPE_USER_DEV_RO;
      else
         region_type := ewok.mpu.REGION_TYPE_USER_DEV;
      end if;

      ewok.mpu.map
        (addr           => get_device_addr (dev_id),
         size           => get_device_size (dev_id),
         region_type    => region_type,
         subregion_mask => get_device_subregions_mask (dev_id),
         success        => success);

      if not success then
         pragma DEBUG
           (debug.log ("mpu_mapping_device(): can not be mapped"));
      end if;

   end map_device;


   -- Unmap a given device from the task memory space
   procedure unmap_device
     (dev_id   : in  ewok.devices_shared.t_registered_device_id)
   is
   begin
      ewok.mpu.unmap (get_device_addr (dev_id));
   end unmap_device;


   -- Unmap the overall userspace content
   procedure unmap_userspace
   is
   begin
      ewok.mpu.unmap_userspace;
   end unmap_userspace;


   -- Unmap the dynamic content from the currently scheduled task
   procedure unmap_dynamics
   is
   begin
      ewok.mpu.unmap_all;
   end unmap_dynamics;


   -- Return true if there is enough space in the memory backend
   -- to map another element to the currently scheduled task
   function can_be_mapped return boolean
   is
   begin
      return ewok.mpu.can_be_mapped;
   end can_be_mapped;

   
   -- Handle a memory backend switch, from one task to another
   procedure switch
     (id : in t_task_id)
   with spark_mode => off
   is
      new_task : t_task renames ewok.tasks.tasks_list(id);
      dev_id   : t_device_id;
      ok       : boolean;
   begin

      -- Release previously dynamically allocated regions (used for mapping
      -- devices and ISR stack)
      ewok.memory.unmap_dynamics;

      -- Kernel tasks have no access to user regions
      if new_task.ttype = TASK_TYPE_KERNEL then
         unmap_userspace;
         return;
      end if;

      --
      -- ISR mode
      --
      if new_task.mode = TASK_MODE_ISRTHREAD then

         -- Mapping the ISR stack
         map_isr;

         -- Mapping the ISR device
         dev_id   := new_task.isr_ctx.device_id;

         if dev_id /= ID_DEV_UNUSED then
            map_device (dev_id, ok);

            if not ok then
               debug.panic ("mpu_switching(): mapping device failed!");
            end if;
         end if;

      --
      -- Main thread
      --
      else

         -- Mapping the user devices
         --
         -- Design note:
         --  - EXTIs are a special case where an interrupt can trigger a
         --    user ISR without any device_id associated
         --  - DMAs are not registered in devices

         for i in new_task.devices'range loop
            if new_task.devices(i).device_id /= ID_DEV_UNUSED and then
               new_task.devices(i).mounted = true
            then
               map_device (new_task.devices(i).device_id, ok);
               if not ok then
                  debug.panic ("mpu_switching(): mapping device failed!");
               end if;
            end if;
         end loop;

      end if; -- ISR or MAIN thread

      --------------------------------
      -- Mapping user code and data --
      --------------------------------
      map_task(id);

   end switch;


end ewok.memory;
