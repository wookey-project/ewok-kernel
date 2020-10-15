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
with ewok.sanitize;
with ewok.debug;
with ewok.alarm;

package body ewok.syscalls.alarm
   with spark_mode => off
is

   procedure svc_alarm
     (caller_id   : in     ewok.tasks_shared.t_task_id;
      params      : in     t_parameters;
      mode        : in     ewok.tasks_shared.t_task_mode)
   is
      alarm_time  : unsigned_32 with address => params(1)'address;
      handler     : constant system_address  := params(2);
   begin

      if alarm_time = 0 or handler = 0 then
         ewok.alarm.unset_alarm (caller_id);
         goto ret_ok;
      end if;

      if not ewok.sanitize.is_word_in_txt_slot (handler, caller_id)
      then
         pragma DEBUG (debug.log (debug.ERROR, "Handler not in .txt section"));
         goto ret_denied;
      end if;

      ewok.alarm.set_alarm
        (caller_id, milliseconds (alarm_time), handler);

   <<ret_ok>>
      set_return_value (caller_id, mode, SYS_E_DONE);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   <<ret_denied>>
      set_return_value (caller_id, mode, SYS_E_DENIED);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;
   end svc_alarm;

end ewok.syscalls.alarm;

