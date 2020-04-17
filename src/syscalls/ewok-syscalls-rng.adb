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
with ewok.sanitize;
with ewok.perm;
with ewok.debug;
with ewok.rng;
with types.c;           use type types.c.t_retval;


package body ewok.syscalls.rng
   with spark_mode => off
is

   procedure svc_get_random
     (caller_id   : in     ewok.tasks_shared.t_task_id;
      params      : in out t_parameters;
      mode        : in     ewok.tasks_shared.t_task_mode)
   is
      length      : unsigned_16
         with address => params(2)'address;

      buffer      : unsigned_8_array (1 .. unsigned_32 (length))
         with address => to_address (params(1));

      ok : boolean;
   begin

      -- Forbidden after end of task initialization
      if not is_init_done (caller_id) then
         goto ret_denied;
      end if;

      -- Does buffer'address is in the caller address space ?
      if not ewok.sanitize.is_range_in_data_slot
                 (to_system_address (buffer'address),
                  types.to_unsigned_32(length),
                  caller_id,
                  mode)
      then
         pragma DEBUG (debug.log (debug.ERROR,
            ewok.tasks.tasks_list(caller_id).name
            & ": svc_get_random(): 'value' parameter not in caller space"));
         goto ret_inval;
      end if;

      -- Is the task allowed to use the RNG?
      if not ewok.perm.ressource_is_granted
               (ewok.perm.PERM_RES_TSK_RNG, caller_id)
      then
         pragma DEBUG (debug.log (debug.ERROR,
            ewok.tasks.tasks_list(caller_id).name
            & ": svc_get_random(): permission not granted"));
         goto ret_denied;
      end if;

      -- Calling the RNG which handle the potential random source errors (case
      -- of harware random sources such as TRNG IP)
      -- NOTE: there is some time when the generated random
      --       content may be weak for various reason due to arch-specific
      --       constraint. In this case, the return value is set to
      --       busy. Please check this return value when using this
      --       syscall to avoid using weak random content

      ewok.rng.random_array (buffer, ok);

      if not ok then
         pragma DEBUG (debug.log (debug.ERROR,
            ewok.tasks.tasks_list(caller_id).name
            & ": svc_get_random(): weak seed"));
         goto ret_busy;
      end if;

      set_return_value (caller_id, mode, SYS_E_DONE);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   <<ret_inval>>
      set_return_value (caller_id, mode, SYS_E_INVAL);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   <<ret_busy>>
      set_return_value (caller_id, mode, SYS_E_BUSY);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   <<ret_denied>>
      set_return_value (caller_id, mode, SYS_E_DENIED);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   end svc_get_random;

end ewok.syscalls.rng;
