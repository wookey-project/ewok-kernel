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

with ewok.tasks;  use ewok.tasks;
with ewok.tasks_shared; use ewok.tasks_shared;
with ewok.sched;
with ewok.softirq;
with ewok.syscalls.dma;
with ewok.syscalls.yield;
with ewok.syscalls.reset;
with ewok.syscalls.sleep;
with ewok.syscalls.gettick;
with ewok.syscalls.lock;
with ewok.syscalls.rng;
with ewok.syscalls.cfg.dev;
with ewok.syscalls.cfg.gpio;
with ewok.exported.interrupts;
   use type ewok.exported.interrupts.t_interrupt_config_access;
with applications;
with m4.cpu.instructions;
with debug;

package body ewok.syscalls.handler
   with spark_mode => off
is

   type t_syscall_parameters_access is access all t_syscall_parameters;
   function to_syscall_parameters_access is new ada.unchecked_conversion
     (system_address, t_syscall_parameters_access);


   function is_synchronous_syscall
     (sys_params_a   : t_syscall_parameters_access)
      return boolean
   is
   begin
      if sys_params_a.all.syscall_type = SYS_IPC or
         sys_params_a.all.syscall_type = SYS_INIT
      then
         return false;
      else
         return true;
      end if;
   end is_synchronous_syscall;


   procedure exec_synchronous_syscall
     (current_id     : in  ewok.tasks_shared.t_task_id;
      mode           : in  ewok.tasks_shared.t_task_mode;
      sys_params_a   : in  t_syscall_parameters_access)
   is
   begin

      case sys_params_a.all.syscall_type is
         when SYS_GETTICK  =>
            ewok.syscalls.gettick.sys_gettick
              (current_id,
               sys_params_a.all.args, mode);

         when SYS_YIELD    =>
            ewok.syscalls.yield.sys_yield (current_id, mode);

         when SYS_CFG      =>
            declare
               syscall : t_syscalls_cfg
                  with address => sys_params_a.all.args(0)'address;
            begin
               case syscall is
                  when CFG_GPIO_SET    =>
                     ewok.syscalls.cfg.gpio.gpio_set (current_id,
                        sys_params_a.all.args, mode);

                  when CFG_GPIO_GET    =>
                     ewok.syscalls.cfg.gpio.gpio_get (current_id,
                        sys_params_a.all.args, mode);

                  when CFG_GPIO_UNLOCK_EXTI =>
                     ewok.syscalls.cfg.gpio.gpio_unlock_exti (current_id,
                        sys_params_a.all.args, mode);

                  when CFG_DMA_RECONF  =>
                     ewok.syscalls.dma.sys_cfg_dma_reconf (current_id,
                        sys_params_a.all.args, mode);

                  when CFG_DMA_RELOAD  =>
                     ewok.syscalls.dma.sys_cfg_dma_reload (current_id,
                        sys_params_a.all.args, mode);

                  when CFG_DMA_DISABLE =>
                     ewok.syscalls.dma.sys_cfg_dma_disable (current_id,
                        sys_params_a.all.args, mode);

                  when CFG_DEV_MAP     =>
                     ewok.syscalls.cfg.dev.dev_map (current_id,
                        sys_params_a.all.args, mode);

                  when CFG_DEV_UNMAP   =>
                     ewok.syscalls.cfg.dev.dev_unmap (current_id,
                        sys_params_a.all.args, mode);

                  when CFG_DEV_RELEASE =>
                     ewok.syscalls.cfg.dev.dev_release (current_id,
                        sys_params_a.all.args, mode);
               end case;
            end;

         when SYS_SLEEP    =>
            ewok.syscalls.sleep.sys_sleep
              (current_id, sys_params_a.all.args, mode);

         when SYS_LOCK     =>
            ewok.syscalls.lock.sys_lock
              (current_id, sys_params_a.all.args, mode);

         when SYS_GET_RANDOM =>
            ewok.syscalls.rng.sys_get_random
              (current_id, sys_params_a.all.args, mode);

         when SYS_RESET    =>
            ewok.syscalls.reset.sys_reset
              (current_id, mode);

         when SYS_INIT     => raise program_error;
         when SYS_IPC      => raise program_error;

      end case;

   end exec_synchronous_syscall;


   function svc_handler
     (frame_a : t_stack_frame_access)
      return t_stack_frame_access
   is

      svc            : t_svc_type;
      sys_params_a   : t_syscall_parameters_access;
      current_a      : ewok.tasks.t_task_access;
      current_id     : t_task_id;

#if CONFIG_SCHED_SUPPORT_FISR
      fast_isr    : constant boolean := true;
#else
      fast_isr    : constant boolean := false;
#end if;

   begin

      current_id  := ewok.sched.get_current;
      current_a   := ewok.tasks.get_task (current_id);

      -- FIXME
      -- When there are numerous SVC, it seems that SYSTICK might generate an
      -- improper tail-chaining with a priority inversion resulting in SVC
      -- beeing handled after SYSTICK.
      if current_id not in applications.list'range then
         debug.log ("<spurious>");
         raise program_error;
      end if;

      --
      -- We must save the frame pointer because synchronous syscall don't refer
      -- to the parameters on the stack indexed by 'frame_a' but to
      -- 'current_a' (they access 'frame_a' via 'current_a.all.ctx.frame_a'
      -- or 'current_a.all.isr_ctx.frame_a')
      --

      if ewok.tasks.get_mode (current_id) = TASK_MODE_MAINTHREAD then
         current_a.all.ctx.frame_a := frame_a;
      else
         current_a.all.isr_ctx.frame_a := frame_a;
      end if;

      --
      -- Getting the svc number from the SVC instruction
      --

      declare
         inst : m4.cpu.instructions.t_svc_instruction
            with import, address => to_address (frame_a.all.PC - 2);
      begin
         if not inst.opcode'valid then
            raise program_error;
         end if;

         declare
            svc_type : t_svc_type with address => inst.svc_num'address;
         begin
            if not svc_type'valid then
               ewok.tasks.set_state
                 (current_id, TASK_MODE_MAINTHREAD, TASK_STATE_FAULT);
               set_return_value
                 (current_id, current_a.all.mode, SYS_E_DENIED);
               return frame_a;
            end if;
            svc := svc_type;
         end;
      end;

      --
      -- Managing SVCs
      --

      case svc is

         when SVC_SYSCALL     =>

            -- Extracting syscall parameters
            sys_params_a   := to_syscall_parameters_access (frame_a.all.R0);

            if not sys_params_a.all.syscall_type'valid then
               ewok.tasks.set_state
                 (current_id, TASK_MODE_MAINTHREAD, TASK_STATE_FAULT);
               set_return_value
                 (current_id, ewok.tasks.get_mode(current_id), SYS_E_DENIED);
            end if;

            -- ISR mode
            if current_a.all.mode = TASK_MODE_ISRTHREAD then
               -- Synchronous syscall
               if is_synchronous_syscall (sys_params_a) then
                  exec_synchronous_syscall
                    (current_id, current_a.all.mode, sys_params_a);
               else
                  set_return_value
                    (current_id, TASK_MODE_ISRTHREAD, SYS_E_DENIED);
               end if;
            else
            -- Main thread
               -- Synchronous syscall
               if is_synchronous_syscall (sys_params_a) then
                  exec_synchronous_syscall
                    (current_id, current_a.all.mode, sys_params_a);
               else
               -- Postponed syscall
                  ewok.softirq.push_syscall (current_id);
                  ewok.tasks.set_state (current_id, TASK_MODE_MAINTHREAD,
                     TASK_STATE_SVC_BLOCKED);
                  return ewok.sched.do_schedule (frame_a);
               end if;

            end if;

         when SVC_TASK_DONE   =>
            ewok.tasks.set_state
              (current_id, TASK_MODE_MAINTHREAD, TASK_STATE_FINISHED);

            return ewok.sched.do_schedule (frame_a);

         when SVC_ISR_DONE    =>

            if fast_isr and
               current_a.all.isr_ctx.sched_policy = ISR_FORCE_MAINTHREAD
            then
               declare
                  current_state : constant t_task_state :=
                     ewok.tasks.get_state (current_id, TASK_MODE_MAINTHREAD);
               begin
                  if current_state = TASK_STATE_RUNNABLE or
                     current_state = TASK_STATE_IDLE
                  then
                     ewok.tasks.set_state
                       (current_id, TASK_MODE_MAINTHREAD, TASK_STATE_FORCED);
                  end if;
               end;
            end if;

            ewok.tasks.set_state
              (current_id, TASK_MODE_ISRTHREAD, TASK_STATE_ISR_DONE);

            return ewok.sched.do_schedule (frame_a);

      end case;

      return frame_a;

   end svc_handler;


end ewok.syscalls.handler;
