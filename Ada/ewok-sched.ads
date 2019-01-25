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

package ewok.sched
   with spark_mode => on
is

   -- SPARK/ghost specific function
   function current_task_is_valid
      return boolean
   with ghost;

   function get_current return ewok.tasks_shared.t_task_id
   with
      inline,
      pre => (current_task_is_valid);

   procedure request_schedule
   with spark_mode => off;

   function task_elect return t_task_id
   with spark_mode => off;

   procedure init
   with spark_mode => off;

   function pendsv_handler
     (frame_a : ewok.t_stack_frame_access)
      return ewok.t_stack_frame_access
   with spark_mode => off;

   function do_schedule
     (frame_a : ewok.t_stack_frame_access)
      return ewok.t_stack_frame_access
   renames pendsv_handler;


end ewok.sched;

