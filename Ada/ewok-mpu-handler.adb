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
with ewok.tasks;           use ewok.tasks;
with ewok.tasks_shared;    use ewok.tasks_shared;
with ewok.devices_shared;  use ewok.devices_shared;
with ewok.sched;
with ewok.interrupts;
with soc.interrupts;
with m4.scb;
with debug;

package body ewok.mpu.handler
   with spark_mode => off
is

   function memory_fault_handler
     (frame_a : t_stack_frame_access)
      return t_stack_frame_access
   is
      current  : ewok.tasks.t_task_access;
   begin

      if m4.scb.SCB.CFSR.MMFSR.MMARVALID then
         debug.log (debug.ERROR, "MPU error: MMFAR.ADDRESS = " &
            system_address'image (m4.scb.SCB.MMFAR.ADDRESS));
      end if;

      if m4.scb.SCB.CFSR.MMFSR.MLSPERR then
         debug.log (debug.ERROR, "MPU error: a MemManage fault occurred during floating-point lazy state preservation");
      end if;

      if m4.scb.SCB.CFSR.MMFSR.MSTKERR then
         debug.log (debug.ERROR, "MPU error: stacking for an exception entry has caused one or more access violation");
      end if;

      if m4.scb.SCB.CFSR.MMFSR.MUNSTKERR then
         debug.log (debug.ERROR, "MPU error: unstack for an exception return has caused one or more access violation");
      end if;

      if m4.scb.SCB.CFSR.MMFSR.DACCVIOL then
         debug.log (debug.ERROR, "MPU error: the processor attempted a load or store at a location that does not permit the operation");
      end if;

      if m4.scb.SCB.CFSR.MMFSR.IACCVIOL then
         debug.log (debug.ERROR, "MPU error: the processor attempted an instruction fetch from a location that does not permit execution");
      end if;

      current  := ewok.tasks.get_task(ewok.sched.get_current);

      if current = NULL then
         debug.panic ("MPU error: No current task.");
      end if;

      declare
      begin
         debug.log (debug.ERROR,
            "MPU error: task: " & current.all.name &
            ", id:"  & ewok.tasks_shared.t_task_id'image (current.all.id) &
            ", PC:"  & system_address'image (frame_a.all.PC));
      end;

      -- On memory fault, the task is not scheduled anymore
      ewok.tasks.set_state
         (current.all.id, TASK_MODE_MAINTHREAD, ewok.tasks.TASK_STATE_FAULT);

      -- FIXME
      -- Request schedule
      m4.scb.SCB.ICSR.PENDSVSET := 1;

      -- FIXME
      debug.panic("panic!");

      return frame_a;
   end memory_fault_handler;


   procedure init
   is
      ok : boolean;
   begin
      ewok.interrupts.set_task_switching_handler
        (soc.interrupts.INT_MEMMANAGE,
         memory_fault_handler'access,
         ID_UNUSED,
         ID_DEV_UNUSED,
         ok);
      if not ok then raise program_error; end if;
   end init;


end ewok.mpu.handler;
