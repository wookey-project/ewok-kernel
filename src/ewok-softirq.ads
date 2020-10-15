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
with ewok.tasks;
with soc.interrupts;
with rings;

package ewok.softirq
  with spark_mode => on
is

   type t_isr_parameters is record
      handler         : system_address             := 0;
      interrupt       : soc.interrupts.t_interrupt := soc.interrupts.INT_NONE;
      posthook_status : unsigned_32                := 0;
      posthook_data   : unsigned_32                := 0;
   end record;

   type t_isr_request is record
      caller_id   : ewok.tasks_shared.t_task_id    := ID_UNUSED;
      params      : t_isr_parameters               := (others => <>);
   end record;

   type t_soft_parameters is record
      handler     : system_address                 := 0;
      param1      : unsigned_32                    := 0;
      param2      : unsigned_32                    := 0;
      param3      : unsigned_32                    := 0;
   end record;

   type t_soft_request is record
      caller_id   : ewok.tasks_shared.t_task_id    := ID_UNUSED;
      params      : t_soft_parameters              := (others => <>);
   end record;


   -- softirq input queue depth. Can be configured depending
   -- on the devices behavior (IRQ bursts)
   -- defaulting to 20 (see Kconfig)
   MAX_QUEUE_SIZE : constant := $CONFIG_KERNEL_SOFTIRQ_QUEUE_DEPTH;

   package p_isr_requests is new rings
     (t_isr_request, MAX_QUEUE_SIZE, t_isr_request'(others => <>));
   use p_isr_requests;

   package p_soft_requests is new rings
     (t_soft_request, MAX_QUEUE_SIZE, t_soft_request'(others => <>));
   use p_soft_requests;

   isr_queue      : p_isr_requests.ring;
   soft_queue     : p_soft_requests.ring;

   procedure init;

   procedure push_isr
     (task_id     : in  ewok.tasks_shared.t_task_id;
      params      : in  t_isr_parameters);

   procedure push_soft
     (task_id     : in  ewok.tasks_shared.t_task_id;
      params      : in  t_soft_parameters);

   procedure isr_handler (req : in  t_isr_request)
      with global => (in_out => ewok.tasks.tasks_list);

   procedure soft_handler (req : in  t_soft_request)
      with global => (in_out => ewok.tasks.tasks_list);

   procedure main_task
      with global => (in_out => ewok.tasks.tasks_list);

private

   previous_isr_owner : t_task_id := ID_UNUSED;

end ewok.softirq;
