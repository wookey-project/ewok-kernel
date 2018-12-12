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

with ewok.tasks;              use ewok.tasks;
with ewok.tasks_shared;       use ewok.tasks_shared;
with ewok.exported.devices;   use ewok.exported.devices;
with ewok.devices_shared;     use ewok.devices_shared;
with ewok.devices;
with ewok.sched;

#if CONFIG_DEBUG_SYS_CFG_MEM
with debug;
#end if;

package body ewok.syscalls.cfg.mem
   with spark_mode => off
is

   package TSK renames ewok.tasks;


   procedure dev_map
     (caller_id   : in     ewok.tasks_shared.t_task_id;
      params      : in out t_parameters;
      mode        : in     ewok.tasks_shared.t_task_mode)
   is
      dev_descriptor : unsigned_8
         with address => params(1)'address;
      dev_id      : ewok.devices_shared.t_device_id;
      dev         : ewok.exported.devices.t_user_device_access;
      ok          : boolean;
   begin

      --
      -- Checking user inputs
      --

      -- Task must not be in ISR mode
      -- NOTE
      --    The reasons to forbid a task in ISR mode to map/unmap some devices
      --    are not technical. An ISR *must* be a minimal piece of code that
      --    manage only the interrupts provided by a specific hardware.
      if mode = ewok.tasks_shared.TASK_MODE_ISRTHREAD then
#if CONFIG_DEBUG_SYS_CFG_MEM
         debug.log (debug.WARNING, "[task"
           & ewok.tasks_shared.t_task_id'image (caller_id)
           & "] sys_cfg(CFG_DEV_MAP): forbidden in ISR mode");
#end if;
         goto ret_denied;
      end if;

      -- No map/unmap before end of initialization
      if not is_init_done (caller_id) then
#if CONFIG_DEBUG_SYS_CFG_MEM
         debug.log (debug.WARNING, "[task"
            & ewok.tasks_shared.t_task_id'image (caller_id)
            & "] sys_cfg(CFG_DEV_MAP): forbidden during init sequence");
#end if;
         goto ret_denied;
      end if;

      -- Valid device descriptor ?
      if dev_descriptor not in  TSK.tasks_list(caller_id).device_id'range
      then
#if CONFIG_DEBUG_SYS_CFG_MEM
         debug.log (debug.WARNING, "invalid device descriptor");
#end if;
         goto ret_inval;
      end if;

      dev_id   := TSK.tasks_list(caller_id).device_id (dev_descriptor);

      -- Used device descriptor ?
      if dev_id = ID_DEV_UNUSED then
#if CONFIG_DEBUG_SYS_CFG_MEM
         debug.log (debug.WARNING, "[task"
            & ewok.tasks_shared.t_task_id'image (caller_id)
            & "] sys_cfg(CFG_DEV_MAP): unused device");
#end if;
         goto ret_inval;
      end if;

      -- Verifying that the device really belongs to the task
      -- NOTE - Defensive programming
      -- FIXME - That test may be removed
      if ewok.devices.get_task_from_id (dev_id) /= caller_id then
         raise program_error;
      end if;

      -- Verifying that the device may be voluntary mapped by the task
      dev      := ewok.devices.get_user_device (dev_id);

      if dev.map_mode /= ewok.exported.devices.DEV_MAP_VOLUNTARY then
#if CONFIG_DEBUG_SYS_CFG_MEM
         debug.log (debug.WARNING, "[task"
            & ewok.tasks_shared.t_task_id'image (caller_id)
            & "] sys_cfg(CFG_DEV_MAP): not a DEV_MAP_VOLUNTARY device");
#end if;
         goto ret_denied;
      end if;

      -- Verifying that the device is not already mapped
      for i in TSK.tasks_list(caller_id).mounted_device'range loop
         if TSK.tasks_list(caller_id).mounted_device(i) = dev_id then
#if CONFIG_DEBUG_SYS_CFG_MEM
         debug.log (debug.WARNING, "[task"
            & ewok.tasks_shared.t_task_id'image (caller_id)
            & "] sys_cfg(CFG_DEV_MAP): the device is already mapped");
#end if;
            goto ret_denied;
         end if;
      end loop;

      -- Verifying that the device can be mapped
      declare
         empty_slot : boolean := false;
      begin
         look_empty_slot:
         for i in TSK.tasks_list(caller_id).mounted_device'range loop
            if TSK.tasks_list(caller_id).mounted_device(i) = ID_DEV_UNUSED then
               empty_slot := true;
               exit look_empty_slot;
            end if;
         end loop look_empty_slot;
         if not empty_slot then
#if CONFIG_DEBUG_SYS_CFG_MEM
            debug.log (debug.WARNING, "[task"
               & ewok.tasks_shared.t_task_id'image (caller_id)
               & "] sys_cfg(CFG_DEV_MAP): no free region left to map the device");
#end if;
            goto ret_busy;
         end if;
      end;

      --
      -- Adding the device in the 'mounted' list
      --

      for i in TSK.tasks_list(caller_id).mounted_device'range loop
         if TSK.tasks_list(caller_id).mounted_device(i) = ID_DEV_UNUSED then
            TSK.tasks_list(caller_id).mounted_device(i)  := dev_id;
            TSK.tasks_list(caller_id).num_devs_mounted   :=
               TSK.tasks_list(caller_id).num_devs_mounted + 1;
         end if;
      end loop;

      -- We enable the device if its not already enabled
      ewok.devices.enable_device (dev_id, ok);
      if not ok then
         goto ret_denied;
      end if;

      -- TODO - mapping the device in its related MPU region

      set_return_value (caller_id, mode, SYS_E_DONE);
      TSK.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      ewok.sched.request_schedule;
      return;

   <<ret_inval>>
      set_return_value (caller_id, mode, SYS_E_INVAL);
      TSK.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   <<ret_denied>>
      set_return_value (caller_id, mode, SYS_E_DENIED);
      TSK.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   <<ret_busy>>
      set_return_value (caller_id, mode, SYS_E_BUSY);
      TSK.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;
    end dev_map;


   procedure dev_unmap
     (caller_id   : in     ewok.tasks_shared.t_task_id;
      params      : in out t_parameters;
      mode        : in     ewok.tasks_shared.t_task_mode)
   is
      dev_descriptor : unsigned_8
         with address => params(1)'address;
      dev_id      : ewok.devices_shared.t_device_id;
      dev         : ewok.exported.devices.t_user_device_access;
   begin

      --
      -- Checking user inputs
      --

      -- Task must not be in ISR mode
      -- NOTE
      --    The reasons to forbid a task in ISR mode to map/unmap some devices
      --    are not technical. An ISR *must* be a minimal piece of code that
      --    manage only the interrupts provided by a specific hardware.
      if mode = ewok.tasks_shared.TASK_MODE_ISRTHREAD then
#if CONFIG_DEBUG_SYS_CFG_MEM
         debug.log (debug.WARNING, "[task"
           & ewok.tasks_shared.t_task_id'image (caller_id)
           & "] sys_cfg(CFG_DEV_MAP): forbidden in ISR mode");
#end if;
         goto ret_denied;
      end if;

      -- No map/unmap before end of initialization
      if not is_init_done (caller_id) then
#if CONFIG_DEBUG_SYS_CFG_MEM
         debug.log (debug.WARNING, "[task"
            & ewok.tasks_shared.t_task_id'image (caller_id)
            & "] sys_cfg(CFG_DEV_MAP): forbidden during init sequence");
#end if;
         goto ret_denied;
      end if;

      -- Valid device descriptor ?
      if dev_descriptor not in  TSK.tasks_list(caller_id).device_id'range
      then
#if CONFIG_DEBUG_SYS_CFG_MEM
         debug.log (debug.WARNING, "invalid device descriptor");
#end if;
         goto ret_inval;
      end if;

      dev_id   := TSK.tasks_list(caller_id).device_id (dev_descriptor);

      -- Used device descriptor ?
      if dev_id = ID_DEV_UNUSED then
#if CONFIG_DEBUG_SYS_CFG_MEM
         debug.log (debug.WARNING, "[task"
            & ewok.tasks_shared.t_task_id'image (caller_id)
            & "] sys_cfg(CFG_DEV_MAP): unused device");
#end if;
         goto ret_inval;
      end if;

      -- Verifying that the device really belongs to the task
      -- NOTE - Defensive programming.
      -- FIXME - That test may be removed
      if ewok.devices.get_task_from_id (dev_id) /= caller_id then
         raise program_error;
      end if;

      -- Verifying that the device may be voluntary unmapped by the task
      dev      := ewok.devices.get_user_device (dev_id);

      if dev.map_mode /= ewok.exported.devices.DEV_MAP_VOLUNTARY then
#if CONFIG_DEBUG_SYS_CFG_MEM
         debug.log (debug.WARNING, "[task"
            & ewok.tasks_shared.t_task_id'image (caller_id)
            & "] sys_cfg(CFG_DEV_MAP): not a DEV_MAP_VOLUNTARY device");
#end if;
         goto ret_denied;
      end if;

      -- Verifying that the device is already mapped
      declare
         found : boolean := false;
      begin
         for i in TSK.tasks_list(caller_id).mounted_device'range loop
            if TSK.tasks_list(caller_id).mounted_device(i) = dev_id then
               found := true;
               exit;
            end if;
         end loop;
         if not found then
#if CONFIG_DEBUG_SYS_CFG_MEM
         debug.log (debug.WARNING, "[task"
            & ewok.tasks_shared.t_task_id'image (caller_id)
            & "] sys_cfg(CFG_DEV_MAP): the device is not mapped"
#end if;
            goto ret_denied;
         end if;
      end;

      --
      -- Removing the device from the 'mounted' list
      --

      for i in TSK.tasks_list(caller_id).mounted_device'range loop
         if TSK.tasks_list(caller_id).mounted_device(i) = dev_id then
            TSK.tasks_list(caller_id).mounted_device(i) := ID_DEV_UNUSED;
         end if;
      end loop;

      -- TODO - unmapping the device from its related MPU region

      set_return_value (caller_id, mode, SYS_E_DONE);
      TSK.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      ewok.sched.request_schedule;
      return;

   <<ret_inval>>
      set_return_value (caller_id, mode, SYS_E_INVAL);
      TSK.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   <<ret_denied>>
      set_return_value (caller_id, mode, SYS_E_DENIED);
      TSK.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   end dev_unmap;

end ewok.syscalls.cfg.mem;
