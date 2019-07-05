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

with ewok.tasks_shared;
with ewok.interrupts;
with soc.interrupts;

package ewok.exported.interrupts
   with spark_mode => off
is

   MAX_POSTHOOK_INSTR  : constant := 10;

   type t_posthook_action is
     (POSTHOOK_NIL,
      POSTHOOK_READ,
      POSTHOOK_WRITE,
      POSTHOOK_WRITE_REG,     -- C name "and"
      POSTHOOK_WRITE_MASK);   -- C name "mask"

   -- value <- register
   type t_posthook_action_read is record
      offset   : unsigned_32;
      value    : unsigned_32;
   end record;

   -- register <- value & mask
   type t_posthook_action_write is record
      offset   : unsigned_32;
      value    : unsigned_32;
      mask     : unsigned_32;
   end record;

   -- register(dest) <- register(src) & mask
   type t_posthook_action_write_reg is record
      offset_dest : unsigned_32;
      offset_src  : unsigned_32;
      mask        : unsigned_32;
      mode        : unsigned_8;
   end record;

   -- register(dest) <- register(src) & register(mask)
   type t_posthook_action_write_mask is record
      offset_dest : unsigned_32;
      offset_src  : unsigned_32;
      offset_mask : unsigned_32;
      mode        : unsigned_8;
   end record;

   MODE_STANDARD  : constant := 0;
   MODE_NOT       : constant := 1;

   type t_posthook_instruction (instr : t_posthook_action := POSTHOOK_NIL) is
   record
      case instr is
         when POSTHOOK_NIL    =>
            null;
         when POSTHOOK_READ   =>
            read        : t_posthook_action_read;
         when POSTHOOK_WRITE  =>
            write       : t_posthook_action_write;
         when POSTHOOK_WRITE_REG =>
            write_reg   : t_posthook_action_write_reg;
         when POSTHOOK_WRITE_MASK   =>
            write_mask  : t_posthook_action_write_mask;
      end case;
   end record;

   -- number of posthooks
   subtype t_posthook_instruction_number is
      integer range 1 .. MAX_POSTHOOK_INSTR;

   -- array of posthooks
   type t_posthook_instruction_list is
      array (t_posthook_instruction_number'range) of t_posthook_instruction;

   type t_interrupt_posthook is record
      action      : t_posthook_instruction_list; -- Reading, writing, masking...
      status      : unsigned_32;
      data        : unsigned_32;
   end record;

   type t_interrupt_config is record
      handler     : ewok.interrupts.t_interrupt_handler_access := NULL;
      interrupt   : soc.interrupts.t_interrupt                 := soc.interrupts.INT_NONE;
      mode        : ewok.tasks_shared.t_scheduling_post_isr;
      posthook    : t_interrupt_posthook;
   end record;

   type t_interrupt_config_access is access all t_interrupt_config;

end ewok.exported.interrupts;
