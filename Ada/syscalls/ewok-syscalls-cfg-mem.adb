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

      -- Valid device descriptor ?

      if dev_descriptor < ewok.tasks.tasks_list(caller_id).device_id'first or
         dev_descriptor > ewok.tasks.tasks_list(caller_id).num_devs
      then
#if CONFIG_DEBUG_SYS_CFG_MEM
         debug.log (debug.WARNING, "invalid device descriptor");
#end if;
         goto ret_inval;
      end if;

      dev_id   := ewok.tasks.tasks_list(caller_id).device_id (dev_descriptor);
      dev      := ewok.devices.get_user_device (dev_id);

      --
      -- Checking user inputs
      --

      if mode = ewok.tasks_shared.TASK_MODE_ISRTHREAD then
#if CONFIG_DEBUG_SYS_CFG_MEM
         debug.log (debug.WARNING, "[task"
           & ewok.tasks_shared.t_task_id'image (caller_id)
           & "] sys_cfg(CFG_DEV_MAP): forbidden in ISR mode");
#end if;
         goto ret_denied;
      end if;

      if not is_init_done (caller_id) then
#if CONFIG_DEBUG_SYS_CFG_MEM
         debug.log (debug.WARNING, "[task"
            & ewok.tasks_shared.t_task_id'image (caller_id)
            & "] sys_cfg(CFG_DEV_MAP): forbidden during init sequence");
#end if;
         goto ret_denied;
      end if;

      if dev_id = ID_DEV_UNUSED then
#if CONFIG_DEBUG_SYS_CFG_MEM
         debug.log (debug.WARNING, "[task"
            & ewok.tasks_shared.t_task_id'image (caller_id)
            & "] sys_cfg(CFG_DEV_MAP): unused device");
#end if;
         goto ret_inval;
      end if;

      if ewok.devices.get_task_from_id (dev_id) /= caller_id then
#if CONFIG_DEBUG_SYS_CFG_MEM
         debug.log (debug.WARNING, "[task"
            & ewok.tasks_shared.t_task_id'image (caller_id)
            & "] sys_cfg(CFG_DEV_MAP): device not owned by the task");
#end if;
         goto ret_inval;
      end if;

      if dev.map_mode /= ewok.exported.devices.DEV_MAP_VOLUNTARY then
#if CONFIG_DEBUG_SYS_CFG_MEM
         debug.log (debug.WARNING, "[task"
            & ewok.tasks_shared.t_task_id'image (caller_id)
            & "] sys_cfg(CFG_DEV_MAP): not a DEV_MAP_VOLUNTARY device");
#end if;
         goto ret_denied;
      end if;

      --
      -- End of checks, let's do the mapping
      --

      if ewok.devices.is_mapped (dev_id) then
#if CONFIG_DEBUG_SYS_CFG_MEM
         debug.log (debug.WARNING, "[task"
            & ewok.tasks_shared.t_task_id'image (caller_id)
            & "] sys_cfg(CFG_DEV_MAP): device already mapped");
#end if;
         goto ret_busy;
      end if;

      -- As this device is not mapped, it may need to be enable.
      -- We enable the device here (INFO: this may be not needed if
      -- this is not the first mapping of this device but this
      -- as no operational impact)
      ewok.devices.enable_device(dev_id, ok);
      if not ok then
         raise program_error;
      end if;

      ewok.devices.map_device (dev_id, ok);

      if not ok then
#if CONFIG_DEBUG_SYS_CFG_MEM
          debug.log (debug.WARNING, "[task"
             & ewok.tasks_shared.t_task_id'image (caller_id)
             & "] sys_cfg(CFG_DEV_MAP): unable to map device");
#end if;
          goto ret_busy;
       end if;

      set_return_value (caller_id, mode, SYS_E_DONE);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      ewok.sched.request_schedule;
      return;

   <<ret_inval>>
      set_return_value (caller_id, mode, SYS_E_INVAL);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   <<ret_denied>>
      set_return_value (caller_id, mode, SYS_E_DENIED);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   <<ret_busy>>
      set_return_value (caller_id, mode, SYS_E_BUSY);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
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
      ok          : boolean;
   begin

      -- Valid device descriptor ?
      if dev_descriptor < ewok.tasks.tasks_list(caller_id).device_id'first or
         dev_descriptor > ewok.tasks.tasks_list(caller_id).num_devs
      then
#if CONFIG_DEBUG_SYS_CFG_MEM
         debug.log (debug.WARNING, "invalid device descriptor");
#end if;
         goto ret_inval;
      end if;

      dev_id   := ewok.tasks.tasks_list(caller_id).device_id (dev_descriptor);
      dev      := ewok.devices.get_user_device (dev_id);

      --
      -- Checking user inputs
      --

      if mode = ewok.tasks_shared.TASK_MODE_ISRTHREAD then
#if CONFIG_DEBUG_SYS_CFG_MEM
         debug.log (debug.WARNING, "[task"
           & ewok.tasks_shared.t_task_id'image (caller_id)
           & "] sys_cfg(CFG_DEV_MAP): forbidden in ISR mode");
#end if;
         goto ret_denied;
      end if;

      if not is_init_done (caller_id) then
#if CONFIG_DEBUG_SYS_CFG_MEM
         debug.log (debug.WARNING, "[task"
            & ewok.tasks_shared.t_task_id'image (caller_id)
            & "] sys_cfg(CFG_DEV_MAP): forbidden during init sequence");
#end if;
         goto ret_denied;
      end if;

      if dev_id = ID_DEV_UNUSED then
#if CONFIG_DEBUG_SYS_CFG_MEM
         debug.log (debug.WARNING, "[task"
            & ewok.tasks_shared.t_task_id'image (caller_id)
            & "] sys_cfg(CFG_DEV_MAP): unused device");
#end if;
         goto ret_inval;
      end if;

      if ewok.devices.get_task_from_id (dev_id) /= caller_id then
#if CONFIG_DEBUG_SYS_CFG_MEM
         debug.log (debug.WARNING, "[task"
            & ewok.tasks_shared.t_task_id'image (caller_id)
            & "] sys_cfg(CFG_DEV_MAP): device not owned by the task");
#end if;
         goto ret_inval;
      end if;

      if dev.map_mode /= ewok.exported.devices.DEV_MAP_VOLUNTARY then
#if CONFIG_DEBUG_SYS_CFG_MEM
         debug.log (debug.WARNING, "[task"
            & ewok.tasks_shared.t_task_id'image (caller_id)
            & "] sys_cfg(CFG_DEV_MAP): not a DEV_MAP_VOLUNTARY device");
#end if;
         goto ret_denied;
      end if;

      --
      -- End of checks, unmapping the device
      --

      if not ewok.devices.is_mapped (dev_id) then
#if CONFIG_DEBUG_SYS_CFG_MEM
         debug.log (debug.WARNING, "[task"
            & ewok.tasks_shared.t_task_id'image (caller_id)
            & "] sys_cfg(CFG_DEV_MAP): device is not mapped");
#end if;
         goto ret_inval;
      end if;

      ewok.devices.unmap_device (dev_id, ok);

      if not ok then
#if CONFIG_DEBUG_SYS_CFG_MEM
         debug.log (debug.WARNING, "[task"
            & ewok.tasks_shared.t_task_id'image (caller_id)
            & "] sys_cfg(CFG_DEV_MAP): unable to unmap device");
#end if;
         goto ret_busy;
      end if;

      set_return_value (caller_id, mode, SYS_E_DONE);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      ewok.sched.request_schedule;
      return;

   <<ret_inval>>
      set_return_value (caller_id, mode, SYS_E_INVAL);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   <<ret_denied>>
      set_return_value (caller_id, mode, SYS_E_DENIED);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   <<ret_busy>>
      set_return_value (caller_id, mode, SYS_E_BUSY);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;


   end dev_unmap;

end ewok.syscalls.cfg.mem;
