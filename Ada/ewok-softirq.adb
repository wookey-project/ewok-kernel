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
with ewok.devices;
with ewok.exported.interrupts;
   use type ewok.exported.interrupts.t_interrupt_config_access;
with ewok.interrupts;
with ewok.layout;
with ewok.sched;
with ewok.syscalls.init;
with ewok.syscalls.cfg;
with ewok.syscalls.gettick;
with ewok.syscalls.ipc;
with ewok.syscalls.lock;
with ewok.syscalls.reset;
with ewok.syscalls.sleep;
with ewok.syscalls.yield;
with ewok.syscalls.rng;
with soc.interrupts; use type soc.interrupts.t_interrupt;
with soc.nvic;
with m4.cpu;
with m4.cpu.instructions;
with debug;

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
      debug.log
        (debug.INFO,
         "SOFTIRQ initialized");
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
         debug.panic ("ewok.softirq.push_isr() failed. "
            & p_isr_requests.ring_state'image
                 (p_isr_requests.state (isr_queue)));
      end if;
      ewok.tasks.set_state
        (ID_SOFTIRQ, TASK_MODE_MAINTHREAD, TASK_STATE_RUNNABLE);
   end push_isr;


   procedure push_syscall
     (task_id     : in  ewok.tasks_shared.t_task_id)
   is
      req   : constant t_syscall_request := (task_id, WAITING);
      ok    : boolean;
   begin
      p_syscall_requests.write (syscall_queue, req, ok);
      if not ok then
         debug.panic ("ewok.softirq.push_syscall() failed. "
            & p_syscall_requests.ring_state'image
                 (p_syscall_requests.state (syscall_queue)));
      end if;
      ewok.tasks.set_state
        (ID_SOFTIRQ, TASK_MODE_MAINTHREAD, TASK_STATE_RUNNABLE);
   end push_syscall;


   procedure syscall_handler (req : in  t_syscall_request)
   is

      type t_syscall_parameters_access is access all t_syscall_parameters;

      function to_syscall_parameters_access is new ada.unchecked_conversion
        (system_address, t_syscall_parameters_access);

      svc      : t_svc_type;
      params_a : t_syscall_parameters_access;
   begin

      --
      -- Getting the svc number from the SVC instruction
      --

      declare
         PC : constant system_address :=
            TSK.tasks_list(req.caller_id).ctx.frame_a.all.PC;
         inst : m4.cpu.instructions.t_svc_instruction
            with import, address => to_address (PC - 2);
      begin
         if not inst.opcode'valid then
            raise program_error;
         end if;

         declare
            svc_type : t_svc_type with address => inst.svc_num'address;
            val      : unsigned_8 with address => inst.svc_num'address;
         begin
            if not svc_type'valid then
               debug.log (debug.ERROR, "invalid SVC: "
                  & unsigned_8'image (val));
               ewok.tasks.set_state
                 (req.caller_id, TASK_MODE_MAINTHREAD, TASK_STATE_FAULT);
               set_return_value
                 (req.caller_id, TSK.tasks_list(req.caller_id).mode, SYS_E_DENIED);
               return;
            end if;
            svc := svc_type;
         end;
      end;

      --
      -- Getting syscall parameters
      --

      params_a :=
         to_syscall_parameters_access (TSK.tasks_list(req.caller_id).ctx.frame_a.all.R0);

      if params_a = NULL then
         debug.log (debug.ERROR, "(task"
            & ewok.tasks_shared.t_task_id'image (req.caller_id)
            & ") syscall with no parameters");
         return;
      end if;

      if not params_a.all.syscall_type'valid then
         debug.log (debug.ERROR, "(task"
            & ewok.tasks_shared.t_task_id'image (req.caller_id)
            & ") unknown syscall" &
            ewok.syscalls.t_syscall_type'image (params_a.all.syscall_type));
         return;
      end if;

      --
      -- Logging
      --

#if CONFIG_DBGLEVEL >= 7
      declare
         len  : constant natural := types.c.len (TSK.tasks_list(req.caller_id).name.all);
         name : string (1 .. len);
      begin
         to_ada (name, TSK.tasks_list(req.caller_id).name.all);
         debug.log (debug.INFO, "[" & name & "] svc"
            & ewok.syscalls.t_svc_type'image (svc)
            & ", syscall" & ewok.syscalls.t_syscall_type'image
            (params_a.all.syscall_type));
      end;
#end if;

      --
      -- Calling the handler
      --

      if svc /= SVC_SYSCALL then
         debug.panic ("ewok.softirq.syscall_handler(): wrong SVC"
            & ewok.syscalls.t_svc_type'image (svc));
      end if;

      case params_a.all.syscall_type is
         when SYS_YIELD      =>
            ewok.syscalls.yield.sys_yield (req.caller_id, TASK_MODE_MAINTHREAD);
         when SYS_INIT       =>
            ewok.syscalls.init.sys_init
              (req.caller_id, params_a.all.args, TASK_MODE_MAINTHREAD);
         when SYS_IPC        =>
            ewok.syscalls.ipc.sys_ipc
              (req.caller_id, params_a.all.args, TASK_MODE_MAINTHREAD);
         when SYS_CFG        =>
            ewok.syscalls.cfg.sys_cfg
              (req.caller_id, params_a.all.args, TASK_MODE_MAINTHREAD);
         when SYS_GETTICK    =>
            ewok.syscalls.gettick.sys_gettick
              (req.caller_id, params_a.all.args, TASK_MODE_MAINTHREAD);
         when SYS_RESET      =>
            ewok.syscalls.reset.sys_reset
              (req.caller_id, TASK_MODE_MAINTHREAD);
         when SYS_SLEEP      =>
            ewok.syscalls.sleep.sys_sleep
              (req.caller_id, params_a.all.args, TASK_MODE_MAINTHREAD);
         when SYS_LOCK       =>
            ewok.syscalls.lock.sys_lock
              (req.caller_id, params_a.all.args, TASK_MODE_MAINTHREAD);
         when SYS_GET_RANDOM =>
            ewok.syscalls.rng.sys_get_random
              (req.caller_id, params_a.all.args, TASK_MODE_MAINTHREAD);
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
      params(0) := req.params.handler;

      -- IRQ
      params(1) := unsigned_32'val
        (soc.nvic.to_irq_number (req.params.interrupt));

      -- Status and data returned by the 'posthook' treatement
      -- (cf. ewok.posthook.exec)
      params(2) := req.params.posthook_status;
      params(3) := req.params.posthook_data;

      create_stack
        (ewok.layout.STACK_TOP_TASK_ISR,
         TSK.tasks_list(req.caller_id).isr_ctx.entry_point, -- Wrapper
         params,
         TSK.tasks_list(req.caller_id).isr_ctx.frame_a);

      TSK.tasks_list(req.caller_id).mode := TASK_MODE_ISRTHREAD;
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
                  m4.cpu.enable_irq;
                  ewok.sched.request_schedule;
                  m4.cpu.instructions.full_memory_barrier;
               else
                  m4.cpu.disable_irq;
                  p_isr_requests.write (isr_queue, isr_req, ok);
                  if not ok then
                     debug.panic
                       ("softirq.main_task() failed to add ISR request");
                  end if;
                  m4.cpu.enable_irq;
                  ewok.sched.request_schedule;
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
