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

package body ewok.sleep
   with spark_mode => off
is

   package TSK renames ewok.tasks;


   procedure sleeping
     (task_id     : in  t_real_task_id;
      ms          : in  milliseconds;
      mode        : in  t_sleep_mode)
   is
   begin
      sleep_info(task_id).sleep_until :=
         m4.systick.get_ticks + m4.systick.to_ticks (ms);

      if mode = SLEEP_MODE_INTERRUPTIBLE then
         sleep_info(task_id).interruptible   := true;
      else
         sleep_info(task_id).interruptible   := false;
      end if;

      TSK.set_state (task_id, TASK_MODE_MAINTHREAD, TASK_STATE_SLEEPING);
   end sleeping;


   procedure check_is_awoke
   is
      t : constant m4.systick.t_tick := m4.systick.get_ticks;
   begin
      for id in applications.list'range loop
         if TSK.tasks_list(id).state = TASK_STATE_SLEEPING and then
            t > sleep_info(id).sleep_until
         then
            TSK.set_state (id, TASK_MODE_MAINTHREAD, TASK_STATE_RUNNABLE);
         end if;
      end loop;
   end check_is_awoke;


   procedure try_waking_up
     (task_id : in  t_real_task_id)
   is
   begin
      if sleep_info(task_id).sleep_until < m4.systick.get_ticks or
         sleep_info(task_id).interruptible
      then
         TSK.set_state (task_id, TASK_MODE_MAINTHREAD, TASK_STATE_RUNNABLE);
      end if;
   end try_waking_up;


   function is_sleeping
     (task_id : in  t_real_task_id)
      return boolean
   is
   begin
      if TSK.tasks_list(task_id).state = TASK_STATE_SLEEPING then
         if sleep_info(task_id).sleep_until > m4.systick.get_ticks then
            return true;
         else
            TSK.set_state (task_id, TASK_MODE_MAINTHREAD, TASK_STATE_RUNNABLE);
            return false;
         end if;
      else
         return false;
      end if;
   end is_sleeping;

end ewok.sleep;
