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
with ewok.tasks_shared; use ewok.tasks_shared;
with soc.interrupts;
with rings;

package ewok.softirq
  with spark_mode => off
is

   type t_state is (DONE, WAITING);

   type t_isr_parameters is record
      handler           : system_address;
      interrupt         : soc.interrupts.t_interrupt;
      posthook_status   : unsigned_32;
      posthook_data     : unsigned_32;
   end record;

   type t_isr_request is record
      caller_id   : ewok.tasks_shared.t_task_id;
      state       : t_state;
      params      : t_isr_parameters;
   end record;

   type t_syscall_request is record
      caller_id   : ewok.tasks_shared.t_task_id;
      state       : t_state;
   end record;

   -- softirq input queue depth. Can be configured depending
   -- on the devices behavior (IRQ bursts)
   -- defaulting to 20 (see Kconfig)
   MAX_QUEUE_SIZE : constant := $CONFIG_KERNEL_SOFTIRQ_QUEUE_DEPTH;

   package p_isr_requests is new rings (t_isr_request, MAX_QUEUE_SIZE);
   use p_isr_requests;

   isr_queue      : p_isr_requests.ring;

   package p_syscall_requests is new rings (t_syscall_request, MAX_QUEUE_SIZE);
   use p_syscall_requests;

   syscall_queue  : p_syscall_requests.ring;

   procedure init
   with
      convention     => c,
      export         => true,
      external_name  => "softirq_init",
      global         => null;

   procedure push_isr
     (task_id     : in  ewok.tasks_shared.t_task_id;
      params      : in  t_isr_parameters);

   procedure push_syscall
     (task_id     : in  ewok.tasks_shared.t_task_id);

   procedure syscall_handler (req : in  t_syscall_request);

   procedure isr_handler (req : in  t_isr_request);

   procedure main_task;

private

   previous_isr_owner : t_task_id := ID_UNUSED;

end ewok.softirq;
