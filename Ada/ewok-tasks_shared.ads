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


with ada.unchecked_conversion;

package ewok.tasks_shared
   with spark_mode => off
is
   type t_task_id is
     (ID_UNUSED,
      ID_APP1,
      ID_APP2,
      ID_APP3,
      ID_APP4,
      ID_APP5,
      ID_APP6,
      ID_APP7,
      ID_SOFTIRQ,    -- Softirq thread 
      ID_KERNEL);    -- Idle thread

   type t_task_mode is
     (TASK_MODE_MAINTHREAD, TASK_MODE_ISRTHREAD);

   type t_scheduling_post_isr is
     (ISR_STANDARD,
      ISR_FORCE_MAINTHREAD,
      ISR_WITHOUT_MAINTHREAD);

   pragma Warnings (Off);
   -- We have to turn warnings off because the size of the t_task_id may
   -- differ

   function to_task_id is new ada.unchecked_conversion
     (unsigned_32, t_task_id);

   function to_unsigned_32 is new ada.unchecked_conversion
     (t_task_id, unsigned_32);

   pragma Warnings (On);

end ewok.tasks_shared;
