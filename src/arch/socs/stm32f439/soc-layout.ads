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

with types;

package soc.layout
   with spark_mode => on
is

   -- This SoC has two flash bank mapped consecutively, giving access
   -- to 2MB of flash
   FLASH_BASE        : constant system_address := 16#0800_0000#;
   FLASH_SIZE        : constant := 2 * MBYTE;

   SRAM_BASE         : constant system_address := 16#1000_0000#;
   SRAM_SIZE         : constant := 64 * KBYTE;

   BOOT_ROM_BASE     : constant system_address := 16#1FFF_0000#;

   RAM_BASE          : constant system_address := 16#2000_0000#; -- SRAM
   RAM_SIZE          : constant := 128 * KBYTE;

   USER_RAM_BASE     : constant system_address := 16#2000_0000#; -- SRAM
   USER_RAM_SIZE     : constant := 128 * KBYTE;

   KERNEL_RAM_BASE   : constant system_address := 16#1000_0000#;
   KERNEL_RAM_SIZE   : constant := 64 * KBYTE;

   PERIPH_BASE       : constant system_address := 16#4000_0000#;
   MEMORY_BANK1_BASE : constant system_address := 16#6000_0000#;
   MEMORY_BANK2_BASE : constant system_address := MEMORY_BANK1_BASE;

   APB1PERIPH_BASE : constant system_address := PERIPH_BASE;
   APB2PERIPH_BASE : constant system_address := PERIPH_BASE + 16#0001_0000#;
   AHB1PERIPH_BASE : constant system_address := PERIPH_BASE + 16#0002_0000#;
   AHB2PERIPH_BASE : constant system_address := PERIPH_BASE + 16#1000_0000#;

   --
   -- AHB1 peripherals
   --

   GPIOA_BASE : constant system_address := AHB1PERIPH_BASE + 16#0000#;
   GPIOB_BASE : constant system_address := AHB1PERIPH_BASE + 16#0400#;
   GPIOC_BASE : constant system_address := AHB1PERIPH_BASE + 16#0800#;
   GPIOD_BASE : constant system_address := AHB1PERIPH_BASE + 16#0C00#;
   GPIOE_BASE : constant system_address := AHB1PERIPH_BASE + 16#1000#;
   GPIOF_BASE : constant system_address := AHB1PERIPH_BASE + 16#1400#;
   GPIOG_BASE : constant system_address := AHB1PERIPH_BASE + 16#1800#;
   GPIOH_BASE : constant system_address := AHB1PERIPH_BASE + 16#1C00#;
   GPIOI_BASE : constant system_address := AHB1PERIPH_BASE + 16#2000#;

   DMA1_BASE  : constant system_address := AHB1PERIPH_BASE + 16#6000#;
   DMA2_BASE  : constant system_address := AHB1PERIPH_BASE + 16#6400#;

   --
   -- APB2 peripherals
   --

   SYSCFG_BASE : constant system_address := APB2PERIPH_BASE + 16#3800#;

   --
   -- Flash and firmware structure
   --
   --
   -- Flip bank

   FW1_SIZE             : constant unsigned_32 := 576*1024;

   FW1_KERN_BASE        : constant unsigned_32 := 16#0802_0000#;
   FW1_KERN_SIZE        : constant unsigned_32 := 64*1024;

   FW1_USER_BASE        : constant unsigned_32 := 16#0808_0000#;
   FW1_USER_SIZE        : constant unsigned_32 := 512*1024;

   -- DFU 1

   DFU1_SIZE            : constant unsigned_32 := 320*1024;

   DFU1_KERN_BASE       : constant unsigned_32 := 16#0803_0000#;
   DFU1_USER_BASE       : constant unsigned_32 := 16#0804_0000#;

   DFU1_KERN_SIZE       : constant unsigned_32 := 64*1024;
   DFU1_USER_SIZE       : constant unsigned_32 := 256*1024;

   -- Flop bank

   FW2_SIZE             : constant unsigned_32 := 576*1024;

   FW2_KERN_SIZE        : constant unsigned_32 := 64*1024;
   FW2_KERN_BASE        : constant unsigned_32 := 16#0812_0000#;

   FW2_USER_BASE        : constant unsigned_32 := 16#0818_0000#;
   FW2_USER_SIZE        : constant unsigned_32 := 512*1024;


   --  DFU 2
   DFU2_SIZE            : constant unsigned_32 := 320*1024;

   DFU2_KERN_BASE       : constant unsigned_32 := 16#0813_0000#;
   DFU2_KERN_SIZE       : constant unsigned_32 := 64*1024;

   DFU2_USER_BASE       : constant unsigned_32 := 16#0814_0000#;
   DFU2_USER_SIZE       : constant unsigned_32 := 256*1024;

end soc.layout;
