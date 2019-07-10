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


with ewok.layout; use ewok.layout;
with ewok.tasks;  use ewok.tasks;
with ewok.devices_shared; use ewok.devices_shared;
with ewok.devices;
with ewok.exported.dma; use type ewok.exported.dma.t_dma_shm_access;

package body ewok.sanitize
   with spark_mode => on
is

   function is_word_in_data_slot
     (ptr      : system_address;
      task_id  : ewok.tasks_shared.t_task_id;
      mode     : ewok.tasks_shared.t_task_mode)
      return boolean
      with spark_mode => off
   is
      user_task : ewok.tasks.t_task renames ewok.tasks.tasks_list(task_id);
   begin

      if ptr >= user_task.data_slot_start   and
         ptr + 4 <= user_task.data_slot_end
      then
         return true;
      end if;

      -- ISR mode is a special case because the stack is therefore
      -- mutualized (thus only one ISR can be executed at the same time)
      if mode = TASK_MODE_ISRTHREAD    and
         ptr >= STACK_BOTTOM_TASK_ISR  and
         ptr <  STACK_TOP_TASK_ISR
      then
         return true;
      end if;

      return false;
   end is_word_in_data_slot;


   function is_word_in_txt_slot
     (ptr      : system_address;
      task_id  : ewok.tasks_shared.t_task_id)
      return boolean
      with spark_mode => off
   is
      user_task : ewok.tasks.t_task renames ewok.tasks.tasks_list(task_id);
   begin
      if ptr >= user_task.txt_slot_start     and
         ptr + 4 <= user_task.txt_slot_end
      then
         return true;
      else
         return false;
      end if;
   end is_word_in_txt_slot;


   function is_word_in_allocated_device
     (ptr      : system_address;
      task_id  : ewok.tasks_shared.t_task_id)
      return boolean
      with spark_mode => off
   is
      dev_id      : ewok.devices_shared.t_device_id;
      dev_size    : unsigned_32;
      dev_addr    : system_address;
      user_task   : ewok.tasks.t_task renames ewok.tasks.tasks_list(task_id);
   begin

      for i in user_task.devices'range loop
         dev_id   := user_task.devices(i).device_id;
         if dev_id /= ID_DEV_UNUSED then
            dev_addr := ewok.devices.get_device_addr (dev_id);
            dev_size := ewok.devices.get_device_size (dev_id);
            if ptr >= dev_addr         and
               ptr + 4 >= dev_addr     and
               ptr + 4 < dev_addr + dev_size
            then
               return true;
            end if;
         end if;
      end loop;

      return false;
   end is_word_in_allocated_device;


   function is_word_in_any_slot
     (ptr      : system_address;
      task_id  : ewok.tasks_shared.t_task_id;
      mode     : ewok.tasks_shared.t_task_mode)
      return boolean
      with spark_mode => off
   is
   begin
      return
         is_word_in_data_slot (ptr, task_id, mode) or
         is_word_in_txt_slot (ptr, task_id);
   end is_word_in_any_slot;


   function is_range_in_devices_slot
     (ptr      : system_address;
      size     : unsigned_32;
      task_id  : ewok.tasks_shared.t_task_id)
      return boolean
      with spark_mode => off
   is
      user_device_size : unsigned_32;
      user_device_addr : unsigned_32;
      dev_id           : t_device_id;
      user_task : ewok.tasks.t_task renames ewok.tasks.tasks_list(task_id);
   begin

      for i in user_task.devices'range loop
         dev_id   := user_task.devices(i).device_id;
         if dev_id /= ID_DEV_UNUSED then
            user_device_size := ewok.devices.get_device_size (dev_id);
            user_device_addr := ewok.devices.get_device_addr (dev_id);
            if ptr >= user_device_addr                            and
               ptr + size <= user_device_addr + user_device_size
            then
               return true;
            end if;
         end if;
      end loop;

      return false;
   end is_range_in_devices_slot;



   function is_range_in_data_slot
     (ptr      : system_address;
      size     : unsigned_32;
      task_id  : ewok.tasks_shared.t_task_id;
      mode     : ewok.tasks_shared.t_task_mode)
      return boolean
      with spark_mode => off
   is
      user_task : ewok.tasks.t_task renames ewok.tasks.tasks_list(task_id);
   begin

      if ptr >= user_task.data_slot_start       and
         ptr + size >= ptr                            and
         ptr + size <= user_task.data_slot_end
      then
         return true;
      end if;

      if mode = TASK_MODE_ISRTHREAD    and
         ptr >= STACK_BOTTOM_TASK_ISR  and
         ptr + size >= ptr             and
         ptr + size < STACK_TOP_TASK_ISR
      then
         return true;
      end if;

      return false;
   end is_range_in_data_slot;


   function is_range_in_txt_slot
     (ptr      : system_address;
      size     : unsigned_32;
      task_id  : ewok.tasks_shared.t_task_id)
      return boolean
      with spark_mode => off
   is
      user_task : ewok.tasks.t_task renames ewok.tasks.tasks_list(task_id);
   begin
      if ptr >= user_task.txt_slot_start        and
         ptr + size >= ptr                      and
         ptr + size <= user_task.txt_slot_end
      then
         return true;
      else
         return false;
      end if;
   end is_range_in_txt_slot;


   function is_range_in_any_slot
     (ptr      : system_address;
      size     : unsigned_32;
      task_id  : ewok.tasks_shared.t_task_id;
      mode     : ewok.tasks_shared.t_task_mode)
      return boolean
      with spark_mode => off
   is
   begin
      return
         is_range_in_data_slot (ptr, size, task_id, mode) or
         is_range_in_txt_slot (ptr, size, task_id);
   end is_range_in_any_slot;


   function is_range_in_dma_shm
     (ptr         : system_address;
      size        : unsigned_32;
      dma_access  : ewok.exported.dma.t_dma_shm_access;
      task_id     : ewok.tasks_shared.t_task_id)
      return boolean
      with spark_mode => off
   is
      user_task : ewok.tasks.t_task renames ewok.tasks.tasks_list(task_id);
   begin

      for i in 1 .. user_task.num_dma_shms loop

         if user_task.dma_shm(i).access_type = dma_access   and
            ptr >= user_task.dma_shm(i).base                and
            ptr + size >= ptr                               and
            ptr + size <= (user_task.dma_shm(i).base +
                           user_task.dma_shm(i).size)
         then
            return true;
         end if;

      end loop;

      return false;
   end is_range_in_dma_shm;


end ewok.sanitize;
