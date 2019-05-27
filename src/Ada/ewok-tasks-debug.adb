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

   procedure crashdump (frame_a : in ewok.t_stack_frame_access)
   is
   begin
      ewok.debug.log (ewok.debug.ERROR,
         "current task: " & ewok.tasks.tasks_list(ewok.sched.get_current).name);

      ewok.debug.log (ewok.debug.ERROR,
         "registers (frame at " &
         system_address'image (to_system_address (frame_a)) &
         ", EXC_RETURN " & unsigned_32'image (frame_a.all.exc_return) & ")");

      ewok.debug.log (ewok.debug.ERROR,
         "R0 " & unsigned_32'image (frame_a.all.R0) &
         ", R1 " & unsigned_32'image (frame_a.all.R1) &
         ", R2 " & unsigned_32'image (frame_a.all.R2) &
         ", R3 " & unsigned_32'image (frame_a.all.R3));

      ewok.debug.log (ewok.debug.ERROR,
         "R4 " & unsigned_32'image (frame_a.all.R4) &
         ", R5 " & unsigned_32'image (frame_a.all.R5) &
         ", R6 " & unsigned_32'image (frame_a.all.R6) &
         ", R7 " & unsigned_32'image (frame_a.all.R7));

      ewok.debug.log (ewok.debug.ERROR,
         "R8 " & unsigned_32'image (frame_a.all.R8) &
         ", R9 " & unsigned_32'image (frame_a.all.R9) &
         ", R10 " & unsigned_32'image (frame_a.all.R10) &
         ", R11 " & unsigned_32'image (frame_a.all.R11));

      ewok.debug.log (ewok.debug.ERROR,
         "R12 " & unsigned_32'image (frame_a.all.R12) &
         ", PC " & unsigned_32'image (frame_a.all.PC) &
         ", LR " & unsigned_32'image (frame_a.all.LR));

      ewok.debug.log (ewok.debug.ERROR,
         "PSR " & unsigned_32'image (m4.cpu.to_unsigned_32 (frame_a.all.PSR)));

   end crashdump;

end ewok.tasks.debug;
