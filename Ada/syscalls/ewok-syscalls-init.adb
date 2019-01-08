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

with ewok.tasks;        use ewok.tasks;
with ewok.tasks_shared; use ewok.tasks_shared;
with ewok.devices_shared;     use ewok.devices_shared;
with ewok.exported.devices;   use ewok.exported.devices;
with ewok.devices;
with ewok.sanitize;
with ewok.dma;
with ewok.syscalls.dma;
with ewok.mpu;
with ewok.sched;
with debug;

package body ewok.syscalls.init
   with spark_mode => off
is

   package TSK renames ewok.tasks;


   procedure init_do_reg_devaccess
     (caller_id   : in ewok.tasks_shared.t_task_id;
      params      : in t_parameters;
      mode        : in ewok.tasks_shared.t_task_mode)
   is

      udev     : aliased ewok.exported.devices.t_user_device
         with import, address => to_address (params(1));

      -- Device descriptor transmitted to userspace
      descriptor  : unsigned_8 range 0 .. ewok.tasks.MAX_DEVS_PER_TASK
         with address => to_address (params(2));

      dev_id   : ewok.devices_shared.t_device_id;
      ok       : boolean;
   begin

      -- Forbidden after end of task initialization
      if TSK.is_init_done (caller_id) then
         goto ret_denied;
      end if;

      -- NOTE: The kernel might register some devices using this syscall
      -- for user task, device_t structure may be stored in:
      --    - its data slot (RAM)
      --    - its txt slot (.rodata)
      if TSK.is_user (caller_id) and then
        (not ewok.sanitize.is_range_in_data_slot
               (to_system_address (udev'address),
                udev'size/8,
                caller_id,
                mode)
         and
         not ewok.sanitize.is_range_in_txt_slot
               (to_system_address (udev'address),
                udev'size/8,
                caller_id))
      then
         debug.log (debug.ERROR,
            "init_do_reg_devaccess(): udev not in task's memory space");
         goto ret_denied;
      end if;

      if TSK.is_user (caller_id) and then
         not ewok.sanitize.is_word_in_data_slot
               (to_system_address (descriptor'address), caller_id, mode)
      then
         debug.log (debug.ERROR,
            "init_do_reg_devaccess(): descriptor not in task's memory space");
         goto ret_denied;
      end if;

      -- Ada based sanitization
      if not udev'valid_scalars
      then
         debug.log (debug.ERROR, "init_do_reg_devaccess(): invalid udev scalars");
         goto ret_inval;
      end if;

      if TSK.is_user (caller_id) and then
         not ewok.devices.sanitize_user_defined_device
                 (udev'unchecked_access, caller_id)
      then
         debug.log (debug.ERROR, "init_do_reg_devaccess(): invalid udev");
         goto ret_inval;
      end if;

      if TSK.tasks_list(caller_id).num_devs = TSK.MAX_DEVS_PER_TASK then
         debug.log (debug.ERROR,
            "init_do_reg_devaccess(): no space left to register the device");
         goto ret_busy;
      end if;

      if udev.size > 0                 and
         udev.map_mode = DEV_MAP_AUTO  and
         TSK.tasks_list(caller_id).num_devs_mounted = ewok.mpu.MAX_DEVICE_REGIONS
      then
         debug.log (debug.ERROR,
            "init_do_reg_devaccess(): no free region left to map the device");
         goto ret_busy;
      end if;

      --
      -- Registering the device
      --

      ewok.devices.register_device (caller_id, udev'unchecked_access, dev_id, ok);

      if not ok then
         debug.log (debug.ERROR,
            "init_do_reg_devaccess(): failed to register the device");
         goto ret_denied;
      end if;

      --
      -- Recording registered devices in the task record
      --

      TSK.append_device
        (caller_id, dev_id, descriptor, ok);
      if not ok then
         raise program_error; -- Should never happen here
      end if;

      -- Mount DEV_MAP_AUTO devices in memory
      if udev.size > 0 and udev.map_mode = DEV_MAP_AUTO then
         TSK.mount_device (caller_id, dev_id, ok);
         if not ok then
            raise program_error; -- Should never happen here
         end if;
      end if;

      set_return_value (caller_id, mode, SYS_E_DONE);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   <<ret_busy>>
      set_return_value (caller_id, mode, SYS_E_BUSY);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   <<ret_inval>>
      set_return_value (caller_id, mode, SYS_E_INVAL);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   <<ret_denied>>
      set_return_value (caller_id, mode, SYS_E_DENIED);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   end init_do_reg_devaccess;


   procedure init_do_done
     (caller_id   : in  ewok.tasks_shared.t_task_id;
      mode        : in  ewok.tasks_shared.t_task_mode)
   is
      ok   : boolean;
      udev : ewok.devices.t_checked_user_device_access;
   begin

      -- Forbidden after end of task initialization
      if TSK.is_init_done (caller_id) then
         goto ret_denied;
      end if;

      -- We enable auto mapped devices (MAP_AUTO)
      for i in TSK.tasks_list(caller_id).device_id'range loop
         if TSK.tasks_list(caller_id).device_id(i) /= ID_DEV_UNUSED then
            udev := ewok.devices.get_user_device
                       (TSK.tasks_list(caller_id).device_id(i));
            if udev.all.map_mode = DEV_MAP_AUTO then
               -- FIXME - Should create new syscalls for enabling/disabling devices
               ewok.devices.enable_device
                  (TSK.tasks_list(caller_id).device_id(i), ok);
               if not ok then
                  goto ret_denied;
               end if;
            end if;
         end if;
      end loop;

#if CONFIG_KERNEL_DMA_ENABLE
      for i in 1 .. TSK.tasks_list(caller_id).num_dma_id loop
         ewok.dma.enable_dma_irq (TSK.tasks_list(caller_id).dma_id(i));
      end loop;
#end if;

      TSK.tasks_list(caller_id).init_done := true;

      set_return_value (caller_id, mode, SYS_E_DONE);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);

      -- Request a schedule to ensure that the task has its devices mapped
      -- afterward
      -- FIXME - has to be changed when device mapping will be synchronously done
      ewok.sched.request_schedule;
      return;

   <<ret_denied>>
      set_return_value (caller_id, mode, SYS_E_DENIED);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;
   end init_do_done;


   procedure init_do_get_taskid
     (caller_id   : in ewok.tasks_shared.t_task_id;
      params      : in t_parameters;
      mode        : in ewok.tasks_shared.t_task_mode)
   is

      target_name : TSK.t_task_name
         with address => to_address (params(1));

      target_id   : ewok.tasks_shared.t_task_id
         with address => to_address (params(2));

   begin

      -- Forbidden after end of task initialization
      if TSK.is_init_done (caller_id) then
         goto ret_denied;
      end if;

      -- Does &target_id is in the caller address space ?
      if not ewok.sanitize.is_word_in_data_slot
               (to_system_address (target_id'address), caller_id, mode)
      then
         goto ret_denied;
      end if;

      target_id := TSK.get_task_id (target_name);

      if target_id = ID_UNUSED then
         goto ret_inval;
      end if;

#if CONFIG_KERNEL_DOMAIN
      if TSK.get_domain (target_id) /= TSK.get_domain (caller_id) then
         goto ret_inval;
      end if;
#end if;

      set_return_value (caller_id, mode, SYS_E_DONE);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   <<ret_inval>>
      set_return_value (caller_id, mode, SYS_E_INVAL);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   <<ret_denied>>
      set_return_value (caller_id, mode, SYS_E_DENIED);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;
   end init_do_get_taskid;


   procedure sys_init
     (caller_id   : in     ewok.tasks_shared.t_task_id;
      params      : in out t_parameters;
      mode        : in     ewok.tasks_shared.t_task_mode)
   is
      syscall : t_syscalls_init
         with import, address => params(0)'address;
   begin

      if not syscall'valid then
         set_return_value (caller_id, mode, SYS_E_INVAL);
         ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
         return;
      end if;

      case syscall is
         when INIT_DEVACCESS  => init_do_reg_devaccess
                                   (caller_id, params, mode);
#if CONFIG_KERNEL_DMA_ENABLE
         when INIT_DMA        => ewok.syscalls.dma.init_do_reg_dma
                                   (caller_id, params, mode);
         when INIT_DMA_SHM    => ewok.syscalls.dma.init_do_reg_dma_shm
                                   (caller_id, params, mode);
#end if;
         when INIT_GETTASKID  => init_do_get_taskid (caller_id, params, mode);
         when INIT_DONE       => init_do_done (caller_id, mode);
      end case;

   end sys_init;


end ewok.syscalls.init;

