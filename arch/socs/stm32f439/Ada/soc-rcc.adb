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
with soc.pwr;
with soc.flash;

package body soc.rcc
   with spark_mode => off
is

   procedure reset
   is

      function to_rcc_cfgr is new ada.unchecked_conversion
        (unsigned_32, t_RCC_CFGR);

      function to_rcc_pllcfgr is new ada.unchecked_conversion
        (unsigned_32, t_RCC_PLLCFGR);

   begin
      RCC.CR.HSION   := true;
      RCC.CFGR       := to_rcc_cfgr (0);
      RCC.CR.HSEON   := false;
      RCC.CR.CSSON   := false;
      RCC.CR.PLLON   := false;

      -- Magic number. Cf. STM32F4 datasheet
      RCC.PLLCFGR    := to_rcc_pllcfgr (16#2400_3010#);

      RCC.CR.HSEBYP  := false;
      RCC.CIR        := 0;             -- Reset all interrupts
   end reset;


   function init
     (enable_hse  : types.c.bool;
      enable_pll  : types.c.bool)
      return types.c.t_retval
   is
   begin

      -- Power interface clock enable
      RCC.APB1ENR.PWREN := true;

      -- Regulator voltage scaling output selection
      -- This bit controls the main internal voltage regulator output voltage
      -- to achieve a trade-off between performance and power consumption when
      -- the device does not operate at the maximum frequency.
      soc.pwr.PWR.CR.VOS := soc.pwr.VOS_SCALE1;

      if enable_hse then
         RCC.CR.HSEON   := true;
         loop
            exit when RCC.CR.HSERDY;
         end loop;

      else -- Enable HSI
         RCC.CR.HSION   := true;
         loop
            exit when RCC.CR.HSIRDY;
         end loop;
      end if;

      if enable_pll then
         RCC.CR.PLLON := false;
         RCC.PLLCFGR :=
           (PLLM   => 16,  -- Division factor for the main PLL
            PLLN   => 336, -- Main PLL multiplication factor for VCO
            PLLP   => 0,   -- Main PLL division factor for main system clock. PLLP = 2
            PLLSRC => (if enable_hse then 1 else 0),
               -- HSE or HSI oscillator clock selected as PLL
            PLLQ   => 7);
               -- Main PLL division factor for USB OTG FS, SDIO and random
               -- number generator
         -- Enable the main PLL
         RCC.CR.PLLON := true;
         loop
            exit when RCC.CR.PLLRDY;
         end loop;
      end if;

      -- Configuring flash (prefetch, instruction cache, data cache, wait state)
      soc.flash.FLASH.ACR.ICEN      := true; -- Instruction cache enable
      soc.flash.FLASH.ACR.DCEN      := true; -- Data cache is enabled
      soc.flash.FLASH.ACR.PRFTEN    := false; -- Prefetch is disabled to avoid 
                                              -- spectre/meltdown like attacks
      soc.flash.FLASH.ACR.LATENCY   := 5;    -- Latency = 5 wait states

      -- Set clock dividers
      RCC.CFGR.HPRE  := 2#0000#; -- AHB prescaler, not divided
      RCC.CFGR.PPRE1 := 2#101#;  -- APB1 low speed prescaler, divided by 4
      RCC.CFGR.PPRE2 := 2#100#;  -- APB2 high speed prescaler, divided by 2

      if enable_pll then
         RCC.CFGR.SW := 2#10#; -- PLL selected as system clock
         loop
            exit when RCC.CFGR.SWS = 2#10#;
         end loop;
      end if;

      return types.c.SUCCESS;
   end init;

end soc.rcc;
