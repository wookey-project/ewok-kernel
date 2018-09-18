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
with soc.interrupts;
with ewok.tasks_shared;
with ewok.devices_shared;

package ewok.interrupts
   with spark_mode => off
is

   type t_interrupt_handler_access is access
      procedure (frame_a : in ewok.t_stack_frame_access);

   type t_interrupt_task_switch_handler_access is access
      function (frame_a : ewok.t_stack_frame_access)
         return ewok.t_stack_frame_access;

   type t_handler_type is (DEFAULT_HANDLER, TASK_SWITCH_HANDLER);

   type t_interrupt_cell (htype : t_handler_type := DEFAULT_HANDLER) is record
      task_id     : ewok.tasks_shared.t_task_id;
      device_id   : ewok.devices_shared.t_device_id;
      count       : unsigned_32;

      case htype is
         when DEFAULT_HANDLER       =>
            handler  : t_interrupt_handler_access;
         when TASK_SWITCH_HANDLER   =>
            task_switch_handler  : t_interrupt_task_switch_handler_access;
      end case;

   end record;

   type t_interrupt_cell_access is access all t_interrupt_cell;

   interrupt_table : array (soc.interrupts.t_interrupt) of aliased t_interrupt_cell;


   function to_system_address is new ada.unchecked_conversion
     (t_interrupt_handler_access, system_address);

   function to_handler_access is new ada.unchecked_conversion
     (system_address, t_interrupt_handler_access);

   procedure init;

   function is_interrupt_already_used
     (interrupt : soc.interrupts.t_interrupt) return boolean;

   procedure set_interrupt_handler
     (interrupt   : in  soc.interrupts.t_interrupt;
      handler     : in  t_interrupt_handler_access;
      task_id     : in  ewok.tasks_shared.t_task_id;
      device_id   : in  ewok.devices_shared.t_device_id;
      success     : out boolean);

   procedure set_task_switching_handler
     (interrupt   : in  soc.interrupts.t_interrupt;
      handler     : in  t_interrupt_task_switch_handler_access;
      task_id     : in  ewok.tasks_shared.t_task_id;
      device_id   : in  ewok.devices_shared.t_device_id;
      success     : out boolean);

   function get_device_from_interrupt
     (interrupt : soc.interrupts.t_interrupt)
      return ewok.devices_shared.t_device_id;

end ewok.interrupts;
