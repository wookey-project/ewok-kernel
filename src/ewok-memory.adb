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

with ewok.devices_shared;  use ewok.devices_shared;
with ewok.tasks;           use type ewok.tasks.t_task_type;
with ewok.devices;
with ewok.layout;
with ewok.mpu;
with ewok.mpu.allocator;
with ewok.debug;
with config;
with config.memlayout; use config.memlayout;
with m4.mpu;

package body ewok.memory
   with spark_mode => off
is

   procedure init
     (success : out boolean)
   is
   begin
      ewok.mpu.init (success);
   end init;


   procedure map_code_and_data
     (id    : in  t_real_task_id)
   is
      flash_mask  : m4.mpu.t_subregion_mask :=
                       (others => m4.mpu.SUB_REGION_DISABLED);
      ram_mask    : m4.mpu.t_subregion_mask :=
                       (others => m4.mpu.SUB_REGION_DISABLED);
   begin

      for i in 0 .. config.memlayout.list(id).flash_slot_number - 1 loop
         flash_mask(config.memlayout.list(id).flash_slot_start + i) :=
            m4.mpu.SUB_REGION_ENABLED;
      end loop;

      for i in 0 .. config.memlayout.list(id).ram_slot_number - 1 loop
         ram_mask(config.memlayout.list(id).ram_slot_start + i) :=
            m4.mpu.SUB_REGION_ENABLED;
      end loop;

      ewok.mpu.update_subregions
        (region_number  => ewok.mpu.USER_CODE_REGION,
         subregion_mask => flash_mask);

      ewok.mpu.update_subregions
        (region_number  => ewok.mpu.USER_DATA_REGION,
         subregion_mask => ram_mask);

   end map_code_and_data;


   procedure unmap_user_code_and_data
   is
   begin
      ewok.mpu.update_subregions
        (region_number  => ewok.mpu.USER_CODE_REGION,
         subregion_mask => (others => m4.mpu.SUB_REGION_DISABLED));

      ewok.mpu.update_subregions
        (region_number  => ewok.mpu.USER_DATA_REGION,
         subregion_mask => (others => m4.mpu.SUB_REGION_DISABLED));
   end unmap_user_code_and_data;


   procedure map_device
     (dev_id   : in  ewok.devices_shared.t_registered_device_id;
      success  : out boolean)
   is
      region_type : ewok.mpu.t_region_type;
   begin

      if ewok.devices.is_device_region_ro (dev_id) then
         region_type := ewok.mpu.REGION_TYPE_USER_DEV_RO;
      else
         region_type := ewok.mpu.REGION_TYPE_USER_DEV;
      end if;

      ewok.mpu.allocator.map_in_pool
        (addr           => ewok.devices.get_device_addr (dev_id),
         size           => ewok.devices.get_device_size (dev_id),
         region_type    => region_type,
         subregion_mask => ewok.devices.get_device_subregions_mask (dev_id),
         success        => success);

      if not success then
         pragma DEBUG
           (debug.log ("mpu_mapping_device(): can not be mapped"));
      end if;

   end map_device;


   procedure unmap_device
     (dev_id   : in  ewok.devices_shared.t_registered_device_id)
   is
   begin
      ewok.mpu.allocator.unmap_from_pool
        (ewok.devices.get_device_addr (dev_id));
   end unmap_device;


   procedure unmap_all_devices
   is
   begin
      ewok.mpu.allocator.unmap_all_from_pool;
   end unmap_all_devices;


   function device_can_be_mapped return boolean
   is
   begin
      return ewok.mpu.allocator.free_region_exist;
   end device_can_be_mapped;


   procedure map_task
     (id : in t_task_id)
   is
      new_task : ewok.tasks.t_task renames ewok.tasks.tasks_list(id);
      dev_id   : t_device_id;
      ok       : boolean;
   begin

      -- Release previously dynamically allocated regions (used for mapping
      -- devices and ISR stack)
      unmap_all_devices;

      -- Kernel tasks have no access to user regions
      if new_task.ttype = ewok.tasks.TASK_TYPE_KERNEL then
         unmap_user_code_and_data;
         return;
      end if;

      -- Mapping ISR device and ISR stack
      if new_task.mode = TASK_MODE_ISRTHREAD then

         -- Mapping the ISR stack
         ewok.mpu.allocator.map_in_pool
           (addr           => ewok.layout.STACK_BOTTOM_TASK_ISR,
            size           => 4096,
            region_type    => ewok.mpu.REGION_TYPE_ISR_STACK,
            subregion_mask => (others => m4.mpu.SUB_REGION_ENABLED),
            success        => ok);

         if not ok then
            debug.panic ("mpu_isr(): mapping ISR stack failed!");
         end if;

         -- Mapping the ISR device
         dev_id := new_task.isr_ctx.device_id;

         if dev_id /= ID_DEV_UNUSED then

            if ewok.devices.registered_device(dev_id).periph_id
                  = soc.devmap.NO_PERIPH
            then
               raise program_error;
            end if;

            map_device (dev_id, ok);
            if not ok then
               debug.panic ("mpu_switching(): mapping device failed!");
            end if;
         end if;

      -- Mapping main thread devices
      else

         -- Note:
         --  - EXTIs are a special case where an interrupt can trigger a
         --    user ISR without any device_id associated
         --  - DMAs are not registered in devices

         for i in new_task.devices'range loop
            if new_task.devices(i).device_id /= ID_DEV_UNUSED and then
               new_task.devices(i).mounted = true
            then

               if ewok.devices.registered_device(new_task.devices(i).device_id).periph_id
                     = soc.devmap.NO_PERIPH
               then
                  raise program_error;
               end if;

               map_device (new_task.devices(i).device_id, ok);
               if not ok then
                  debug.panic ("mpu_switching(): mapping device failed!");
               end if;
            end if;
         end loop;

      end if; -- ISR or MAIN thread

      map_code_and_data (id);

   end map_task;


end ewok.memory;
