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
with ewok.ipc;          use ewok.ipc;
with ewok.sched;

package body ewok.syscalls.yield
   with spark_mode => off
is

   procedure sys_yield
     (caller_id   : in  ewok.tasks_shared.t_task_id;
      mode        : in  ewok.tasks_shared.t_task_mode)
   is
      ipc_waiting : boolean;
   begin

      if mode = TASK_MODE_ISRTHREAD then
         set_return_value (caller_id, mode, SYS_E_DENIED);
         return;
      end if;

      set_return_value (caller_id, mode, SYS_E_DONE);


      -- is there an IPC that have been sent to caller_id while the caller
      -- was executing its yield() userspace code ?
      -- The goal here is to avoid yielding to IDLE mode while an IPC is
      -- waiting in the task's IPC endpoints from any other application.
      -- This case can happen only if the task is preempted between its IPC
      -- check and its execution of the spervisor call of this very syscall.
      -- This temporal frame may be long enough to generate such a race
      -- condition in the case of huge IPC-based communication channels
      for i in ewok.tasks.tasks_list(caller_id).ipc_endpoints'range loop
         if ewok.tasks.tasks_list(caller_id).ipc_endpoints(i) /= NULL
            and then
            ewok.tasks.tasks_list(caller_id).ipc_endpoints(i).state
            = ewok.ipc.WAIT_FOR_RECEIVER
            and then
            ewok.ipc.to_task_id
               (ewok.tasks.tasks_list(caller_id).ipc_endpoints(i).to)
               = caller_id
         then
            -- there is an IPC waiting
            ipc_waiting := true;
         else
            ipc_waiting := false;
         end if;
      end loop;


      if not ipc_waiting
      then
         ewok.tasks.set_state (caller_id, mode, TASK_STATE_IDLE);
      else
         -- there is an IPC waiting, we can't yield, as the main thread
         -- may never be awoken if this IPC is the last unblocking event
         -- of this thread.
         ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      end if;
      ewok.sched.request_schedule;
      return;

   end sys_yield;

end ewok.syscalls.yield;
