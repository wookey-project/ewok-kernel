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


package body ewok.syscalls.lock
   with spark_mode => off
is

   procedure sys_lock
     (caller_id   : in ewok.tasks_shared.t_task_id;
      params      : in t_parameters;
      mode        : in ewok.tasks_shared.t_task_mode)
   is
      syscall : t_syscalls_lock
         with address => params(0)'address;
   begin

      if mode = TASK_MODE_ISRTHREAD then
         set_return_value (caller_id, mode, SYS_E_DENIED);
         return;
      end if;

      if not syscall'valid then
         set_return_value (caller_id, mode, SYS_E_INVAL);
         return;
      end if;

      case syscall is
         when LOCK_ENTER =>
            set_return_value (caller_id, mode, SYS_E_DONE);
            ewok.tasks.set_state (caller_id, mode, TASK_STATE_LOCKED);

         when LOCK_EXIT  =>
            set_return_value (caller_id, mode, SYS_E_DONE);
            ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      end case;
   end sys_lock;

end ewok.syscalls.lock;
