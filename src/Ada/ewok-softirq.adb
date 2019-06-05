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


with ewok.syscalls;     use ewok.syscalls;
with ewok.tasks;        use ewok.tasks;
with ewok.debug;
with ewok.devices;
with ewok.exported.interrupts;
   use type ewok.exported.interrupts.t_interrupt_config_access;
with ewok.interrupts;
with ewok.layout;
with ewok.sched;
with ewok.syscalls.log;
with soc.interrupts; use type soc.interrupts.t_interrupt;
with soc.nvic;
with m4.cpu;
with m4.cpu.instructions;

#if CONFIG_DBGLEVEL >= 7
with types.c; use types.c;
#end if;

package body ewok.softirq
  with spark_mode => off
is

   package TSK renames ewok.tasks;


   procedure init
   is
   begin
      p_isr_requests.init (isr_queue);
      p_syscall_requests.init (syscall_queue);
      pragma DEBUG (debug.log (debug.INFO, "SOFTIRQ initialized"));
   end init;


   procedure push_isr
     (task_id     : in  ewok.tasks_shared.t_task_id;
      params      : in  t_isr_parameters)
   is
      req   : constant t_isr_request := (task_id, WAITING, params);
      ok    : boolean;
   begin
      p_isr_requests.write (isr_queue, req, ok);
      if not ok then
         debug.panic ("push_isr() failed.");
      end if;
      ewok.tasks.set_state
        (ID_SOFTIRQ, TASK_MODE_MAINTHREAD, TASK_STATE_RUNNABLE);
   end push_isr;


   procedure push_syscall
     (task_id     : in  ewok.tasks_shared.t_task_id;
      svc         : in  ewok.syscalls.t_svc)
   is
      req   : constant t_syscall_request := (task_id, svc, WAITING);
      ok    : boolean;
   begin
      p_syscall_requests.write (syscall_queue, req, ok);
      if not ok then
         debug.panic ("push_syscall() failed.");
      end if;
      ewok.tasks.set_state
        (ID_SOFTIRQ, TASK_MODE_MAINTHREAD, TASK_STATE_RUNNABLE);
   end push_syscall;


   procedure syscall_handler (req : in  t_syscall_request)
   is
      svc_params_a : constant t_parameters_access :=
         to_parameters_access
           (TSK.tasks_list(req.caller_id).ctx.frame_a.all.R0);
   begin

      --
      -- Logging
      --

#if CONFIG_DBGLEVEL >= 7
      declare
         len  : constant natural := types.c.len (TSK.tasks_list(req.caller_id).name.all);
         name : string (1 .. len);
      begin
         to_ada (name, TSK.tasks_list(req.caller_id).name.all);
         debug.log (debug.INFO, name & ": svc"
            & ewok.syscalls.t_svc'image (svc));
      end;
#end if;

      --
      -- Calling the handler
      --

      case req.svc is
         when SVC_LOG =>
            ewok.syscalls.log.svc_log
              (req.caller_id, svc_params_a.all, TASK_MODE_MAINTHREAD);
         when others =>
            raise program_error;
      end case;

   end syscall_handler;


   procedure isr_handler (req : in  t_isr_request)
   is
      params   : t_parameters;
      config_a : ewok.exported.interrupts.t_interrupt_config_access;
   begin

      -- For further MPU mapping of the device, we need to know which device
      -- triggered that interrupt.
      -- Note
      --  - EXTIs are not associated to any device because they can be
      --    associated to several GPIO pins
      --  - DMAs are not considered as devices because a single controller
      --    can be used by several drivers. DMA streams are registered in a
      --    specific table

      TSK.tasks_list(req.caller_id).isr_ctx.device_id :=
         ewok.interrupts.get_device_from_interrupt (req.params.interrupt);

      -- Keep track of some hint about scheduling policy to apply after the end
      -- of the ISR execution
      -- Note - see above

      config_a :=
         ewok.devices.get_interrupt_config_from_interrupt (req.params.interrupt);

      if config_a /= NULL then
         TSK.tasks_list(req.caller_id).isr_ctx.sched_policy := config_a.all.mode;
      else
         TSK.tasks_list(req.caller_id).isr_ctx.sched_policy := ISR_STANDARD;
      end if;

      -- Zeroing the ISR stack if the ISR previously executed belongs to
      -- another task
      if previous_isr_owner /= req.caller_id then
         declare
            stack : byte_array(1 .. ewok.layout.STACK_SIZE_TASK_ISR)
               with address => to_address (ewok.layout.STACK_BOTTOM_TASK_ISR);
         begin
            stack := (others => 0);
         end;

         previous_isr_owner := req.caller_id;
      end if;

      --
      -- Note - isr_ctx.entry_point is a wrapper. The real ISR entry
      -- point is defined in params(0)
      --

      -- User defined ISR handler
      params(1) := req.params.handler;

      -- IRQ
      params(2) := unsigned_32'val
        (soc.nvic.to_irq_number (req.params.interrupt));

      -- Status and data returned by the 'posthook' treatement
      -- (cf. ewok.posthook.exec)
      params(3) := req.params.posthook_status;
      params(4) := req.params.posthook_data;

      create_stack
        (ewok.layout.STACK_TOP_TASK_ISR,
         TSK.tasks_list(req.caller_id).isr_ctx.entry_point, -- Wrapper
         params,
         TSK.tasks_list(req.caller_id).isr_ctx.frame_a);

      ewok.tasks.set_mode (req.caller_id, TASK_MODE_ISRTHREAD);
      ewok.tasks.set_state
        (req.caller_id, TASK_MODE_ISRTHREAD, TASK_STATE_RUNNABLE);

   end isr_handler;


   procedure main_task
   is
      isr_req  : t_isr_request;
      sys_req  : t_syscall_request;
      ok       : boolean;
   begin

      loop

         --
         -- User ISRs
         --

         loop
            m4.cpu.disable_irq;
            p_isr_requests.read (isr_queue, isr_req, ok);
            m4.cpu.enable_irq;

            exit when not ok;

            if isr_req.state = WAITING then
               if TSK.tasks_list(isr_req.caller_id).state /= TASK_STATE_LOCKED and
                  TSK.tasks_list(isr_req.caller_id).state /= TASK_STATE_SLEEPING_DEEP
               then
                  m4.cpu.disable_irq;
                  isr_handler (isr_req);
                  isr_req.state := DONE;
                  ewok.sched.request_schedule;
                  m4.cpu.enable_irq;
                  m4.cpu.instructions.full_memory_barrier;
               else
                  m4.cpu.disable_irq;
                  p_isr_requests.write (isr_queue, isr_req, ok);
                  if not ok then
                     debug.panic ("SOFTIRQ failed to add ISR request");
                  end if;
                  ewok.sched.request_schedule;
                  m4.cpu.enable_irq;
                  m4.cpu.instructions.full_memory_barrier;
               end if;
            else
               raise program_error;
            end if;

         end loop;

         --
         -- Syscalls
         --

         loop

            m4.cpu.disable_irq;
            p_syscall_requests.read (syscall_queue, sys_req, ok);
            m4.cpu.enable_irq;

            exit when not ok;

            if sys_req.state = WAITING then
               syscall_handler (sys_req);
               sys_req.state := DONE;
            else
               raise program_error;
            end if;
         end loop;

         --
         -- Set softirq task as IDLE if there is no more request to handle
         --

         m4.cpu.disable_irq;

         if p_isr_requests.state (isr_queue) = p_isr_requests.EMPTY and
            p_syscall_requests.state (syscall_queue) = p_syscall_requests.EMPTY
         then
            ewok.tasks.set_state
              (ID_SOFTIRQ, TASK_MODE_MAINTHREAD, TASK_STATE_IDLE);
            m4.cpu.instructions.full_memory_barrier;
            ewok.sched.request_schedule;
         end if;

         m4.cpu.enable_irq;

      end loop;

   end main_task;


end ewok.softirq;
