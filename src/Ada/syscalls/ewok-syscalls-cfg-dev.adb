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

with ewok.debug;
with ewok.tasks;              use ewok.tasks;
with ewok.tasks_shared;       use ewok.tasks_shared;
with ewok.exported.devices;   use ewok.exported.devices;
with ewok.devices_shared;     use ewok.devices_shared;
with ewok.devices;


package body ewok.syscalls.cfg.dev
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
      dev         : ewok.devices.t_checked_user_device_access;
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
         debug.log (debug.ERROR,
            ewok.tasks.tasks_list(caller_id).name
            & ": dev_map(): forbidden in ISR mode");
         goto ret_denied;
      end if;

      -- No map/unmap before end of initialization
      if not is_init_done (caller_id) then
         debug.log (debug.ERROR,
            ewok.tasks.tasks_list(caller_id).name
            & ": dev_map(): forbidden during init sequence");
         goto ret_denied;
      end if;

      -- Valid device descriptor ?
      if dev_descriptor not in  TSK.tasks_list(caller_id).device_id'range
      then
         debug.log (debug.ERROR,
            ewok.tasks.tasks_list(caller_id).name
            & ": dev_map(): invalid device descriptor");
         goto ret_inval;
      end if;

      dev_id   := TSK.tasks_list(caller_id).device_id (dev_descriptor);

      -- Used device descriptor ?
      if dev_id = ID_DEV_UNUSED then
         debug.log (debug.ERROR,
            ewok.tasks.tasks_list(caller_id).name
            & ": dev_map(): unused device");
         goto ret_inval;
      end if;

      -- Defensive programming. Verifying that the device really belongs to the
      -- task
      if ewok.devices.get_task_from_id (dev_id) /= caller_id then
         raise program_error;
      end if;

      -- Verifying that the device may be voluntary mapped by the task
      dev      := ewok.devices.get_user_device (dev_id);

      if dev.map_mode /= ewok.exported.devices.DEV_MAP_VOLUNTARY then
         debug.log (debug.ERROR,
            ewok.tasks.tasks_list(caller_id).name
            & ": dev_map(): not a DEV_MAP_VOLUNTARY device");
         goto ret_denied;
      end if;

      -- Verifying that the device is not already mapped
      if TSK.is_mounted (caller_id, dev_id) then
         debug.log (debug.ERROR,
            ewok.tasks.tasks_list(caller_id).name
            & ": dev_map(): the device is already mapped");
         goto ret_denied;
      end if;

      --
      -- Mapping the device
      --

      TSK.mount_device (caller_id, dev_id, ok);

      if not ok then
         debug.log (debug.ERROR,
            ewok.tasks.tasks_list(caller_id).name
            & ": dev_map(): mount_device() failed (no free region?)");
         goto ret_busy;
      end if;

      -- We enable the device if its not already enabled
      -- FIXME - That code should not be here.
      --         Should create a special syscall for enabling/disabling
      --         devices (cf. ewok-syscalls-init.adb)
      ewok.devices.enable_device (dev_id, ok);
      if not ok then
         goto ret_denied;
      end if;

      set_return_value (caller_id, mode, SYS_E_DONE);
      TSK.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
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
      dev_id         : ewok.devices_shared.t_device_id;
      dev            : ewok.devices.t_checked_user_device_access;
      ok             : boolean;
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
         debug.log (debug.ERROR,
            ewok.tasks.tasks_list(caller_id).name
            & ": dev_unmap(): forbidden in ISR mode");
         goto ret_denied;
      end if;

      -- No unmap before end of initialization
      if not is_init_done (caller_id) then
         debug.log (debug.ERROR,
            ewok.tasks.tasks_list(caller_id).name
            & ": dev_unmap(): forbidden during init sequence");
         goto ret_denied;
      end if;

      -- Valid device descriptor ?
      if dev_descriptor not in  TSK.tasks_list(caller_id).device_id'range
      then
         debug.log (debug.ERROR,
            ewok.tasks.tasks_list(caller_id).name
            & ": dev_unmap(): invalid device descriptor");
         goto ret_inval;
      end if;

      dev_id   := TSK.tasks_list(caller_id).device_id (dev_descriptor);

      -- Used device descriptor ?
      if dev_id = ID_DEV_UNUSED then
         debug.log (debug.ERROR,
            ewok.tasks.tasks_list(caller_id).name
            & ": dev_unmap(): unused device");
         goto ret_inval;
      end if;

      -- Defensive programming. Verifying that the device really belongs to the
      -- task
      if ewok.devices.get_task_from_id (dev_id) /= caller_id then
         raise program_error;
      end if;

      -- Verifying that the device may be voluntary unmapped by the task
      dev      := ewok.devices.get_user_device (dev_id);

      if dev.map_mode /= ewok.exported.devices.DEV_MAP_VOLUNTARY then
         debug.log (debug.ERROR,
            ewok.tasks.tasks_list(caller_id).name
            & ": dev_unmap(): not a DEV_MAP_VOLUNTARY device");
         goto ret_denied;
      end if;

      --
      -- Unmapping the device
      --

      TSK.unmount_device (caller_id, dev_id, ok);

      if not ok then
         debug.log (debug.ERROR,
            ewok.tasks.tasks_list(caller_id).name
            & ": dev_unmap(): device is not mapped");
         goto ret_denied;
      end if;

      set_return_value (caller_id, mode, SYS_E_DONE);
      TSK.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
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


   procedure dev_release
     (caller_id   : in     ewok.tasks_shared.t_task_id;
      params      : in out t_parameters;
      mode        : in     ewok.tasks_shared.t_task_mode)
   is
      dev_descriptor : unsigned_8
         with address => params(1)'address;
      dev_id         : ewok.devices_shared.t_device_id;
      ok             : boolean;
   begin

      -- No release before end of initialization
      if not is_init_done (caller_id) then
         debug.log (debug.ERROR,
            ewok.tasks.tasks_list(caller_id).name
            & ": dev_release(): forbidden during init sequence");
         goto ret_denied;
      end if;

      -- Valid device descriptor ?
      if dev_descriptor not in  TSK.tasks_list(caller_id).device_id'range
      then
         debug.log (debug.ERROR,
            ewok.tasks.tasks_list(caller_id).name
            & ": dev_release(): invalid device descriptor");
         goto ret_inval;
      end if;

      dev_id   := TSK.tasks_list(caller_id).device_id (dev_descriptor);

      -- Used device descriptor ?
      if dev_id = ID_DEV_UNUSED then
         debug.log (debug.ERROR,
            ewok.tasks.tasks_list(caller_id).name
            & ": dev_release(): unused device");
         goto ret_inval;
      end if;

      -- Defensive programming. Verifying that the device really belongs to the
      -- task
      if ewok.devices.get_task_from_id (dev_id) /= caller_id then
         raise program_error;
      end if;

      --
      -- Releasing the device
      --

      -- Unmounting the device
      if TSK.is_mounted (caller_id, dev_id) then
         TSK.unmount_device (caller_id, dev_id, ok);
         if not ok then
            raise program_error; -- Should never happen
         end if;
      end if;

      -- Removing it from the task's list of used devices
      TSK.remove_device (caller_id, dev_id, ok);
      if not ok then
         raise program_error; -- Should never happen
      end if;

      -- Release GPIOs, EXTIs and interrupts
      ewok.devices.release_device (caller_id, dev_id, ok);

      set_return_value (caller_id, mode, SYS_E_DONE);
      TSK.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   <<ret_inval>>
      set_return_value (caller_id, mode, SYS_E_INVAL);
      TSK.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   <<ret_denied>>
      set_return_value (caller_id, mode, SYS_E_DENIED);
      TSK.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   end dev_release;


end ewok.syscalls.cfg.dev;
