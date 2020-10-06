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

with system.machine_code;

with m4.systick;
with soc.interrupts;       use soc.interrupts;
with ewok.debug;
with ewok.tasks;           use ewok.tasks;
with ewok.tasks.debug;
with ewok.sched;
with ewok.tasks_shared;    use ewok.tasks_shared;
with ewok.devices_shared;  use type ewok.devices_shared.t_device_id;
with ewok.isr;


package body ewok.interrupts.handler
   with spark_mode => off
is

   function busfault_handler
     (frame_a : ewok.t_stack_frame_access) return ewok.t_stack_frame_access
   is
   begin
      pragma DEBUG (ewok.tasks.debug.crashdump (frame_a));
      debug.panic ("Bus fault!");
      return frame_a;
   end busfault_handler;


   function usagefault_handler
     (frame_a : ewok.t_stack_frame_access) return ewok.t_stack_frame_access
   is
   begin
      pragma DEBUG (ewok.tasks.debug.crashdump (frame_a));
      debug.panic ("Usage fault!");
      return frame_a;
   end usagefault_handler;


   function hardfault_handler
     (frame_a : ewok.t_stack_frame_access) return ewok.t_stack_frame_access
   is
   begin
      pragma DEBUG (ewok.tasks.debug.crashdump (frame_a));
      debug.panic ("Hard fault!");
      return frame_a;
   end hardfault_handler;


   function systick_default_handler
     (frame_a : ewok.t_stack_frame_access)
      return ewok.t_stack_frame_access
   is
   begin
      m4.systick.increment;
      return frame_a;
   end systick_default_handler;


   function default_sub_handler
     (frame_a : t_stack_frame_access)
      return t_stack_frame_access
   is
      it          : t_interrupt;
      new_frame_a : t_stack_frame_access;
      ttype       : t_task_type;
   begin

      it := soc.interrupts.get_interrupt;

      --
      -- Exceptions and interrupts (not nested)
      --
      if frame_a.all.exc_return = 16#FFFF_FFFD# then

         -- System exceptions
         if it < INT_WWDG then
            if interrupt_table(it).task_id = ewok.tasks_shared.ID_KERNEL then
               new_frame_a := interrupt_table(it).task_switch_handler (frame_a);
            else
               debug.panic ("Unhandled exception " & t_interrupt'image (it));
            end if;
         else
         -- External interrupts
            -- Execute kernel ISR
            if interrupt_table(it).task_id = ewok.tasks_shared.ID_KERNEL then
               interrupt_table(it).handler (frame_a);
               new_frame_a := frame_a;

            -- User ISR are postponed (asynchronous execution)
            elsif interrupt_table(it).task_id /= ewok.tasks_shared.ID_UNUSED then
               ewok.isr.postpone_isr
                 (it,
                  interrupt_table(it).handler,
                  interrupt_table(it).task_id);
               new_frame_a := ewok.sched.do_schedule (frame_a);
            else
               pragma DEBUG (debug.log (debug.ALERT,
                  "Unhandled interrupt " & t_interrupt'image (it)));
            end if;
         end if;

         -- Task's execution mode must be transmitted to the Default_Handler
         -- to run it with the proper privilege (set in the CONTROL register).
         -- The current function uses R0 and R1 registers to return the
         -- following values:
         --    R0 - address of the task frame
         --    R1 - execution mode

         if ewok.sched.current_task_id /= ID_UNUSED then
            ttype := ewok.tasks.tasks_list(ewok.sched.current_task_id).ttype;
         else
            ttype := TASK_TYPE_KERNEL;
         end if;

         system.machine_code.asm
           ("mov r1, %0",
            inputs   => t_task_type'asm_input ("r", ttype),
            clobber  => "r1",
            volatile => true);

         return new_frame_a;

      --
      -- Nested exceptions
      --
      elsif frame_a.all.exc_return = 16#FFFF_FFF1# then
         -- System exceptions
         if it < INT_WWDG then
            case it is
               when INT_PENDSV  => debug.panic ("Nested PendSV not handled.");
               when INT_SYSTICK => null;
               when others      =>
                  if interrupt_table(it).task_id = ewok.tasks_shared.ID_KERNEL then
                     new_frame_a :=
                        interrupt_table(it).task_switch_handler (frame_a);
                  else
                     debug.panic
                       ("Unhandled exception " & t_interrupt'image (it));
                  end if;
            end case;

         else
         -- External interrupts
            -- Execute kernel ISR
            if interrupt_table(it).task_id = ewok.tasks_shared.ID_KERNEL then
               interrupt_table(it).handler (frame_a);

            -- User ISR are postponed (asynchronous execution)
            elsif interrupt_table(it).task_id /= ewok.tasks_shared.ID_UNUSED then
               ewok.isr.postpone_isr
                 (it,
                  interrupt_table(it).handler,
                  interrupt_table(it).task_id);
            else
               pragma DEBUG (debug.log (debug.ALERT,
                  "Unhandled interrupt " & t_interrupt'image (it)));
            end if;

         end if;

         return frame_a;

      -- Privileged exceptions should never happen because threads never
      -- use the main stack (MSP) but the process stack (PSP).
      elsif frame_a.all.exc_return = 16#FFFF_FFF9# then
         debug.panic ("Privileged exception " & t_interrupt'image (it));
         raise program_error;

      -- Unsupported EXC_RETURN
      else
         debug.panic ("EXC_RETURN not supported");
         raise program_error;
      end if;

   end default_sub_handler;


end ewok.interrupts.handler;
