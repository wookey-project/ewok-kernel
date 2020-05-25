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
with ewok.debug;

package body ewok.syscalls.log
   with spark_mode => off
is

   procedure svc_log
     (caller_id   : in     ewok.tasks_shared.t_task_id;
      params      : in out t_parameters;
      mode        : in     ewok.tasks_shared.t_task_mode)
   is
      -- Message size
      size  : positive
         with address => params(1)'address;

      -- Message address
      msg_address : constant system_address := params(2);

   begin

      if size >= 512 then
         goto ret_inval;
      end if;

      -- Does &msg is in the caller address space ?
      if not ewok.sanitize.is_range_in_data_slot
              (msg_address,
               unsigned_32 (size),
               caller_id,
               mode)
      then
         goto ret_inval;
      end if;

      declare
         msg : string (1 .. size)
            with address => to_address (msg_address);
      begin
         pragma DEBUG (debug.log
           (ewok.tasks.tasks_list(caller_id).name & " " & msg & ASCII.CR,
            false));
      end;

      set_return_value (caller_id, mode, SYS_E_DONE);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   <<ret_inval>>
      set_return_value (caller_id, mode, SYS_E_INVAL);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
   end svc_log;


end ewok.syscalls.log;
