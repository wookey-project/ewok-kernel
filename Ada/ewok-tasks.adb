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


with debug;
with m4.cpu;
with m4.cpu.instructions;
with ewok.layout;          use ewok.layout;
with ewok.devices_shared;  use ewok.devices_shared;
with ewok.softirq;
with c.kernel;
with types.c;              use type types.c.t_retval;

with applications; -- Automatically generated
with sections;     -- Automatically generated

package body ewok.tasks
   with spark_mode => off
is

   procedure idle_task
   is
   begin
      debug.log (debug.INFO, "IDLE thread");
      m4.cpu.enable_irq;
      loop
         m4.cpu.instructions.wait_for_interrupt;
      end loop;
   end idle_task;


   procedure finished_task
   is
   begin
      loop null; end loop;
   end finished_task;


   procedure create_stack
     (sp       : in  system_address;
      pc       : in  system_address;
      params   : in  ewok.t_parameters;
      frame_a  : out ewok.t_stack_frame_access)
   is
   begin

      frame_a := to_stack_frame_access (sp - (t_stack_frame'size / 8));

      frame_a.all.R0 := params(0);
      frame_a.all.R1 := params(1);
      frame_a.all.R2 := params(2);
      frame_a.all.R3 := params(3);

      frame_a.all.R4    := 0;
      frame_a.all.R5    := 0;
      frame_a.all.R6    := 0;
      frame_a.all.R7    := 0;
      frame_a.all.R8    := 0;
      frame_a.all.R9    := 0;
      frame_a.all.R10   := 0;
      frame_a.all.R11   := 0;
      frame_a.all.R12   := 0;

      frame_a.all.exc_return  := m4.cpu.EXC_THREAD_MODE;
      frame_a.all.LR    := to_system_address (finished_task'address);
      frame_a.all.PC    := pc;
      frame_a.all.PSR   := m4.cpu.t_PSR_register'
	     (ISR_NUMBER     => 0,
	      ICI_IT_lo      => 0,
	      GE             => 0,
	      Thumb          => 1,
	      ICI_IT_hi      => 0,
	      DSP_overflow   => 0,
	      Overflow       => 0,
	      Carry          => 0,
	      Zero           => 0,
	      Negative       => 0);

   end create_stack;


   procedure set_default_values (tsk : out t_task)
   is
   begin
      tsk.name              := "          ";
      tsk.entry_point       := 0;
      tsk.ttype             := TASK_TYPE_USER;
      tsk.mode              := TASK_MODE_MAINTHREAD;
      tsk.id                := ID_UNUSED;
      tsk.slot              := 0;
      tsk.num_slots         := 0;
      tsk.prio              := 0;
#if CONFIG_KERNEL_DOMAIN
      tsk.domain            := 0;
#end if;
      tsk.num_devs          := 0;
      tsk.num_devs_mmapped  := 0;
#if CONFIG_KERNEL_SCHED_DEBUG
      tsk.count             := 0;
      tsk.force_count       := 0;
      tsk.isr_count         := 0;
#end if;
#if CONFIG_KERNEL_DMA_ENABLE
      tsk.num_dma_shms      := 0;
      tsk.dma_shm           :=
        (others => ewok.exported.dma.t_dma_shm_info'
           (granted_id  => ID_UNUSED,
            accessed_id => ID_UNUSED,
            base        => 0,
            size        => 0,
            access_type => ewok.exported.dma.SHM_ACCESS_READ));

      tsk.num_dma_id        := 0;
      tsk.dma_id            := (others => ewok.dma_shared.ID_DMA_UNUSED);
#end if;
      tsk.init_done         := false;
      tsk.device_id         := (others => ewok.devices_shared.ID_DEV_UNUSED);
      tsk.data_slot_start   := 0;
      tsk.data_slot_end     := 0;
      tsk.txt_slot_start    := 0;
      tsk.txt_slot_end      := 0;
      tsk.stack_size        := 0;
      tsk.state             := TASK_STATE_EMPTY;
      tsk.isr_state         := TASK_STATE_EMPTY;
      tsk.ipc_endpoints     := (others => NULL);
      tsk.ctx.frame_a       := NULL;
      tsk.isr_ctx           := t_isr_context'(0, ID_DEV_UNUSED, ISR_STANDARD, NULL);
   end set_default_values;


   procedure init_softirq_task
   is
      params : constant t_parameters := (others => 0);
   begin

      -- Setting default values
      set_default_values (tasks_list(ID_SOFTIRQ));

      tasks_list(ID_SOFTIRQ).name := softirq_task_name;

      tasks_list(ID_SOFTIRQ).entry_point  :=
         to_system_address (ewok.softirq.main_task'address);

      if tasks_list(ID_SOFTIRQ).entry_point mod 2 = 0 then
         tasks_list(ID_SOFTIRQ).entry_point :=
            tasks_list(ID_SOFTIRQ).entry_point + 1;
      end if;

      tasks_list(ID_SOFTIRQ).ttype  := TASK_TYPE_KERNEL;
      tasks_list(ID_SOFTIRQ).mode   := TASK_MODE_MAINTHREAD;
      tasks_list(ID_SOFTIRQ).id     := ID_SOFTIRQ;

      tasks_list(ID_SOFTIRQ).slot      := 0; -- unused
      tasks_list(ID_SOFTIRQ).num_slots := 0; -- unused

      -- Zeroing the stack
      declare
         stack : byte_array(1 .. STACK_SIZE_SOFTIRQ)
            with address => to_address (STACK_TOP_SOFTIRQ - STACK_SIZE_SOFTIRQ);
      begin
         stack := (others => 0);
      end;

      -- Create the initial stack frame and set the stack pointer
      create_stack
        (STACK_TOP_SOFTIRQ,
         tasks_list(ID_SOFTIRQ).entry_point,
         params,
         tasks_list(ID_SOFTIRQ).ctx.frame_a);

      tasks_list(ID_SOFTIRQ).stack_size   := STACK_SIZE_SOFTIRQ;
      tasks_list(ID_SOFTIRQ).state := TASK_STATE_IDLE;
      tasks_list(ID_SOFTIRQ).isr_state := TASK_STATE_IDLE;

      for i in tasks_list(ID_SOFTIRQ).ipc_endpoints'range loop
         tasks_list(ID_SOFTIRQ).ipc_endpoints(i)   := NULL;
      end loop;

      debug.log (debug.INFO, "Created context for SOFTIRQ task (pc: "
         & system_address'image (tasks_list(ID_SOFTIRQ).entry_point)
         & ") sp: "
         & system_address'image
            (to_system_address (tasks_list(ID_SOFTIRQ).ctx.frame_a)));

   end init_softirq_task;


   procedure init_idle_task
   is
      params : constant t_parameters := (others => 0);
   begin

      -- Setting default values
      set_default_values (tasks_list(ID_KERNEL));

      tasks_list(ID_KERNEL).name := idle_task_name;

      tasks_list(ID_KERNEL).entry_point  :=
         to_system_address (idle_task'address);

      if tasks_list(ID_KERNEL).entry_point mod 2 = 0 then
         tasks_list(ID_KERNEL).entry_point :=
            tasks_list(ID_KERNEL).entry_point + 1;
      end if;

      tasks_list(ID_KERNEL).ttype  := TASK_TYPE_KERNEL;
      tasks_list(ID_KERNEL).mode   := TASK_MODE_MAINTHREAD;
      tasks_list(ID_KERNEL).id     := ID_KERNEL;

      tasks_list(ID_KERNEL).slot      := 0; -- unused
      tasks_list(ID_KERNEL).num_slots := 0; -- unused

      -- Zeroing the stack
      declare
         stack : byte_array(1 .. STACK_SIZE_IDLE)
            with address => to_address (STACK_TOP_IDLE - STACK_SIZE_IDLE);
      begin
         stack := (others => 0);
      end;

      -- Create the initial stack frame and set the stack pointer
      create_stack
        (STACK_TOP_IDLE,
         tasks_list(ID_KERNEL).entry_point,
         params,
         tasks_list(ID_KERNEL).ctx.frame_a);

      tasks_list(ID_KERNEL).stack_size   := STACK_SIZE_IDLE;
      tasks_list(ID_KERNEL).state        := TASK_STATE_RUNNABLE;
      tasks_list(ID_KERNEL).isr_state    := TASK_STATE_IDLE;

      for i in tasks_list(ID_KERNEL).ipc_endpoints'range loop
         tasks_list(ID_KERNEL).ipc_endpoints(i)   := NULL;
      end loop;

      debug.log (debug.INFO, "Created context for IDLE task (pc: "
         & system_address'image (tasks_list(ID_KERNEL).entry_point)
         & ") sp: "
         & system_address'image
            (to_system_address (tasks_list(ID_KERNEL).ctx.frame_a)));

   end init_idle_task;


   procedure init_apps
   is
      user_base   : system_address;
      params      : t_parameters;
      random      : unsigned_32;
   begin

      if applications.t_real_task_id'last > ID_APP7 then
         debug.panic ("Too many apps");
      end if;

      user_base := applications.txt_user_region_base;

      for id in applications.list'range loop

         set_default_values (tasks_list(id));

	      tasks_list(id).name := applications.list(id).name;
	
	      tasks_list(id).entry_point  :=
            user_base
            + to_unsigned_32 (applications.list(id).slot - 1)
               * applications.txt_user_size / 8; -- this is MPU specific

	      if tasks_list(id).entry_point mod 2 = 0 then
	         tasks_list(id).entry_point := tasks_list(id).entry_point + 1;
	      end if;
	
	      tasks_list(id).ttype := TASK_TYPE_USER;
	      tasks_list(id).mode  := TASK_MODE_MAINTHREAD;
	      tasks_list(id).id    := id;
	
	      tasks_list(id).slot      := applications.list(id).slot;
	      tasks_list(id).num_slots := applications.list(id).num_slots;

         tasks_list(id).prio  := applications.list(id).priority;

#if CONFIG_KERNEL_DOMAIN
         tasks_list(id).domain   := applications.list(id).domain;
#end if;

#if CONFIG_KERNEL_SCHED_DEBUG
         tasks_list(id).count       := 0;
         tasks_list(id).force_count := 0;
         tasks_list(id).isr_count   := 0;
#end if;

#if CONFIG_KERNEL_DMA_ENABLE
         tasks_list(id).num_dma_shms   := 0;
         tasks_list(id).dma_shm        :=
           (others => ewok.exported.dma.t_dma_shm_info'
              (granted_id  => ID_UNUSED,
               accessed_id => ID_UNUSED,
               base        => 0,
               size        => 0,
               access_type => ewok.exported.dma.SHM_ACCESS_READ));
         tasks_list(id).num_dma_id     := 0;
         tasks_list(id).dma_id         :=
           (others => ewok.dma_shared.ID_DMA_UNUSED);
#end if;
	
         tasks_list(id).num_devs          := 0;
         tasks_list(id).num_devs_mmapped  := 0;

         tasks_list(id).device_id      := (others => ID_DEV_UNUSED);

         tasks_list(id).init_done   := false;

         tasks_list(id).data_slot_start   :=
            USER_DATA_BASE
            + to_unsigned_32 (tasks_list(id).slot - 1)
               * USER_DATA_SIZE;

         tasks_list(id).data_slot_end     :=
            USER_DATA_BASE
            + to_unsigned_32
                 (tasks_list(id).slot + tasks_list(id).num_slots - 1)
               * USER_DATA_SIZE;

         tasks_list(id).txt_slot_start := tasks_list(id).entry_point - 1;

         tasks_list(id).txt_slot_end   :=
            user_base
            + to_unsigned_32
                (applications.list(id).slot + tasks_list(id).num_slots - 1)
               * applications.txt_user_size / 8; -- this is MPU specific

         tasks_list(id).stack_size  := applications.list(id).stack_size;
         tasks_list(id).state       := TASK_STATE_RUNNABLE;
         tasks_list(id).isr_state   := TASK_STATE_IDLE;

	      for i in tasks_list(id).ipc_endpoints'range loop
	         tasks_list(id).ipc_endpoints(i)   := NULL;
	      end loop;

         -- Zeroing the stack
         declare
            stack : byte_array(1 .. unsigned_32 (tasks_list(id).stack_size))
               with address => to_address
                 (tasks_list(id).data_slot_end -
                  unsigned_32 (tasks_list(id).stack_size));
         begin
            stack := (others => 0);
         end;

         --
	      -- Create the initial stack frame and set the stack pointer
         --

         -- Getting the stack "canary"
         if c.kernel.get_random_u32 (random) /= types.c.SUCCESS then
            debug.panic ("Unable to get random from TRNG source");
         end if;

         params := t_parameters'(to_unsigned_32 (id), random, 0, 0);

	      create_stack
	        (tasks_list(id).data_slot_end,
	         tasks_list(id).entry_point,
	         params,
	         tasks_list(id).ctx.frame_a);

         tasks_list(id).isr_ctx.entry_point := applications.list(id).start_isr;

         debug.log (debug.INFO, "created task " & tasks_list(id).name
            & " (pc: " & system_address'image (tasks_list(id).entry_point)
            & ", sp: " & system_address'image
                           (to_system_address (tasks_list(id).ctx.frame_a))
            & ", ID" & t_task_id'image (id) & ")");
      end loop;

   end init_apps;


   function get_task (id : ewok.tasks_shared.t_task_id)
      return t_task_access
   is
   begin
      return tasks_list(id)'access;
   end get_task;


   function get_task_id (name : t_task_name)
      return ewok.tasks_shared.t_task_id
   is

      -- String comparison is a bit tricky here because:
      --  - We want it case-unsensitive ('a' and 'A' are the same)
      --  - The nul character and space ' ' are consider the same
      --
      -- The following inner functions are needed to effect comparisons:

      -- Convert a character to uppercase
      function to_upper (c : character)
         return character
      is
         val : constant natural := character'pos (c);
      begin
         return
           (if c in 'a' .. 'z' then character'val (val - 16#20#) else c);
      end;

      -- Test if a character is 'nul'
      function is_nul (c : character)
         return boolean
      is begin
         return c = ASCII.NUL or c = ' ';
      end;

      -- Test if the 2 strings are the same
      function is_same (s1: t_task_name; s2 : t_task_name)
         return boolean
      is begin
         for i in t_task_name'range loop
            if is_nul (s1(i)) and is_nul (s2(i)) then
               return true;
            end if;
            if to_upper (s1(i)) /= to_upper (s2(i)) then
               return false;
            end if;
         end loop;
         return true;
      end;

   begin
      for id in applications.list'range loop
         if is_same (tasks_list(id).name, name) then
            return id;
         end if;
      end loop;
      return ID_UNUSED;
   end get_task_id;


#if CONFIG_KERNEL_DOMAIN
   function get_domain (id : in ewok.tasks_shared.t_task_id)
      return unsigned_8
   is
   begin
      return tasks_list(id).domain;
   end get_domain;
#end if;


   function get_state
     (id    : ewok.tasks_shared.t_task_id;
      mode  : t_task_mode)
      return t_task_state
   is
   begin
     if mode = TASK_MODE_MAINTHREAD then
       return tasks_list(id).state;
      else -- TASK_MODE_ISRTHREAD
       return tasks_list(id).isr_state;
      end if;
   end get_state;

   procedure set_state
     (id    : ewok.tasks_shared.t_task_id;
      mode  : t_task_mode;
      state : t_task_state)
   is
   begin
      if mode = TASK_MODE_MAINTHREAD then
        tasks_list(id).state := state;
      else -- TASK_MODE_ISRTHREAD
         tasks_list(id).isr_state := state;
      end if;
   end set_state;

   function get_mode
     (id     : in  ewok.tasks_shared.t_task_id)
   return t_task_mode
   is
   begin
     return tasks_list(id).mode;
   end get_mode;

   procedure set_mode
     (id     : in   ewok.tasks_shared.t_task_id;
      mode   : in   ewok.tasks_shared.t_task_mode)
   is
   begin
     tasks_list(id).mode := mode;
   end set_mode;

   -- FIXME useful ?
   function is_user (id : ewok.tasks_shared.t_task_id) return boolean
   is
   begin
      return (id in applications.t_real_task_id);
   end is_user;


   procedure set_return_value
     (id    : in  ewok.tasks_shared.t_task_id;
      mode  : in  t_task_mode;
      val   : in  unsigned_32)
   is
   begin
      case mode is
         when TASK_MODE_MAINTHREAD =>
            tasks_list(id).ctx.frame_a.all.R0      := val;
         when TASK_MODE_ISRTHREAD =>
            tasks_list(id).isr_ctx.frame_a.all.R0  := val;
      end case;
   end set_return_value;


   procedure task_init
   is
   begin

      for id in tasks_list'range loop
         set_default_values (tasks_list(id));
      end loop;

      init_idle_task;
      init_softirq_task;
      init_apps;

      sections.task_map_data;

   end task_init;


   function is_init_done
     (id    : ewok.tasks_shared.t_task_id)
      return boolean
   is
   begin
      return tasks_list(id).init_done;
   end is_init_done;


end ewok.tasks;
