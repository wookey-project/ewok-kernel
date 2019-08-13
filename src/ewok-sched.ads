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


with ewok.tasks_shared; use ewok.tasks_shared;
with applications;

package ewok.sched
   with spark_mode => on
is

   sched_period            : unsigned_32  := 0;
   current_task_id         : t_task_id    := ID_KERNEL;
   current_task_mode       : t_task_mode  := TASK_MODE_MAINTHREAD;
   last_main_user_task_id  : t_task_id    := applications.list'first;

   pragma assertion_policy (pre => IGNORE, post => IGNORE, assert => IGNORE);

   -- SPARK/ghost specific function
   function current_task_is_valid
      return boolean
         with ghost;

   procedure request_schedule
      with
         inline;

   function task_elect return t_task_id;

   procedure init;

   function pendsv_handler
     (frame_a : ewok.t_stack_frame_access)
      return ewok.t_stack_frame_access;

   function do_schedule
     (frame_a : ewok.t_stack_frame_access)
      return ewok.t_stack_frame_access
      renames pendsv_handler;

end ewok.sched;

