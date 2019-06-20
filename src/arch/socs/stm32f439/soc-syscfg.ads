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
with soc.gpio;
with system;

package soc.syscfg
   with spark_mode => off
is

   --------------------------------------------------
   -- SYSCFG memory remap register (SYSCFG_MEMRMP) --
   --------------------------------------------------

   type t_SYSCFG_MEMRMP is record
      MEM_MODE       : bits_3;
      reserved_3_7   : bits_5;
      FB_MODE        : bit;
      reserved_9     : bit;
      SWP_FMC        : bits_2;
      reserved_12_15 : bits_4;
      reserved_16_31 : unsigned_16;
   end record
      with volatile_full_access, size => 32;

   for t_SYSCFG_MEMRMP use record
      MEM_MODE       at 0 range  0 ..  2;
      reserved_3_7   at 0 range  3 ..  7;
      FB_MODE        at 0 range  8 ..  8;
      reserved_9     at 0 range  9 ..  9;
      SWP_FMC        at 0 range 10 .. 11;
      reserved_12_15 at 0 range 12 .. 15;
      reserved_16_31 at 0 range 16 .. 31;
   end record;

   ----------------------------------------------------------------
   -- SYSCFG peripheral mode configuration register (SYSCFG_PMC) --
   ----------------------------------------------------------------

   type t_SYSCFG_PMC is record
      reserved_0_15  : unsigned_16;
      ADC1DC2        : bit;
      ADC2DC2        : bit;
      ADC3DC2        : bit;
      reserved_19_22 : bits_4;
      MII_RMII_SEL   : bit;
      reserved_24_31 : byte;
   end record
      with volatile_full_access, size => 32;

   for t_SYSCFG_PMC use record
      reserved_0_15  at 0 range  0 .. 15;
      ADC1DC2        at 0 range 16 .. 16;
      ADC2DC2        at 0 range 17 .. 17;
      ADC3DC2        at 0 range 18 .. 18;
      reserved_19_22 at 0 range 19 .. 22;
      MII_RMII_SEL   at 0 range 23 .. 23;
      reserved_24_31 at 0 range 24 .. 31;
   end record;

   ------------------------------------------------------------------------
   -- SYSCFG external interrupt configuration registers (SYSCFG_EXTICRx) --
   ------------------------------------------------------------------------
   type t_exticr_list is
      array (soc.gpio.t_gpio_pin_index range <>) of soc.gpio.t_gpio_port_index
      with pack;

   type t_SYSCFG_EXTICR1 is record
      exti     : t_exticr_list (0 .. 3);
      reserved : short;
   end record
      with pack, size => 32, volatile_full_access;

   type t_SYSCFG_EXTICR2 is record
      exti     : t_exticr_list (4 .. 7);
      reserved : short;
   end record
      with pack, size => 32, volatile_full_access;

   type t_SYSCFG_EXTICR3 is record
      exti     : t_exticr_list (8 .. 11);
      reserved : short;
   end record
      with pack, size => 32, volatile_full_access;

   type t_SYSCFG_EXTICR4 is record
      exti     : t_exticr_list (12 .. 15);
      reserved : short;
   end record
      with pack, size => 32, volatile_full_access;

   -------------------------------------------------------
   -- Compensation cell control register (SYSCFG_CMPCR) --
   -------------------------------------------------------

   type t_SYSCFG_CMPCR is record
      CMP_PD         : bit;
      reserved_1_6   : bits_6;
      READY          : bit;
      reserved_8_15  : byte;
      reserved_16_31 : unsigned_16;
   end record
      with volatile_full_access, size => 32;

   for t_SYSCFG_CMPCR use record
      CMP_PD          at 0 range  0 ..  0;
      reserved_1_6    at 0 range  1 ..  6;
      READY           at 0 range  7 ..  7;
      reserved_8_15   at 0 range  8 .. 15;
      reserved_16_31  at 0 range 16 .. 31;
   end record;

   -----------------------
   -- SYSCFG peripheral --
   -----------------------

   type t_SYSCFG_periph is record
      MEMRMP   : t_SYSCFG_MEMRMP;
      PMC      : t_SYSCFG_PMC;
      EXTICR1  : t_SYSCFG_EXTICR1;
      EXTICR2  : t_SYSCFG_EXTICR2;
      EXTICR3  : t_SYSCFG_EXTICR3;
      EXTICR4  : t_SYSCFG_EXTICR4;
      CMPCR    : t_SYSCFG_CMPCR;
   end record
      with volatile;

   for t_SYSCFG_periph use record
      MEMRMP    at 16#00# range 0 .. 31;
      PMC       at 16#04# range 0 .. 31;
      EXTICR1   at 16#08# range 0 .. 31;
      EXTICR2   at 16#0C# range 0 .. 31;
      EXTICR3   at 16#10# range 0 .. 31;
      EXTICR4   at 16#14# range 0 .. 31;
      CMPCR     at 16#20# range 0 .. 31;
   end record;

   SYSCFG : t_SYSCFG_periph
      with
         import,
         volatile,
         address => system'to_address (soc.layout.SYSCFG_BASE); -- 0x40013800


   function get_exti_port
     (pin : soc.gpio.t_gpio_pin_index)
      return soc.gpio.t_gpio_port_index;

   procedure set_exti_port
     (pin   : in soc.gpio.t_gpio_pin_index;
      port  : in soc.gpio.t_gpio_port_index);

end soc.syscfg;
