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
with ewok.sched;

package body ewok.syscalls.yield
   with spark_mode => off
is

   procedure svc_yield
     (caller_id   : in  ewok.tasks_shared.t_task_id;
      mode        : in  ewok.tasks_shared.t_task_mode)
   is
   begin

      if mode = TASK_MODE_ISRTHREAD then
         set_return_value (caller_id, mode, SYS_E_DENIED);
         return;
      end if;

      -- Before setting the current task in IDLE state, we verify that
      -- no IPC was sent to this task.
      if ewok.tasks.is_ipc_waiting (caller_id) then
         -- An IPC is waiting to be managed by the current task
         ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
         set_return_value (caller_id, mode, SYS_E_BUSY);
      else
         ewok.tasks.set_state (caller_id, mode, TASK_STATE_IDLE);
         set_return_value (caller_id, mode, SYS_E_DONE);
         ewok.sched.request_schedule;
      end if;


   end svc_yield;

end ewok.syscalls.yield;
