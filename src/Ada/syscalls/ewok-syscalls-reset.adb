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
with ewok.perm;         use ewok.perm;
with ewok.debug;
with m4.scb;

package body ewok.syscalls.reset
   with spark_mode => off
is

   procedure svc_reset
     (caller_id   : in  ewok.tasks_shared.t_task_id;
      mode        : in  ewok.tasks_shared.t_task_mode)
   is
   begin

      if not ewok.perm.ressource_is_granted (PERM_RES_TSK_RESET, caller_id)
      then
         set_return_value (caller_id, mode, SYS_E_DENIED);
         ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
         return;
      end if;

      m4.scb.reset;

      debug.panic ("soc.nvic.reset failed !?!");

   end svc_reset;

end ewok.syscalls.reset;
