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
with ewok.gpio;
with ewok.exported.gpios;
with ewok.sanitize;

package body ewok.syscalls.cfg.gpio
   with spark_mode => off
is

   procedure gpio_set
     (caller_id   : in     ewok.tasks_shared.t_task_id;
      params      : in out t_parameters;
      mode        : in     ewok.tasks_shared.t_task_mode)
   is

      ref   : ewok.exported.gpios.t_gpio_ref
         with address => params(1)'address;

      val   : unsigned_8
         with address => params(2)'address;

   begin

      -- Task initialization is complete ?
      if not is_init_done (caller_id) then
         goto ret_denied;
      end if;

      -- Valid t_gpio_ref ?
      if not ref.pin'valid or not ref.port'valid then
         goto ret_inval;
      end if;

      -- Does that GPIO really belongs to the caller ?
      if not ewok.gpio.belong_to (caller_id, ref) then
         goto ret_denied;
      end if;

      -- Write the pin
      if val >= 1 then
         ewok.gpio.write_pin (ref, 1);
      else
         ewok.gpio.write_pin (ref, 0);
      end if;

      set_return_value (caller_id, mode, SYS_E_DONE);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   <<ret_inval>>
      set_return_value (caller_id, mode, SYS_E_INVAL);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   <<ret_denied>>
      set_return_value (caller_id, mode, SYS_E_DENIED);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;
   end gpio_set;


   procedure gpio_get
     (caller_id   : in     ewok.tasks_shared.t_task_id;
      params      : in out t_parameters;
      mode        : in     ewok.tasks_shared.t_task_mode)
   is

      ref   : ewok.exported.gpios.t_gpio_ref
         with address => params(1)'address;

      val   : unsigned_8
         with address => to_address (params(2));

   begin

      -- Task initialization is complete ?
      if not is_init_done (caller_id) then
         goto ret_denied;
      end if;

      -- Valid t_gpio_ref ?
      if not ref.pin'valid or not ref.port'valid then
         goto ret_inval;
      end if;

      -- Does &val is in the caller address space ?
      if not ewok.sanitize.is_word_in_data_slot
               (to_system_address (val'address), caller_id, mode)
      then
         goto ret_denied;
      end if;

      -- Read the pin
      val := unsigned_8 (ewok.gpio.read_pin (ref));

      set_return_value (caller_id, mode, SYS_E_DONE);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   <<ret_inval>>
      set_return_value (caller_id, mode, SYS_E_INVAL);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   <<ret_denied>>
      set_return_value (caller_id, mode, SYS_E_DENIED);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;
   end gpio_get;

end ewok.syscalls.cfg.gpio;
