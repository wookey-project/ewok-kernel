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

with config.applications;  use config.applications;
with ewok.tasks;
with m4.systick;

package ewok.alarm
   with spark_mode => on
is

   count_alarms : unsigned_32 := 0;

   type t_alarm_state is record
      time    : m4.systick.t_tick;
      handler : system_address;
   end record;

   alarm_state : array (t_real_task_id'range) of t_alarm_state
      := (others => (0, 0));

   procedure set_alarm
     (task_id        : in  t_real_task_id;
      ms             : in  milliseconds;
      handler        : in  system_address)
   with
      global => (Output => alarm_state);

   procedure unset_alarm
     (task_id        : in  t_real_task_id)
   with
      global => (Output => alarm_state);

   -- For a task, check if it's alarming time is over
   procedure check_alarm
     (task_id : in  t_real_task_id)
   with
      global => (In_Out => (alarm_state, ewok.tasks.tasks_list));

   -- For each task, check if it's alarming time is over
   procedure check_alarms
   with
      global => (In_Out => (alarm_state, ewok.tasks.tasks_list));

end ewok.alarm;
