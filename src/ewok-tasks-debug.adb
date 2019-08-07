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
with m4.scb;

package body ewok.tasks.debug
   with spark_mode => off
is

   package DBG renames ewok.debug;

   procedure crashdump (frame_a : in ewok.t_stack_frame_access)
   is
      cfsr : constant m4.scb.t_SCB_CFSR := m4.scb.SCB.CFSR;
   begin

      if cfsr.MMFSR.IACCVIOL  then pragma DEBUG (DBG.log (DBG.ERROR, "+cfsr.MMFSR.IACCVIOL")); end if;
      if cfsr.MMFSR.DACCVIOL  then pragma DEBUG (DBG.log (DBG.ERROR, "+cfsr.MMFSR.DACCVIOL")); end if;
      if cfsr.MMFSR.MUNSTKERR then pragma DEBUG (DBG.log (DBG.ERROR, "+cfsr.MMFSR.MUNSTKERR")); end if;
      if cfsr.MMFSR.MSTKERR   then pragma DEBUG (DBG.log (DBG.ERROR, "+cfsr.MMFSR.MSTKERR")); end if;
      if cfsr.MMFSR.MLSPERR   then pragma DEBUG (DBG.log (DBG.ERROR, "+cfsr.MMFSR.MLSPERR")); end if;
      if cfsr.MMFSR.MMARVALID then pragma DEBUG (DBG.log (DBG.ERROR, "+cfsr.MMFSR.MMARVALID")); end if;
      if cfsr.MMFSR.MMARVALID then
         pragma DEBUG (DBG.log (DBG.ERROR, "MMFAR.ADDRESS = " &
            system_address'image (m4.scb.SCB.MMFAR.ADDRESS)));
      end if;

      if cfsr.BFSR.IBUSERR    then pragma DEBUG (DBG.log (DBG.ERROR, "+cfsr.BFSR.IBUSERR")); end if;
      if cfsr.BFSR.PRECISERR  then pragma DEBUG (DBG.log (DBG.ERROR, "+cfsr.BFSR.PRECISERR")); end if;
      if cfsr.BFSR.IMPRECISERR then pragma DEBUG (DBG.log (DBG.ERROR, "+cfsr.BFSR.IMPRECISERR")); end if;
      if cfsr.BFSR.UNSTKERR   then pragma DEBUG (DBG.log (DBG.ERROR, "+cfsr.BFSR.UNSTKERR")); end if;
      if cfsr.BFSR.STKERR     then pragma DEBUG (DBG.log (DBG.ERROR, "+cfsr.BFSR.STKERR")); end if;
      if cfsr.BFSR.LSPERR     then pragma DEBUG (DBG.log (DBG.ERROR, "+cfsr.BFSR.LSPERR")); end if;
      if cfsr.BFSR.BFARVALID  then pragma DEBUG (DBG.log (DBG.ERROR, "+cfsr.BFSR.BFARVALID")); end if;
      if cfsr.BFSR.BFARVALID  then
         pragma DEBUG (DBG.log (DBG.ERROR, "BFAR.ADDRESS = " &
            system_address'image (m4.scb.SCB.BFAR.ADDRESS)));
      end if;

      if cfsr.UFSR.UNDEFINSTR then pragma DEBUG (DBG.log (DBG.ERROR, "+cfsr.UFSR.UNDEFINSTR")); end if;
      if cfsr.UFSR.INVSTATE   then pragma DEBUG (DBG.log (DBG.ERROR, "+cfsr.UFSR.INVSTATE")); end if;
      if cfsr.UFSR.INVPC      then pragma DEBUG (DBG.log (DBG.ERROR, "+cfsr.UFSR.INVPC")); end if;
      if cfsr.UFSR.NOCP       then pragma DEBUG (DBG.log (DBG.ERROR, "+cfsr.UFSR.NOCP")); end if;
      if cfsr.UFSR.UNALIGNED  then pragma DEBUG (DBG.log (DBG.ERROR, "+cfsr.UFSR.UNALIGNED")); end if;
      if cfsr.UFSR.DIVBYZERO  then pragma DEBUG (DBG.log (DBG.ERROR, "+cfsr.UFSR.DIVBYZERO")); end if;

      DBG.log (DBG.ERROR, ewok.tasks.tasks_list(ewok.sched.current_task_id).name);

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
