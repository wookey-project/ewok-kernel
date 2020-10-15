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
with ewok.softirq;

package body ewok.alarm
   with spark_mode => off
is

   procedure set_alarm
     (task_id        : in  t_real_task_id;
      ms             : in  milliseconds;
      handler        : in  system_address)
   is
   begin
      if alarm_state(task_id).time = 0 then
         count_alarms := count_alarms + 1;
      end if;
      alarm_state(task_id).time     := m4.systick.get_ticks
                                          + m4.systick.to_ticks (ms);
      alarm_state(task_id).handler  := handler;
   end set_alarm;


   procedure unset_alarm
     (task_id        : in  t_real_task_id)
   is
   begin
      if alarm_state(task_id).time > 0 then
         count_alarms := count_alarms - 1;
      end if;
      alarm_state(task_id).time     := 0;
      alarm_state(task_id).handler  := 0;
   end unset_alarm;


   procedure check_alarm
     (task_id : in  t_real_task_id)
   is
      t           : constant m4.systick.t_tick := m4.systick.get_ticks;
      soft_params : ewok.softirq.t_soft_parameters;
   begin
      if alarm_state(task_id).time > 0 and
         t > alarm_state(task_id).time
      then
         soft_params := (alarm_state(task_id).handler, unsigned_32 (t), 0, 0);
         ewok.softirq.push_soft (task_id, soft_params);
         unset_alarm (task_id);
      end if;
   end check_alarm;


   procedure check_alarms
   is
   begin
      if count_alarms > 0 then
         for id in config.applications.list'range loop
            check_alarm (id);
         end loop;
      end if;
   end check_alarms;


end ewok.alarm;
