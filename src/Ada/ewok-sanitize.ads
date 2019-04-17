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
with ewok.exported.dma;

package ewok.sanitize
   with spark_mode => on
is

   function is_range_in_devices_slot
     (ptr      : system_address;
      size     : unsigned_32;
      task_id  : ewok.tasks_shared.t_task_id)
      return boolean;

   pragma warnings (off, "explicit membership test may be optimized");

   function is_word_in_data_slot
     (ptr      : system_address;
      task_id  : ewok.tasks_shared.t_task_id;
      mode     : ewok.tasks_shared.t_task_mode) return boolean
      with
         global => null,
         post  => (if (ptr + 4 not in system_address'range) then is_word_in_data_slot'result = false);

   function is_word_in_txt_slot
     (ptr      : system_address;
      task_id  : ewok.tasks_shared.t_task_id) return boolean
      with
         global => null,
         -- there is now hypothesis on input values, yet we impose some
         -- specific behavior for various overflows
         post  => (if (ptr + 4 not in system_address'range) then is_word_in_txt_slot'result = false);

   function is_word_in_allocated_device
     (ptr      : system_address;
      task_id  : ewok.tasks_shared.t_task_id)
      return boolean;

   function is_word_in_any_slot
     (ptr      : system_address;
      task_id  : ewok.tasks_shared.t_task_id;
      mode     : ewok.tasks_shared.t_task_mode) return boolean
      with
         global => null,
         -- there is now hypothesis on input values, yet we impose some
         -- specific behavior for various overflows
         post  => (if (ptr + 4 not in system_address'range) then is_word_in_any_slot'result = false);

   function is_range_in_data_slot
     (ptr      : system_address;
      size     : unsigned_32;
      task_id  : ewok.tasks_shared.t_task_id;
      mode     : ewok.tasks_shared.t_task_mode) return boolean
      with
         global => null,
         -- there is now hypothesis on input values, yet we impose some
         -- specific behavior for various overflows
         post  => (if (ptr + size not in system_address'range) then is_range_in_data_slot'result = false);

   function is_range_in_txt_slot
     (ptr      : system_address;
      size     : unsigned_32;
      task_id  : ewok.tasks_shared.t_task_id) return boolean
      with
         global => null,
         -- there is now hypothesis on input values, yet we impose some
         -- specific behavior for various overflows
         post  => (if (ptr + size not in system_address'range) then is_range_in_txt_slot'result = false);

   function is_range_in_any_slot
     (ptr      : system_address;
      size     : unsigned_32;
      task_id  : ewok.tasks_shared.t_task_id;
      mode     : ewok.tasks_shared.t_task_mode) return boolean
      with
         global => null,
         -- there is now hypothesis on input values, yet we impose some
         -- specific behavior for various overflows
         post  => (if (ptr + size not in system_address'range) then is_range_in_any_slot'result = false);

   function is_range_in_dma_shm
     (ptr         : system_address;
      size        : unsigned_32;
      dma_access  : ewok.exported.dma.t_dma_shm_access;
      task_id     : ewok.tasks_shared.t_task_id) return boolean
      with
         spark_mode => off,
         global     => null,
         -- there is now hypothesis on input values, yet we impose some
         -- specific behavior for various overflows
         post       => (if (ptr + size not in system_address'range) then is_range_in_dma_shm'result = false);

   pragma warnings (on);

end ewok.sanitize;
