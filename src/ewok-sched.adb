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

with ewok.tasks;           use ewok.tasks;
with ewok.devices_shared;  use ewok.devices_shared;
with ewok.sleep;
with ewok.syscalls.handler;
with ewok.memory;
with ewok.interrupts;
with soc.interrupts;
with soc.dwt;
with m4.scb;
with m4.systick;


package body ewok.sched
   with spark_mode => off
is

   package TSK renames ewok.tasks;

   -----------------------------------------------
   -- SPARK/ghost specific functions & procedures
   -----------------------------------------------

   function current_task_is_valid
      return boolean
   is
   begin
      return (current_task_id /= ID_UNUSED);
   end current_task_is_valid;

   ----------------------------------------------
   -- sched functions
   ----------------------------------------------

   procedure request_schedule
   is
   begin
      m4.scb.SCB.ICSR.PENDSVSET := 1;
   end request_schedule;


   function task_elect
      return t_task_id
   is
      elected  : t_task_id;
   begin

      --
      -- Execute pending user ISRs first
      --

      for id in config.applications.list'range loop
         if TSK.tasks_list(id).mode = TASK_MODE_ISRTHREAD
            and then
            ewok.tasks.get_state (id, TASK_MODE_ISRTHREAD) = TASK_STATE_RUNNABLE
            and then
            ewok.tasks.get_state (id, TASK_MODE_MAINTHREAD) /= TASK_STATE_LOCKED
         then
            elected := id;
            goto ok_return;
         end if;
      end loop;

      --
      -- Execute tasks in critical sections
      --

      for id in config.applications.list'range loop
         if TSK.tasks_list(id).state = TASK_STATE_LOCKED then
            elected := id;
            if TSK.tasks_list(id).mode = TASK_MODE_MAINTHREAD then
               last_main_user_task_id := elected;
            end if;
            goto ok_return;
         end if;
      end loop;

      --
      -- Updating finished ISRs state
      --

      for id in config.applications.list'range loop

         if TSK.tasks_list(id).mode = TASK_MODE_ISRTHREAD
            and then
            ewok.tasks.get_state (id, TASK_MODE_ISRTHREAD) = TASK_STATE_ISR_DONE
         then
            ewok.tasks.set_state
              (id, TASK_MODE_ISRTHREAD, TASK_STATE_IDLE);
            TSK.tasks_list(id).isr_ctx.frame_a        := NULL;
            TSK.tasks_list(id).isr_ctx.device_id      := ID_DEV_UNUSED;
            TSK.tasks_list(id).isr_ctx.sched_policy   := ISR_STANDARD;
            ewok.tasks.set_mode (id, TASK_MODE_MAINTHREAD);


            -- When a task has just finished its ISR  its main thread might
            -- become runnable
            if ewok.sleep.is_sleeping (id) then
               ewok.sleep.try_waking_up (id);
            elsif TSK.tasks_list(id).state = TASK_STATE_IDLE then
               ewok.tasks.set_state
                 (id, TASK_MODE_MAINTHREAD, TASK_STATE_RUNNABLE);
            end if;

         end if;

      end loop;

      --
      -- Execute SOFTIRQ if there are some pending ISRs and/or syscalls
      --

      if ewok.tasks.get_state
              (ID_SOFTIRQ, TASK_MODE_MAINTHREAD) = TASK_STATE_RUNNABLE then
         elected := ID_SOFTIRQ;
         goto ok_return;
      end if;

      --
      -- IPC can force task election to reduce IPC overhead
      --

      for id in config.applications.list'range loop
         if TSK.tasks_list(id).state = TASK_STATE_FORCED then
            ewok.tasks.set_state
              (id, TASK_MODE_MAINTHREAD, TASK_STATE_RUNNABLE);
            elected := id;
            goto ok_return;
         end if;
      end loop;


#if CONFIG_SCHED_RAND
      declare
         random   : aliased unsigned_32;
         id       : t_task_id;
         ok       : boolean;
         pragma unreferenced (ok);
      begin
         ewok.rng.random (random'access, ok);
         id := t_task_id'val ((config.applications.list'first)'pos +
                            (random mod config.applications.list'length));
         for i in 1 .. config.applications.list'length loop
            if ewok.tasks.get_state
              (id, TASK_MODE_MAINTHREAD) = TASK_STATE_RUNNABLE then
               elected := id;
               goto ok_return;
            end if;
            if id /= config.applications.list'last then
               id := t_task_id'succ (id);
            else
               id := config.applications.list'first;
            end if;
         end loop;
      end;
#end if;

#if CONFIG_SCHED_RR
      declare
         id : t_task_id;
      begin
         id := last_main_user_task_id;
         for i in 1 .. config.applications.list'length loop
            if id < config.applications.list'last then
               id := t_task_id'succ (id);
            else
               id := config.applications.list'first;
            end if;
            if ewok.tasks.get_state
              (id, TASK_MODE_MAINTHREAD) = TASK_STATE_RUNNABLE then
               elected := id;
               last_main_user_task_id := elected;
               goto ok_return;
            end if;
         end loop;
      end;
#end if;

#if CONFIG_SCHED_MLQ_RR
      declare
         max_prio : unsigned_8 := 0;
         id       : t_task_id;
      begin

         -- Max priority
         for id in config.applications.list'range loop
            if TSK.tasks_list(id).prio > max_prio
               and
               ewok.tasks.get_state (id, TASK_MODE_MAINTHREAD)
                  = TASK_STATE_RUNNABLE
            then
               max_prio := TSK.tasks_list(id).prio;
            end if;
         end loop;

         -- Round Robin election on tasks with the max priority
         id := last_main_user_task_id;
         for i in 1 .. config.applications.list'length loop
            if id < config.applications.list'last then
               id := t_task_id'succ (id);
            else
               id := config.applications.list'first;
            end if;
            if TSK.tasks_list(id).prio = max_prio
               and
               ewok.tasks.get_state (id, TASK_MODE_MAINTHREAD)
                  = TASK_STATE_RUNNABLE
            then
               elected := id;
               last_main_user_task_id := elected;
               goto ok_return;
            end if;
         end loop;
      end;
#end if;

      -- Default
      elected := ID_KERNEL;

   <<ok_return>>
      --pragma DEBUG (debug.log (debug.DEBUG, "task " & t_task_id'image (elected) & " elected"));
      return elected;

   end task_elect;


   function pendsv_handler
     (frame_a : ewok.t_stack_frame_access)
      return ewok.t_stack_frame_access
   is
      old_task_id    : constant t_task_id    := current_task_id;
      old_task_mode  : constant t_task_mode  := current_task_mode;
   begin

      -- Keep ISR threads running until they finish
      if current_task_mode = TASK_MODE_ISRTHREAD and then
         ewok.tasks.get_state
           (current_task_id, TASK_MODE_ISRTHREAD) = TASK_STATE_RUNNABLE
      then
         return frame_a;
      end if;

#if CONFIG_KERNEL_EXP_REENTRANCY
      -- This global variable write access is not reentrant, but, by
      -- construction can't be accedded concurently in a monoprocessor
      -- system due to processor's IRQ priority.
      -- Although, we make IRQ locked here for future compatibility
      --
      -- TODO: define a clear denomination for locking/unlocking critical
      --       sections in kernel instead of directly calling HW primitives
      m4.cpu.disable_irq;
#end if;

      -- Save current context
      if current_task_mode = TASK_MODE_ISRTHREAD then
         TSK.tasks_list(current_task_id).isr_ctx.frame_a := frame_a;
      else
         TSK.tasks_list(current_task_id).ctx.frame_a := frame_a;
      end if;

      -- Elect a new task and change current_task_id
      current_task_id   := task_elect;
      current_task_mode := TSK.tasks_list(current_task_id).mode;

#if CONFIG_KERNEL_EXP_REENTRANCY
      -- End of global variables WR access
      m4.cpu.enable_irq;
#end if;

      -- Apply MPU specific configuration
      if not
           (current_task_id = old_task_id and
            current_task_mode = old_task_mode)
      then
         ewok.memory.map_task (current_task_id);
      end if;

      -- Return the new context
      if current_task_mode = TASK_MODE_ISRTHREAD then
         return TSK.tasks_list(current_task_id).isr_ctx.frame_a;
      else
         return TSK.tasks_list(current_task_id).ctx.frame_a;
      end if;

   end pendsv_handler;


   function systick_handler
     (frame_a : ewok.t_stack_frame_access)
      return ewok.t_stack_frame_access
   is
      old_task_id    : constant t_task_id    := current_task_id;
      old_task_mode  : constant t_task_mode  := current_task_mode;
   begin

      m4.systick.increment;
      sched_period := sched_period + 1;

      -- Managing DWT cycle count overflow
      soc.dwt.ovf_manage;

      -- FIXME - CONFIG_SCHED_PERIOD must be in milliseconds,
      --         not in ticks
      if sched_period /= $CONFIG_SCHED_PERIOD then
         return frame_a;
      else
         sched_period := 0;
      end if;

#if CONFIG_KERNEL_EXP_REENTRANCY
      -- This global variable write access is not reentrant, but, by
      -- construction can't be accedded concurently in a monoprocessor
      -- system due to processor's IRQ priority.
      -- Although, we make IRQ locked here for future compatibility
      -- Here we lock down to the end of globals usage to avoid to
      -- many successive disable/enable of IRQs
      m4.cpu.disable_irq;
#end if;

      -- Waking-up sleeping tasks
      ewok.sleep.check_is_awoke;

      -- Keep ISR threads running until they finish
      if current_task_mode = TASK_MODE_ISRTHREAD and then
         ewok.tasks.get_state
           (current_task_id, TASK_MODE_ISRTHREAD) = TASK_STATE_RUNNABLE
      then
#if CONFIG_KERNEL_EXP_REENTRANCY
         m4.cpu.enable_irq;
#end if;
         return frame_a;
      end if;

      -- Save current context
      if current_task_mode = TASK_MODE_ISRTHREAD then
         TSK.tasks_list(current_task_id).isr_ctx.frame_a := frame_a;
      else
         TSK.tasks_list(current_task_id).ctx.frame_a := frame_a;
      end if;

      -- Elect a new task
      current_task_id   := task_elect;
      current_task_mode := TSK.tasks_list(current_task_id).mode;

#if CONFIG_KERNEL_EXP_REENTRANCY
      -- End of global variable access
      m4.cpu.enable_irq;
#end if;

      -- Apply MPU specific configuration
      if not
           (current_task_id = old_task_id and
            current_task_mode = old_task_mode)
      then
         ewok.memory.map_task (current_task_id);
      end if;

      -- Return the new context
      if current_task_mode = TASK_MODE_ISRTHREAD then
         return TSK.tasks_list(current_task_id).isr_ctx.frame_a;
      else
         return TSK.tasks_list(current_task_id).ctx.frame_a;
      end if;

   end systick_handler;


   procedure init
   is
      idle_task   : t_task renames ewok.tasks.tasks_list(ID_KERNEL);
      ok          : boolean;
   begin

      current_task_id := ID_KERNEL;

      ewok.interrupts.set_task_switching_handler
        (soc.interrupts.INT_SYSTICK,
         systick_handler'access,
         ID_KERNEL,
         ID_DEV_UNUSED,
         ok);

      if not ok then raise program_error; end if;

      ewok.interrupts.set_task_switching_handler
        (soc.interrupts.INT_PENDSV,
         pendsv_handler'access,
         ID_KERNEL,
         ID_DEV_UNUSED,
         ok);

      if not ok then raise program_error; end if;

      ewok.interrupts.set_task_switching_handler
        (soc.interrupts.INT_SVC,
         ewok.syscalls.handler.svc_handler'access,
         ID_KERNEL,
         ID_DEV_UNUSED,
         ok);

      if not ok then raise program_error; end if;

      --
      -- Jump to the kernel task
      --
      system.machine_code.asm
        ("mov r0, %0"   & ascii.lf &
         "msr psp, r0"  & ascii.lf &
         "mov r0, 2"    & ascii.lf &
         "msr control, r0" & ascii.lf &
         "mov r1, %1"   & ascii.lf &
         "bx r1",
         inputs   =>
           (system_address'asm_input
              ("r", to_system_address (idle_task.ctx.frame_a)),
            system_address'asm_input
              ("r", idle_task.entry_point)),
         clobber  => "r0, r1",
         volatile => true);

   end init;


end ewok.sched;
