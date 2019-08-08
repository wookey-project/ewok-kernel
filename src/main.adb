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

with interfaces;
with types;       use types;

with m4.cpu.instructions;
with m4.systick;

with soc.dwt;
with soc.rng;
with soc.system;

with ewok.debug;
with ewok.dma;
with ewok.exti;
with ewok.interrupts;
with ewok.memory;
with ewok.softirq;
with ewok.sched;
with ewok.tasks;


procedure main
is

   VTOR_address : system_address
      with
         import,
         convention     => assembly,
         external_name  => "VTOR_address";

   ok    : boolean;

begin

   m4.cpu.disable_irq;

   -- Initialize interrupts, handlers & priorities
   ewok.interrupts.init;

   -- Initialize system Clock
   m4.systick.init;

   -- Configure the USART for debugging purpose
#if CONFIG_KERNEL_SERIAL
#if    CONFIG_KERNEL_USART = 1
   ewok.debug.init (1);
#elsif CONFIG_KERNEL_USART = 4
   ewok.debug.init (4);
#elsif CONFIG_KERNEL_USART = 6
   ewok.debug.init (6);
#else
   raise program_error;
#end if;
#end if;

   -- Initialize DWT (required for precise time measurement)
   soc.dwt.init;

   -- Initialize the platform TRNG
   soc.rng.init (ok);
   if not ok then
      pragma DEBUG (ewok.debug.log (ewok.debug.ERROR, "Unable to use TRNG"));
   end if;

   -- Initialize DMA controllers
   ewok.dma.init;

   -- Initialize the EXTIs
   ewok.exti.init;

   -- The kernel is a PIE executable. Its base address is given in first
   -- argument, based on the loader informations
   soc.system.init (VTOR_address);

   -- Initialize the memory (MPU or MMU)
   -- After this sequence, the kernel is executed with restricted rights and
   -- invalid accesses can generate memory faults.
   ewok.memory.init (ok);
   if not ok then
      ewok.debug.panic ("Memory configuration failed!");
   end if;

   m4.cpu.instructions.full_memory_barrier;

   -- Create user tasks
   ewok.tasks.task_init;

   -- Initialize SOFTIRQ thread
   ewok.softirq.init;

   -- Let's run tasks!
   ewok.sched.init;

   ewok.debug.panic ("Why am I here?");

end main;
