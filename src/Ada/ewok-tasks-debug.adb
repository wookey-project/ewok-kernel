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

with ewok.debug;
with ewok.sched;
with ewok.tasks;

package body ewok.tasks.debug
   with spark_mode => off
is

   package DBG renames ewok.debug;

   procedure crashdump (frame_a : in ewok.t_stack_frame_access)
   is
   begin
      DBG.log (DBG.ERROR, ewok.tasks.tasks_list(ewok.sched.get_current).name);

      DBG.alert ("Frame ");
      DBG.alert (system_address'image (to_system_address (frame_a)));
      DBG.newline;

      DBG.alert ("EXC_RETURN ");
      DBG.alert (unsigned_32'image (frame_a.all.exc_return));
      DBG.newline;

      DBG.alert ("R0  "); DBG.alert (unsigned_32'image (frame_a.all.R0)); DBG.newline;
      DBG.alert ("R1  "); DBG.alert (unsigned_32'image (frame_a.all.R1)); DBG.newline;
      DBG.alert ("R2  "); DBG.alert (unsigned_32'image (frame_a.all.R2)); DBG.newline;
      DBG.alert ("R3  "); DBG.alert (unsigned_32'image (frame_a.all.R3)); DBG.newline;
      DBG.alert ("R4  "); DBG.alert (unsigned_32'image (frame_a.all.R4)); DBG.newline;
      DBG.alert ("R5  "); DBG.alert (unsigned_32'image (frame_a.all.R5)); DBG.newline;
      DBG.alert ("R6  "); DBG.alert (unsigned_32'image (frame_a.all.R6)); DBG.newline;
      DBG.alert ("R7  "); DBG.alert (unsigned_32'image (frame_a.all.R7)); DBG.newline;
      DBG.alert ("R8  "); DBG.alert (unsigned_32'image (frame_a.all.R8)); DBG.newline;
      DBG.alert ("R9  "); DBG.alert (unsigned_32'image (frame_a.all.R9)); DBG.newline;
      DBG.alert ("R10 "); DBG.alert (unsigned_32'image (frame_a.all.R10)); DBG.newline;
      DBG.alert ("R11 "); DBG.alert (unsigned_32'image (frame_a.all.R11)); DBG.newline;
      DBG.alert ("R12 "); DBG.alert (unsigned_32'image (frame_a.all.R12)); DBG.newline;

      DBG.alert ("PC  "); DBG.alert (unsigned_32'image (frame_a.all.PC)); DBG.newline;
      DBG.alert ("LR  "); DBG.alert (unsigned_32'image (frame_a.all.LR)); DBG.newline;
      DBG.alert ("PSR ");
      DBG.alert (unsigned_32'image (m4.cpu.to_unsigned_32 (frame_a.all.PSR)));
      DBG.newline;

   end crashdump;

end ewok.tasks.debug;
