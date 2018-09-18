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

with applications;       use applications;
with ewok.exported.sleep; use ewok.exported.sleep;
with m4.systick;

package ewok.sleep
   with spark_mode => off
is

   type t_sleep_info is record
      sleep_until    : m4.systick.t_tick;
      interruptible  : boolean;
   end record;

   sleep_info : array (t_real_task_id'range) of t_sleep_info :=
     (others => (0, false));


   --
   -- \brief declare a time to sleep.
   --
   -- This function is called in a syscall context and make the task
   -- unschedulable for at least the given sleep_until. Only external events
   -- (ISR, IPC) can awake the task during this period. If no external events
   -- happend, the task is marked as schedulable at the end of the sleep
   -- period, which means that the task is schedule *after* the sleep time,
   -- not exactly at the sleep time end.
   -- The variation of the time to wait between the end of the sleep time and
   -- the effective time execution depends on the scheduling policy, the task
   -- priority and the number of tasks on the system.
   --
   -- \param id   --   --e task id requesting to sleep
   -- \param sleep_until the sleep duration in unit given by unit argument
   -- \param mode   -- sleep mode (preemptible by ISR or IPC, or not)
   --
   procedure sleeping
     (task_id     : in  t_real_task_id;
      ms          : in  milliseconds;
      mode        : in  t_sleep_mode)
   with
      global => (Output => sleep_info);

   --
   -- This function is called at each sched time of the systick handler, to
   -- decrement the sleep_until of each task of 1.
   -- If the speeptime reaches 0, the task mainthread is awoken.
   --
   -- WARNING: there is case where the task is awoken *before* the end of
   -- its sleep period:
   -- - when an ISR arise
   -- - when an IPC targeting the task is pushed
   --
   -- In theses two cases, the sleep_cancel() function must be called in order
   -- to cancel the current sleep round. The task is awoken by the corresponding
   -- kernel module instead.
   --
   procedure check_is_awoke
   with
      global => (In_Out => sleep_info);

   --
   -- As explain in sleep_round function explanations, some external events
   -- may awake the main thread. In that case, the sleep process must be
   -- canceled as the awoking process is made by another module.
   -- tasks that have requested locked sleep will continue to sleep
   --
   procedure try_waking_up
     (task_id : in  t_real_task_id)
   with
      global => (In_Out => sleep_info);

   --
   -- \brief check if a task is currently sleeping
   --
   -- \param id the task id to check
   --
   -- return true if a task is sleeping, or false
   --
   function is_sleeping
     (task_id : in  t_real_task_id)
      return boolean
   with
      global => (Input => sleep_info);

end ewok.sleep;
