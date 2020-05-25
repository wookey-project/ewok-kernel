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
with ewok.dma_shared;   use ewok.dma_shared;
with ewok.exported.dma;
with ewok.dma;
with ewok.perm;
with ewok.sanitize;
with ewok.debug;

package body ewok.syscalls.dma
   with spark_mode => off
is

   package TSK renames ewok.tasks;

   procedure svc_register_dma
     (caller_id   : in ewok.tasks_shared.t_task_id;
      params      : in t_parameters;
      mode        : in ewok.tasks_shared.t_task_mode)
   is
      dma_config_address : constant system_address := params(1);
      descriptor_address : constant system_address := params(2);
      index              : ewok.dma_shared.t_registered_dma_index;
      ok                 : boolean;
   begin

      -- Forbidden after end of task initialization
      if is_init_done (caller_id) then
         goto ret_denied;
      end if;

      -- DMA allowed for that task?
      if not ewok.perm.ressource_is_granted
               (ewok.perm.PERM_RES_DEV_DMA, caller_id)
      then
         pragma DEBUG (debug.log (debug.ERROR, "svc_register_dma(): permission not granted"));
         goto ret_denied;
      end if;

      -- Does dma_config is in caller's address space ?
      if not ewok.sanitize.is_range_in_data_slot
                 (dma_config_address,
                  ewok.exported.dma.t_dma_user_config'size/8,
                  caller_id,
                  mode)
      then
         pragma DEBUG (debug.log (debug.ERROR, "svc_register_dma(): dma_config not in task's memory space"));
         goto ret_denied;
      end if;

      -- Does descriptor_address is in caller's address space ?
      if not ewok.sanitize.is_word_in_data_slot
                 (descriptor_address, caller_id, mode)
      then
         pragma DEBUG (debug.log (debug.ERROR, "svc_register_dma(): descriptor not in task's memory space"));
         goto ret_denied;
      end if;


      declare
         dma_config  : constant ewok.exported.dma.t_dma_user_config
            with import, address => to_address (dma_config_address);

         descriptor  : unsigned_32
            with import, address => to_address (descriptor_address);
      begin

         -- Ada based sanitation using on types compliance
         if not dma_config'valid_scalars
         then
            pragma DEBUG (debug.log (debug.ERROR, "svc_register_dma(): invalid dma_t"));
            goto ret_inval;
         end if;

         -- Verify DMA configuration transmitted by the user
         if not ewok.dma.sanitize_dma
                    (dma_config, caller_id,
                     ewok.exported.dma.t_config_mask'(others => false), mode)
         then
            pragma DEBUG (debug.log (debug.ERROR, "svc_register_dma(): invalid dma configuration"));
            goto ret_inval;
         end if;

         -- Check if controller/stream are already used
         -- Note: A DMA controller can manage only one channel per stream in the
         --       same time.
         if ewok.dma.stream_is_already_used (dma_config) then
            pragma DEBUG (debug.log (debug.ERROR, "svc_register_dma(): dma configuration already used"));
            goto ret_denied;
         end if;

         -- Is there any user descriptor available ?
         if TSK.tasks_list(caller_id).num_dma_id < MAX_DMAS_PER_TASK then
            TSK.tasks_list(caller_id).num_dma_id :=
               TSK.tasks_list(caller_id).num_dma_id + 1;
         else
            goto ret_busy;
         end if;

         -- Initialization
         ewok.dma.init_stream (dma_config, caller_id, index, ok);
         if not ok then
            pragma DEBUG (debug.log (debug.ERROR, "svc_register_dma(): dma initialization failed"));
            goto ret_denied;
         end if;

         descriptor := TSK.tasks_list(caller_id).num_dma_id;
         TSK.tasks_list(caller_id).dma_id(descriptor) := index;

         set_return_value (caller_id, mode, SYS_E_DONE);
         ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
         return;
      end;

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

   end svc_register_dma;


   procedure svc_register_dma_shm
     (caller_id   : in ewok.tasks_shared.t_task_id;
      params      : in t_parameters;
      mode        : in ewok.tasks_shared.t_task_mode)
   is
      dma_shm_config_address : constant system_address := params(1);
      granted_id           : ewok.tasks_shared.t_task_id;
   begin

      -- Forbidden after end of task initialization
      if is_init_done (caller_id) then
         goto ret_denied;
      end if;

      -- Does dma_shm_config'address is in the caller address space ?
      if not ewok.sanitize.is_range_in_data_slot
                 (dma_shm_config_address,
                  ewok.exported.dma.t_dma_shm_info'size/8,
                  caller_id,
                  mode)
      then
         pragma DEBUG (debug.log (debug.ERROR, "svc_register_dma_shm(): parameters not in task's memory space"));
         goto ret_denied;
      end if;


      declare
         dma_shm_config   : ewok.exported.dma.t_dma_shm_info
            with import, address => to_address (dma_shm_config_address);
      begin

         -- Ada based sanitation using on types compliance
         if not dma_shm_config'valid_scalars
         then
            pragma DEBUG (debug.log (debug.ERROR, "svc_register_dma_shm(): invalid dma_shm_t"));
            goto ret_inval;
         end if;

         -- Verify DMA shared memory configuration transmitted by the user
         if not ewok.dma.sanitize_dma_shm (dma_shm_config, caller_id, mode)
         then
            pragma DEBUG (debug.log (debug.ERROR, "svc_register_dma_shm(): invalid configuration"));
            goto ret_inval;
         end if;

         granted_id := dma_shm_config.granted_id;

         -- Does the task can share memory with its target task?
         if not ewok.perm.dmashm_is_granted (caller_id, granted_id)
         then
            pragma DEBUG (debug.log (debug.ERROR, "svc_register_dma_shm(): not granted"));
            goto ret_denied;
         end if;

         -- Is there any user descriptor available ?
         if TSK.tasks_list(granted_id).num_dma_shms < MAX_DMA_SHM_PER_TASK and
            TSK.tasks_list(caller_id).num_dma_shms  < MAX_DMA_SHM_PER_TASK
         then
            TSK.tasks_list(granted_id).num_dma_shms := TSK.tasks_list(granted_id).num_dma_shms + 1;
            TSK.tasks_list(caller_id).num_dma_shms  := TSK.tasks_list(caller_id).num_dma_shms + 1;
         else
            pragma DEBUG (debug.log (debug.ERROR, "svc_register_dma_shm(): busy"));
            goto ret_busy;
         end if;

         TSK.tasks_list(granted_id).dma_shm(TSK.tasks_list(granted_id).num_dma_shms) := dma_shm_config;
         TSK.tasks_list(caller_id).dma_shm(TSK.tasks_list(caller_id).num_dma_shms) := dma_shm_config;

         set_return_value (caller_id, mode, SYS_E_DONE);
         ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
         return;
      end;

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

   end svc_register_dma_shm;


   procedure svc_dma_reconf
     (caller_id   : in     ewok.tasks_shared.t_task_id;
      params      : in out t_parameters;
      mode        : in     ewok.tasks_shared.t_task_mode)
   is

      new_dma_config_address : constant system_address := params(1);

      config_mask    : ewok.exported.dma.t_config_mask
         with import, address => params(2)'address;

      dma_descriptor : unsigned_32
         with import, address => params(3)'address;

      ok             : boolean;
   begin

      -- Forbidden before end of task initialization
      if not is_init_done (caller_id) then
         goto ret_denied;
      end if;

      -- Does new_dma_config'address is in the caller address space ?
      if not ewok.sanitize.is_range_in_data_slot
                 (new_dma_config_address,
                  ewok.exported.dma.t_dma_user_config'size/8,
                  caller_id,
                  mode)
      then
         pragma DEBUG (debug.log (debug.ERROR, "svc_dma_reconf(): parameters not in task's memory space"));
         goto ret_inval;
      end if;

      -- Valid DMA descriptor ?
      if dma_descriptor < TSK.tasks_list(caller_id).dma_id'first or
         dma_descriptor > TSK.tasks_list(caller_id).num_dma_id
      then
         pragma DEBUG (debug.log (debug.ERROR, "svc_dma_reconf(): invalid descriptor"));
         goto ret_inval;
      end if;


      declare
         new_dma_config : ewok.exported.dma.t_dma_user_config
            with import, address => to_address (new_dma_config_address);
      begin
         -- Check if the user tried to change the DMA ctrl/channel/stream
         -- parameters
         if not ewok.dma.has_same_dma_channel
                    (TSK.tasks_list(caller_id).dma_id(dma_descriptor), new_dma_config)
         then
            pragma DEBUG (debug.log (debug.ERROR, "svc_dma_reconf(): ctrl/channel/stream changed"));
            goto ret_inval;
         end if;

         -- Ada based sanitation using on types compliance is not easy,
         -- as only fields marked by config_mask have a real interpretation
         -- These fields are checked in the dma_sanitize_dma() function call
         -- bellow

         -- Verify DMA configuration transmitted by the user
         if not ewok.dma.sanitize_dma
                    (new_dma_config, caller_id, config_mask, mode)
         then
            pragma DEBUG (debug.log (debug.ERROR, "svc_dma_reconf(): invalid configuration"));
            goto ret_inval;
         end if;

         -- Reconfigure the DMA controller
         ewok.dma.reconfigure_stream
           (new_dma_config,
            TSK.tasks_list(caller_id).dma_id(dma_descriptor),
            config_mask,
            caller_id,
            ok);

         if not ok then
            goto ret_inval;
         end if;

         set_return_value (caller_id, mode, SYS_E_DONE);
         ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
         return;
      end;

   <<ret_inval>>
      set_return_value (caller_id, mode, SYS_E_INVAL);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   <<ret_denied>>
      set_return_value (caller_id, mode, SYS_E_DENIED);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   end svc_dma_reconf;


   procedure svc_dma_reload
     (caller_id   : in     ewok.tasks_shared.t_task_id;
      params      : in out t_parameters;
      mode        : in     ewok.tasks_shared.t_task_mode)
   is
      dma_descriptor : unsigned_32
         with import, address => params(1)'address;
   begin

      -- Forbidden before end of task initialization
      if not is_init_done (caller_id) then
         goto ret_denied;
      end if;

      -- Valid DMA descriptor ?
      if dma_descriptor < TSK.tasks_list(caller_id).dma_id'first or
         dma_descriptor > TSK.tasks_list(caller_id).num_dma_id
      then
         pragma DEBUG (debug.log (debug.ERROR, "svc_dma_reload(): invalid descriptor"));
         goto ret_inval;
      end if;

      ewok.dma.enable_dma_stream
        (TSK.tasks_list(caller_id).dma_id(dma_descriptor));

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

   end svc_dma_reload;


   procedure svc_dma_disable
     (caller_id   : in     ewok.tasks_shared.t_task_id;
      params      : in out t_parameters;
      mode        : in     ewok.tasks_shared.t_task_mode)
   is
      dma_descriptor : unsigned_32
         with import, address => params(1)'address;
   begin

      -- Forbidden before end of task initialization
      if not is_init_done (caller_id) then
         goto ret_denied;
      end if;

      -- Valid DMA descriptor ?
      if dma_descriptor < TSK.tasks_list(caller_id).dma_id'first or
         dma_descriptor > TSK.tasks_list(caller_id).num_dma_id
      then
         pragma DEBUG (debug.log (debug.ERROR, "svc_dma_disable(): invalid descriptor"));
         goto ret_inval;
      end if;

      ewok.dma.disable_dma_stream
        (TSK.tasks_list(caller_id).dma_id(dma_descriptor));

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

   end svc_dma_disable;


end ewok.syscalls.dma;
