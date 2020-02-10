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


with config;
with config.memlayout; use config.memlayout;

package ewok.layout
   with spark_mode => on
is

   VTORS_SIZE  : constant := 392;

   FLASH_SIZE     : constant := 1024 * KBYTE;

   LDR_BASE       : constant system_address := 16#0800_0000#;
   LDR_SIZE       : constant := 32 * KBYTE;

   SHR_BASE       : constant system_address := 16#0800_8000#;
   SHR_SIZE       : constant := 32 * KBYTE;

   --   +----------------+ <- 16#top_kernel_ram#
   --   |  IDLE_STACK    | 4K
   --   +----------------+
   --   |  SOFTIRQ_STACK | 4K
   --   +----------------+
   --   |  ISR_STACK     | 4K
   --   +----------------+
   --   |  INITIAL_STACK | downto bottom kernel ram
   --   +----------------+
   --

   STACK_TOP_IDLE       : constant system_address :=
      config.memlayout.kernel_region.ram_memory_addr
      + config.memlayout.kernel_region.ram_memory_size;

   STACK_SIZE_IDLE      : constant := 4 * KBYTE;

   STACK_TOP_SOFTIRQ    : constant system_address :=
      STACK_TOP_IDLE
      - STACK_SIZE_IDLE;

   STACK_SIZE_SOFTIRQ   : constant := 4 * KBYTE;

   STACK_TOP_TASK_ISR   : constant system_address :=
      STACK_TOP_SOFTIRQ
      - STACK_SIZE_SOFTIRQ;

   STACK_SIZE_TASK_ISR  : constant := 4 * KBYTE;

   STACK_BOTTOM_TASK_ISR   : constant system_address :=
      STACK_TOP_TASK_ISR
      - STACK_SIZE_TASK_ISR;

   -- Transient stack. Used only during kernel initialization
   STACK_TOP_TASK_INITIAL  : constant system_address := STACK_BOTTOM_TASK_ISR;

end ewok.layout;

