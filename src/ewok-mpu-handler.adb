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
with ewok.tasks.debug;
with ewok.tasks_shared;    use ewok.tasks_shared;
with ewok.devices_shared;  use ewok.devices_shared;
with ewok.sched;
with ewok.debug;
with ewok.interrupts;
with soc.interrupts;
with m4.scb;

package body ewok.mpu.handler
   with spark_mode => off
is

   function memory_fault_handler
     (frame_a : t_stack_frame_access)
      return t_stack_frame_access
   is

#if not CONFIG_KERNEL_PANIC_FREEZE
      new_frame_a : t_stack_frame_access
#end if;

   begin

      if m4.scb.SCB.CFSR.MMFSR.MMARVALID then
         pragma DEBUG (debug.log (debug.ERROR,
            "MPU: MMFAR.ADDRESS = " &
            system_address'image (m4.scb.SCB.MMFAR.ADDRESS)));
      end if;

      if m4.scb.SCB.CFSR.MMFSR.MLSPERR then
         pragma DEBUG (debug.log (debug.ERROR,
            "MPU: MemManage fault during floating-point lazy state preservation"));
      end if;

      if m4.scb.SCB.CFSR.MMFSR.MSTKERR then
         pragma DEBUG (debug.log (debug.ERROR,
            "MPU: stacking for an exception entry has caused access violation"));
      end if;

      if m4.scb.SCB.CFSR.MMFSR.MUNSTKERR then
         pragma DEBUG (debug.log (debug.ERROR,
            "MPU: unstack for an exception return has caused access violation"));
      end if;

      if m4.scb.SCB.CFSR.MMFSR.DACCVIOL then
         pragma DEBUG (debug.log (debug.ERROR,
            "MPU: the processor attempted a load or store at a location that does not permit the operation"));
      end if;

      if m4.scb.SCB.CFSR.MMFSR.IACCVIOL then
         pragma DEBUG (debug.log (debug.ERROR,
            "MPU: the processor attempted an instruction fetch from a location that does not permit execution"));
      end if;

      pragma DEBUG (ewok.tasks.debug.crashdump (frame_a));

      -- On memory fault, the task is not scheduled anymore
      ewok.tasks.set_state
        (ewok.sched.get_current, TASK_MODE_MAINTHREAD, ewok.tasks.TASK_STATE_FAULT);

#if CONFIG_KERNEL_PANIC_FREEZE
      debug.panic ("Memory fault!");
      return frame_a;
#else
      new_frame_a := ewok.sched.do_schedule (frame_a);
      return new_frame_a;
#end if;

   end memory_fault_handler;


   procedure init
   is
      ok : boolean;
   begin
      ewok.interrupts.set_task_switching_handler
        (soc.interrupts.INT_MEMMANAGE,
         memory_fault_handler'access,
         ID_KERNEL,
         ID_DEV_UNUSED,
         ok);
      if not ok then raise program_error; end if;
   end init;


end ewok.mpu.handler;
