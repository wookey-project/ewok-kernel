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

   function is_word_in_data_slot
     (ptr      : system_address;
      task_id  : ewok.tasks_shared.t_task_id;
      mode     : ewok.tasks_shared.t_task_mode) return boolean
      with
         Global => null,
         Post  => (if (ptr + 4 not in system_address'range) then is_word_in_data_slot'Result = false);

   function is_word_in_txt_slot
     (ptr      : system_address;
      task_id  : ewok.tasks_shared.t_task_id) return boolean
      with
         Global => null,
         -- there is now hypothesis on input values, yet we impose some
         -- specific behavior for various overflows
         Post  => (if (ptr + 4 not in system_address'range) then is_word_in_txt_slot'Result = false);

   function is_word_in_allocated_device
     (ptr      : system_address;
      task_id  : ewok.tasks_shared.t_task_id)
      return boolean;

   function is_word_in_any_slot
     (ptr      : system_address;
      task_id  : ewok.tasks_shared.t_task_id;
      mode     : ewok.tasks_shared.t_task_mode) return boolean
      with
         Global => null,
         -- there is now hypothesis on input values, yet we impose some
         -- specific behavior for various overflows
         Post  => (if (ptr + 4 not in system_address'range) then is_word_in_any_slot'Result = false);

   function is_range_in_data_slot
     (ptr      : system_address;
      size     : unsigned_32;
      task_id  : ewok.tasks_shared.t_task_id;
      mode     : ewok.tasks_shared.t_task_mode) return boolean
      with
         Global => null,
         -- there is now hypothesis on input values, yet we impose some
         -- specific behavior for various overflows
         Post  => (if (ptr + size not in system_address'range) then is_range_in_data_slot'Result = false);

   function is_range_in_txt_slot
     (ptr      : system_address;
      size     : unsigned_32;
      task_id  : ewok.tasks_shared.t_task_id) return boolean
      with
         Global => null,
         -- there is now hypothesis on input values, yet we impose some
         -- specific behavior for various overflows
         Post  => (if (ptr + size not in system_address'range) then is_range_in_txt_slot'Result = false);

   function is_range_in_any_slot
     (ptr      : system_address;
      size     : unsigned_32;
      task_id  : ewok.tasks_shared.t_task_id;
      mode     : ewok.tasks_shared.t_task_mode) return boolean
      with
         Global => null,
         -- there is now hypothesis on input values, yet we impose some
         -- specific behavior for various overflows
         Post  => (if (ptr + size not in system_address'range) then is_range_in_any_slot'Result = false);

   function is_range_in_dma_shm
     (ptr         : system_address;
      size        : unsigned_32;
      dma_access  : ewok.exported.dma.t_dma_shm_access;
      task_id     : ewok.tasks_shared.t_task_id) return boolean
      with
         Spark_Mode => off,
         Global     => null,
         -- there is now hypothesis on input values, yet we impose some
         -- specific behavior for various overflows
         Post       => (if (ptr + size not in system_address'range) then is_range_in_dma_shm'Result = false);

end ewok.sanitize;
