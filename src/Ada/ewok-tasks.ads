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


with ewok.tasks_shared; use ewok.tasks_shared;
with ewok.devices_shared;
with ewok.ipc;
with ewok.exported.dma;
with ewok.dma_shared;
with ewok.mpu;
with soc;
with soc.layout;


package ewok.tasks
   with spark_mode => off
is

   subtype t_task_name is string (1 .. 10);

   type t_task_state is (
      -- No task in this slot
      TASK_STATE_EMPTY,

      -- Task can be elected by the scheduler with its standard priority
      -- or an ISR is ready for execution
      TASK_STATE_RUNNABLE,

      -- Force the scheduler to choose that task
      TASK_STATE_FORCED,

      -- Pending syscall. Task can't be scheduled.
      TASK_STATE_SVC_BLOCKED,

      -- An ISR is finished
      TASK_STATE_ISR_DONE,

      -- Task currently has nothing to do, not schedulable
      TASK_STATE_IDLE,

      -- Task is sleeping
      TASK_STATE_SLEEPING,

      -- Task is deeply sleeping
      TASK_STATE_SLEEPING_DEEP,

      -- Task has generated an exception (memory fault, etc.), not
      -- schedulable anymore
      TASK_STATE_FAULT,

      -- Task has return from its main() function. Yet its ISR handlers can
      -- still be executed if needed
      TASK_STATE_FINISHED,

      -- Task has emitted a blocking send(target) and is waiting for that
      -- the EndPoint shared with the receiver gets ready
      TASK_STATE_IPC_SEND_BLOCKED,

      -- Task has emitted a blocking recv(target) and is waiting for a
      -- send()
      TASK_STATE_IPC_RECV_BLOCKED,

      -- Task has emitted a blocking send(target) and is waiting recv()
      -- acknowledgement from the target task
      TASK_STATE_IPC_WAIT_ACK,

      -- Task has entered in a critical section. Related ISRs can't be executed
      TASK_STATE_LOCKED);

   type t_task_type is
     (-- Kernel task
      TASK_TYPE_KERNEL,
      -- User task, being executed in user mode, with restricted access
      TASK_TYPE_USER);

   type t_main_context is record
      frame_a       : ewok.t_stack_frame_access;
   end record;

   type t_isr_context is record
      entry_point   : system_address;
      device_id     : ewok.devices_shared.t_device_id;
      sched_policy  : ewok.tasks_shared.t_scheduling_post_isr;
      frame_a       : ewok.t_stack_frame_access;
   end record;

   --
   -- Tasks
   --

   MAX_DEVS_PER_TASK       : constant := 10;
   MAX_DMAS_PER_TASK       : constant := 8;
   MAX_INTERRUPTS_PER_TASK : constant := 8;
   MAX_DMA_SHM_PER_TASK    : constant := 4;

   type t_registered_dma_index_list is array (unsigned_32 range <>) of
      ewok.dma_shared.t_user_dma_index;

   type t_dma_shm_info_list is array (unsigned_32 range <>) of
      ewok.exported.dma.t_dma_shm_info;

   type t_device_id_list is array (unsigned_8 range <>) of
      ewok.devices_shared.t_device_id;

   type t_task is record
      name              : t_task_name;
      entry_point       : system_address;
      ttype             : t_task_type;
      mode              : t_task_mode;
      id                : ewok.tasks_shared.t_task_id;
      slot              : unsigned_8; -- 1: first slot (0: unused)
      num_slots         : unsigned_8;
      prio              : unsigned_8;
#if CONFIG_KERNEL_DOMAIN
      domain            : unsigned_8;
#end if;
#if CONFIG_KERNEL_SCHED_DEBUG
      count             : unsigned_32;
      force_count       : unsigned_32;
      isr_count         : unsigned_32;
#end if;
#if CONFIG_KERNEL_DMA_ENABLE
      num_dma_shms      : unsigned_32 range 0 .. MAX_DMA_SHM_PER_TASK;
      dma_shm           : t_dma_shm_info_list (1 .. MAX_DMA_SHM_PER_TASK);
      num_dma_id        : unsigned_32 range 0 .. MAX_DMAS_PER_TASK;
      dma_id            : t_registered_dma_index_list (1 .. MAX_DMAS_PER_TASK);
#end if;
      num_devs          : unsigned_8 range 0 .. MAX_DEVS_PER_TASK;
      num_devs_mounted  : unsigned_8 range 0 .. ewok.mpu.MAX_DEVICE_REGIONS;
      device_id         : t_device_id_list (1 .. MAX_DEVS_PER_TASK);
      mounted_device    : t_device_id_list (ewok.mpu.device_regions'range);

      init_done         : boolean;
      data_slot_start   : system_address;
      data_slot_end     : system_address;
      txt_slot_start    : system_address;
      txt_slot_end      : system_address;
      stack_bottom      : system_address;
      stack_top         : system_address;
      stack_size        : unsigned_16;
      state             : t_task_state;
      isr_state         : t_task_state;
      ipc_endpoints     : ewok.ipc.t_endpoints (ewok.tasks_shared.t_task_id'range);
      ctx               : aliased t_main_context;
      isr_ctx           : aliased t_isr_context;
   end record;

   type t_task_access is access all t_task;

   type t_task_array is array (t_task_id range <>) of aliased t_task;

   -------------
   -- Globals --
   -------------

   -- The list of the running tasks
   tasks_list : t_task_array (ID_APP1 .. ID_KERNEL);

   softirq_task_name : aliased t_task_name := "SOFTIRQ" & "   ";
   idle_task_name    : aliased t_task_name := "IDLE" & "      ";

   ---------------
   -- Functions --
   ---------------

   procedure idle_task with no_return;
   procedure finished_task with no_return;

   -- create various task's stack
   -- preconditions :
   -- Here we check that generated headers, defining stack address and
   -- program counter of various stack are valid for the currently
   -- supported SoC. This is a sanitizing function for generated files.
   procedure create_stack
     (sp       : in  system_address;
      pc       : in  system_address;
      params   : in  ewok.t_parameters;
      frame_a  : out ewok.t_stack_frame_access)
      with
         -- precondition 1 : stack pointer must be in RAM
         pre =>
           (
            (sp >= soc.layout.USER_RAM_BASE and
             sp <= (soc.layout.USER_RAM_BASE + soc.layout.USER_RAM_SIZE)) or
            (sp >= soc.layout.KERNEL_RAM_BASE and
             sp <= (soc.layout.KERNEL_RAM_BASE + soc.layout.KERNEL_RAM_SIZE))
           ) and (
         -- precondition 2 : program counter must be in flash
            pc >= soc.layout.FLASH_BASE and
            pc <= soc.layout.FLASH_BASE + soc.layout.FLASH_SIZE
           ),
         global => ( in_out => tasks_list );


   procedure set_default_values (tsk : out t_task);

   procedure init_softirq_task;
   procedure init_idle_task;
   procedure init_apps;

   function is_real_user (id : ewok.tasks_shared.t_task_id) return boolean;

   function get_task (id : ewok.tasks_shared.t_task_id)
      return t_task_access
   with inline;

#if CONFIG_KERNEL_DOMAIN
   function get_domain (id : in ewok.tasks_shared.t_task_id)
      return unsigned_8
   with inline;
#end if;

   function get_task_id (name : t_task_name)
      return ewok.tasks_shared.t_task_id;

   procedure set_state
     (id    : ewok.tasks_shared.t_task_id;
      mode  : t_task_mode;
      state : t_task_state)
   with inline;

   function get_state
     (id    : ewok.tasks_shared.t_task_id;
      mode  : t_task_mode)
   return t_task_state
   with inline;

   function get_mode
     (id     : in  ewok.tasks_shared.t_task_id)
   return t_task_mode
   with
      inline,
      global => null;

   procedure set_mode
     (id     : in   ewok.tasks_shared.t_task_id;
      mode   : in   ewok.tasks_shared.t_task_mode)
   with
      inline,
      global => ( in_out => tasks_list );

   -- Set return value inside a syscall
   -- Note: mode must be defined as a task can do a syscall while in ISR mode
   --       or in THREAD mode
   procedure set_return_value
     (id    : in  ewok.tasks_shared.t_task_id;
      mode  : in  t_task_mode;
      val   : in  unsigned_32)
   with inline;

   procedure task_init
   with
      convention     => c,
      export         => true,
      external_name  => "task_init",
      global         => null;

   function is_init_done
     (id    : ewok.tasks_shared.t_task_id)
      return boolean;

   procedure append_device
     (id          : in  ewok.tasks_shared.t_task_id;
      dev_id      : in  ewok.devices_shared.t_device_id;
      descriptor  : out unsigned_8;
      success     : out boolean)
      with
         post => (if success = false then
                     descriptor = 0
                  else
                     descriptor > 0 and
                     descriptor < tasks_list(id).device_id'last
                  );

   procedure remove_device
     (id       : in  ewok.tasks_shared.t_task_id;
      dev_id   : in  ewok.devices_shared.t_device_id;
      success  : out boolean);

   function is_mounted
     (id       : in  ewok.tasks_shared.t_task_id;
      dev_id   : in  ewok.devices_shared.t_device_id)
      return boolean;

   procedure mount_device
     (id       : in  ewok.tasks_shared.t_task_id;
      dev_id   : in  ewok.devices_shared.t_device_id;
      success  : out boolean);

   procedure unmount_device
     (id       : in  ewok.tasks_shared.t_task_id;
      dev_id   : in  ewok.devices_shared.t_device_id;
      success  : out boolean);

end ewok.tasks;
