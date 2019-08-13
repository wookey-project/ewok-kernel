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

with applications;         use applications;
with ewok.exported.sleep;  use ewok.exported.sleep;
with ewok.tasks;
with m4.systick;

package ewok.sleep
   with spark_mode => on
is

   awakening_time : array (t_real_task_id'range) of m4.systick.t_tick
      := (others => 0);

   -- Make the task sleeping and not executable for the given time.
   -- Only external events can awake the task during this period unless
   -- SLEEP_MODE_DEEP is selected.
   procedure sleeping
     (task_id     : in  t_real_task_id;
      ms          : in  milliseconds;
      mode        : in  t_sleep_mode)
   with
      global => (Output => awakening_time);

   -- For each task, check if it's sleeping time is over
   procedure check_is_awoke
   with
      global => (In_Out => (awakening_time, ewok.tasks.tasks_list));

   -- Try to awake a task
   procedure try_waking_up
     (task_id : in  t_real_task_id)
   with
      global => (In_Out => (awakening_time, ewok.tasks.tasks_list));

   -- Check if a task is currently sleeping
   function is_sleeping
     (task_id : in  t_real_task_id)
      return boolean
   with
      global => (Input => awakening_time);

end ewok.sleep;
