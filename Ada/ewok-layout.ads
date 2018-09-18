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


with soc.layout;

package ewok.layout
   with spark_mode => on
is

   VTORS_SIZE  : constant := 392;

   --   +----------------+0x0800 0000
   --   |  LDR (32k)     |
   --   +----------------+0x0800 8000
   --   |  SHR (32k)     |
   --   +----------------+0x0801 0000
   --   |  DFU1_k (64k)  |
   --   + - - - - - - - -+0x0802 0000
   --   |  DFU1_u (64k)  |
   --   +----------------+0x0803 0000
   --   |  FW1_k  (64k)  |
   --   + - - - - - - - -+0x0804 0000
   --   |                |
   --   |  FW1_u (256k)  |
   --   |                |
   --   +----------------+0x0808 0000
   --   |                |
   --   |  FW2_u (256k)  |
   --   |                |
   --   + - - - - - - - -+0x080c 0000
   --   |  FW2_k  (64k)  |
   --   +----------------+0x080d 0000
   --   |  DFU2_k (64k)  |
   --   + - - - - - - - -+0x080e 0000
   --   |  DFU2_u (64k)  |
   --   +----------------+0x080f 0000

   FLASH_SIZE     : constant := 1024 * KBYTE;

   LDR_BASE       : constant system_address := 16#0800_0000#;
   LDR_SIZE       : constant := 32 * KBYTE;

   SHR_BASE       : constant system_address := 16#0800_8000#;
   SHR_SIZE       : constant := 32 * KBYTE;

   --
   -- DFU 1
   --

   DFU1_BASE      : constant system_address := 16#0801_0000#;
   DFU1_SIZE      : constant := 128 * KBYTE;
   DFU1_KERN_BASE : constant system_address := DFU1_BASE;
   DFU1_KERN_SIZE : constant := 64 * KBYTE;
   DFU1_START     : constant system_address := DFU1_KERN_BASE + VTORS_SIZE + 1;
   DFU1_USER_BASE : constant system_address := DFU1_KERN_BASE + DFU1_KERN_SIZE;
   DFU1_USER_SIZE : constant := 64 * KBYTE;

   --
   -- Firmware 1
   --

   FW1_BASE       : constant system_address := 16#0803_0000#;
   FW1_SIZE       : constant := 320 * KBYTE;
   FW1_KERN_BASE  : constant system_address := FW1_BASE;
   FW1_KERN_SIZE  : constant := 64 * KBYTE;
   FW1_START      : constant system_address := FW1_KERN_BASE + VTORS_SIZE + 1;
   FW1_USER_BASE  : constant system_address := FW1_KERN_BASE + FW1_KERN_SIZE;
   FW1_USER_SIZE  : constant := 256 * KBYTE;

   --
   -- Firmware 2
   --

   FW2_BASE       : constant system_address := 16#0808_0000#;
   FW2_SIZE       : constant := 320 * KBYTE;
   FW2_USER_BASE  : constant system_address := FW2_BASE;
   FW2_USER_SIZE  : constant := 256 * KBYTE;
   FW2_KERN_BASE  : constant system_address := FW2_USER_BASE + FW2_USER_SIZE;
   FW2_START	   : constant system_address := FW2_KERN_BASE + VTORS_SIZE + 1;
   FW2_KERN_SIZE  : constant := 64 * KBYTE;



   DFU2_BASE      : constant system_address := 16#080d_0000#;
   DFU2_START     : constant system_address := DFU2_BASE + VTORS_SIZE + 1;

   DFU2_KERN_BASE : constant system_address := DFU2_BASE;
   DFU2_USER_BASE : constant system_address := DFU2_BASE + (64*KBYTE);

   DFU2_SIZE      : constant := 128 * KBYTE;
   DFU2_KERN_SIZE : constant := 64 * KBYTE;
   DFU2_USER_SIZE : constant := 64 * KBYTE;

   ---------------------------------------------------------------

   --   +----------------+ <- 16#1001_0000#
   --   |  IDLE_STACK    |
   --   +----------------+ <- 16#1000_F000#
   --   |  SOFTIRQ_STACK |
   --   |                |
   --   +----------------+ <- 16#1000_D000#
   --   |  ISR_STACK     |
   --   +----------------+ <- 16#1000_C000#
   --   |  INITIAL_STACK |
   --   +----------------+
   --

   KERN_DATA_BASE  : constant system_address := 16#1000_0000#;
   KERN_DATA_SIZE  : constant := 64 * KBYTE;

   USER_DATA_BASE  : constant system_address := soc.layout.RAM_BASE;

   LDR_DATA_BASE   : constant system_address := 16#2001_c000#;
   LDR_DATA_SIZE   : constant := 16 * KBYTE;

   STACK_TOP_IDLE       : constant system_address := KERN_DATA_BASE + KERN_DATA_SIZE;
   STACK_SIZE_IDLE      : constant := 4 * KBYTE;

   STACK_TOP_SOFTIRQ    : constant system_address := STACK_TOP_IDLE - STACK_SIZE_IDLE;
   STACK_SIZE_SOFTIRQ   : constant := 8 * KBYTE;

   STACK_TOP_TASK_ISR   : constant system_address := STACK_TOP_SOFTIRQ - STACK_SIZE_SOFTIRQ;
   STACK_SIZE_TASK_ISR  : constant := 4 * KBYTE;
   STACK_BOTTOM_TASK_ISR   : constant system_address := STACK_TOP_TASK_ISR - STACK_SIZE_TASK_ISR;

   -- Transient stack. Used only during kernel initialization
   STACK_TOP_TASK_INITIAL  : constant system_address := STACK_BOTTOM_TASK_ISR;

   ---------------------------------------------------------------
   ---------------------------------------------------------------

   FW_MAX_USER_SIZE : constant := 64 * KBYTE;
   DFU_MAX_USER_SIZE : constant := 32 * KBYTE;

   FW_MAX_USER_DATA : constant := 8 * KBYTE;
   USER_RAM_SIZE   : constant := 128 * KBYTE;
   USER_DATA_SIZE  : constant := 16 * KBYTE;

   FW1_APP1_BASE : constant system_address := FW1_USER_BASE;
   FW1_APP2_BASE : constant system_address := FW1_USER_BASE + (1 * FW_MAX_USER_SIZE);
   FW1_APP3_BASE : constant system_address := FW1_USER_BASE + (2 * FW_MAX_USER_SIZE);
   FW1_APP4_BASE : constant system_address := FW1_USER_BASE + (3 * FW_MAX_USER_SIZE);
   FW1_APP5_BASE : constant system_address := FW1_USER_BASE + (4 * FW_MAX_USER_SIZE);
   FW1_APP6_BASE : constant system_address := FW1_USER_BASE + (5 * FW_MAX_USER_SIZE); 
   FW1_APP7_BASE : constant system_address := FW1_USER_BASE + (6 * FW_MAX_USER_SIZE);
   FW1_APP8_BASE : constant system_address := FW1_USER_BASE + (7 * FW_MAX_USER_SIZE); 

   FW2_APP1_BASE : constant system_address := FW2_USER_BASE;
   FW2_APP2_BASE : constant system_address := FW2_USER_BASE + (1 * FW_MAX_USER_SIZE);
   FW2_APP3_BASE : constant system_address := FW2_USER_BASE + (2 * FW_MAX_USER_SIZE);
   FW2_APP4_BASE : constant system_address := FW2_USER_BASE + (3 * FW_MAX_USER_SIZE);
   FW2_APP5_BASE : constant system_address := FW2_USER_BASE + (4 * FW_MAX_USER_SIZE);
   FW2_APP6_BASE : constant system_address := FW2_USER_BASE + (5 * FW_MAX_USER_SIZE);
   FW2_APP7_BASE : constant system_address := FW2_USER_BASE + (6 * FW_MAX_USER_SIZE);
   FW2_APP8_BASE : constant system_address := FW2_USER_BASE + (7 * FW_MAX_USER_SIZE);


   USER_APP1_DATA_BASE  : constant system_address := soc.layout.RAM_BASE;
   USER_APP2_DATA_BASE  : constant system_address := soc.layout.RAM_BASE + (1 * USER_DATA_SIZE);
   USER_APP3_DATA_BASE  : constant system_address := soc.layout.RAM_BASE + (2 * USER_DATA_SIZE);
   USER_APP4_DATA_BASE  : constant system_address := soc.layout.RAM_BASE + (3 * USER_DATA_SIZE);
   USER_APP5_DATA_BASE  : constant system_address := soc.layout.RAM_BASE + (4 * USER_DATA_SIZE);
   USER_APP6_DATA_BASE  : constant system_address := soc.layout.RAM_BASE + (5 * USER_DATA_SIZE);
   USER_APP7_DATA_BASE  : constant system_address := soc.layout.RAM_BASE + (6 * USER_DATA_SIZE);
   USER_APP8_DATA_BASE  : constant system_address := soc.layout.RAM_BASE + (7 * USER_DATA_SIZE); -- SHM 
end ewok.layout;

