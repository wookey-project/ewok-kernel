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

with ewok.perm;            use ewok.perm;
with ewok.tasks;           use ewok.tasks;
with ewok.tasks_shared;    use ewok.tasks_shared;
with ewok.exported.ticks;  use ewok.exported.ticks;
with ewok.sanitize;
with ewok.debug;
with soc.dwt;


package body ewok.syscalls.gettick
   with spark_mode => off
is

   procedure svc_gettick
     (caller_id   : in     ewok.tasks_shared.t_task_id;
      params      : in out t_parameters;
      mode        : in     ewok.tasks_shared.t_task_mode)
   is

      value_address  : constant system_address := params(1);
      precision      : ewok.exported.ticks.t_precision
         with address => params(2)'address;
   begin

      if not precision'valid then
         goto ret_inval;
      end if;

      -- Does &value is in the caller address space ?
      if not ewok.sanitize.is_range_in_data_region
               (value_address, 8, caller_id, mode)
      then
         pragma DEBUG (debug.log (debug.ERROR,
            ewok.tasks.tasks_list(caller_id).name
            & ": svc_gettick(): 'value' parameter not in caller space"));
         goto ret_inval;
      end if;

      declare
         value : unsigned_64
            with address => to_address (value_address);
      begin
         -- Verifying permisions
         case precision is
            when PRECISION_MILLI_SEC =>
               if not ewok.perm.ressource_is_granted
                  (PERM_RES_TIM_GETMILLI, caller_id)
               then
                  goto ret_denied;
               end if;
               soc.dwt.get_milliseconds (value);

            when PRECISION_MICRO_SEC =>
               if not ewok.perm.ressource_is_granted
                  (PERM_RES_TIM_GETMICRO, caller_id)
               then
                  goto ret_denied;
               end if;
               soc.dwt.get_microseconds (value);

            when PRECISION_CYCLE =>
               if not ewok.perm.ressource_is_granted
                  (PERM_RES_TIM_GETCYCLE, caller_id)
               then
                  goto ret_denied;
               end if;
               soc.dwt.get_cycles (value);
         end case;
      end;

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

   end svc_gettick;

end ewok.syscalls.gettick;

