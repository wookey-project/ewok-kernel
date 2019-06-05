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
with ewok.syscalls.cfg.dev;
with ewok.syscalls.cfg.gpio;
with ewok.syscalls.dma;
with ewok.syscalls.gettick;
with ewok.syscalls.init;
with ewok.syscalls.ipc;
with ewok.syscalls.lock;
with ewok.syscalls.reset;
with ewok.syscalls.rng;
with ewok.syscalls.sleep;
with ewok.syscalls.yield;
with ewok.exported.interrupts;
   use type ewok.exported.interrupts.t_interrupt_config_access;
with m4.cpu.instructions;

package body ewok.syscalls.handler
   with spark_mode => off
is

   function svc_handler
     (frame_a : t_stack_frame_access)
      return t_stack_frame_access
   is
      svc            : t_svc;
      svc_params_a   : t_parameters_access;
      current_id     : t_task_id;
      current_a      : ewok.tasks.t_task_access;
   begin

      current_id  := ewok.sched.get_current;
      current_a   := ewok.tasks.get_task (current_id);

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
            svc_type : t_svc with address => inst.svc_num'address;
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
      -- Getting svc parameters from caller's stack
      --

      svc_params_a := to_parameters_access (frame_a.all.R0);

      -------------------
      -- Managing SVCs --
      -------------------

      case svc is

         when SVC_TASK_DONE   =>

            if current_a.all.mode /= TASK_MODE_MAINTHREAD then
               set_return_value
                 (current_id, current_a.all.mode, SYS_E_DENIED);
               return frame_a;
            end if;

            ewok.tasks.set_state
              (current_id, TASK_MODE_MAINTHREAD, TASK_STATE_FINISHED);

            return ewok.sched.do_schedule (frame_a);

         when SVC_ISR_DONE    =>

            if current_a.all.mode /= TASK_MODE_ISRTHREAD then
               set_return_value
                 (current_id, current_a.all.mode, SYS_E_DENIED);
               return frame_a;
            end if;

#if CONFIG_SCHED_SUPPORT_FISR
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
#end if;

            ewok.tasks.set_state
              (current_id, TASK_MODE_ISRTHREAD, TASK_STATE_ISR_DONE);

            return ewok.sched.do_schedule (frame_a);

         when SVC_YIELD          =>
            ewok.syscalls.yield.svc_yield (current_id, current_a.all.mode);
            return frame_a;

         when SVC_GETTICK        =>
            ewok.syscalls.gettick.svc_gettick (current_id, svc_params_a.all, current_a.all.mode);
            return frame_a;

         when SVC_RESET          =>
            ewok.syscalls.reset.svc_reset (current_id, current_a.all.mode);
            return frame_a;

         when SVC_SLEEP          =>
            ewok.syscalls.sleep.svc_sleep (current_id, svc_params_a.all, current_a.all.mode);
            return frame_a;

         when SVC_GET_RANDOM     =>
            ewok.syscalls.rng.svc_get_random (current_id, svc_params_a.all, current_a.all.mode);
            return frame_a;

         when SVC_LOG   =>

            -- Svc_log() syscall is postponed (asynchronously executed)
            if current_a.all.mode = TASK_MODE_MAINTHREAD then
               ewok.softirq.push_syscall (current_id, svc);
               ewok.tasks.set_state (current_id, TASK_MODE_MAINTHREAD,
                  TASK_STATE_SVC_BLOCKED);
               return ewok.sched.do_schedule (frame_a);
            else
               -- Postponed syscalls are forbidden in ISR mode
               set_return_value
                 (current_id, TASK_MODE_ISRTHREAD, SYS_E_DENIED);
               return frame_a;
            end if;

         when SVC_INIT_DEVACCESS =>
            ewok.syscalls.init.svc_register_device (current_id, svc_params_a.all, current_a.all.mode);
            return frame_a;

         when SVC_INIT_DMA       =>
            ewok.syscalls.dma.svc_do_reg_dma (current_id, svc_params_a.all, current_a.all.mode);
            return frame_a;

         when SVC_INIT_DMA_SHM   =>
            ewok.syscalls.dma.svc_do_reg_dma_shm (current_id, svc_params_a.all, current_a.all.mode);
            return frame_a;

         when SVC_INIT_GETTASKID =>
            ewok.syscalls.init.svc_get_taskid (current_id, svc_params_a.all, current_a.all.mode);
            return frame_a;

         when SVC_INIT_DONE      =>
            ewok.syscalls.init.svc_init_done (current_id, current_a.all.mode);
            return frame_a;

         when SVC_IPC_RECV_SYNC   =>
            ewok.syscalls.ipc.svc_ipc_do_recv
              (current_id, svc_params_a.all, true, current_a.all.mode);
            return ewok.sched.do_schedule (frame_a);

         when SVC_IPC_SEND_SYNC   =>
            ewok.syscalls.ipc.svc_ipc_do_send
              (current_id, svc_params_a.all, true, current_a.all.mode);
            return ewok.sched.do_schedule (frame_a);

         when SVC_IPC_RECV_ASYNC  =>
            ewok.syscalls.ipc.svc_ipc_do_recv
              (current_id, svc_params_a.all, false, current_a.all.mode);
            return ewok.sched.do_schedule (frame_a);

         when SVC_IPC_SEND_ASYNC  =>
            ewok.syscalls.ipc.svc_ipc_do_send
              (current_id, svc_params_a.all, false, current_a.all.mode);
            return ewok.sched.do_schedule (frame_a);

         when SVC_GPIO_SET   =>
            ewok.syscalls.cfg.gpio.svc_gpio_set (current_id, svc_params_a.all, current_a.all.mode);
            return frame_a;

         when SVC_GPIO_GET   =>
            ewok.syscalls.cfg.gpio.svc_gpio_get (current_id, svc_params_a.all, current_a.all.mode);
            return frame_a;

         when SVC_GPIO_UNLOCK_EXTI =>
            ewok.syscalls.cfg.gpio.svc_gpio_unlock_exti (current_id, svc_params_a.all, current_a.all.mode);
            return frame_a;

         when SVC_DMA_RECONF =>
            ewok.syscalls.dma.svc_dma_reconf (current_id, svc_params_a.all, current_a.all.mode);
            return frame_a;

         when SVC_DMA_RELOAD =>
            ewok.syscalls.dma.svc_dma_reload (current_id, svc_params_a.all, current_a.all.mode);
            return frame_a;

         when SVC_DMA_DISABLE =>
            ewok.syscalls.dma.svc_dma_disable (current_id, svc_params_a.all, current_a.all.mode);
            return frame_a;

         when SVC_DEV_MAP    =>
            ewok.syscalls.cfg.dev.svc_dev_map (current_id, svc_params_a.all, current_a.all.mode);
            return frame_a;

         when SVC_DEV_UNMAP  =>
            ewok.syscalls.cfg.dev.svc_dev_unmap (current_id, svc_params_a.all, current_a.all.mode);
            return frame_a;

         when SVC_DEV_RELEASE =>
            ewok.syscalls.cfg.dev.svc_dev_release (current_id, svc_params_a.all, current_a.all.mode);
            return frame_a;

         when SVC_LOCK_ENTER     =>
            ewok.syscalls.lock.svc_lock_enter (current_id, current_a.all.mode);
            return frame_a;

         when SVC_LOCK_EXIT      =>
            ewok.syscalls.lock.svc_lock_exit (current_id, current_a.all.mode);
            return frame_a;

      end case;

   end svc_handler;


end ewok.syscalls.handler;
