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
with soc.devmap; use soc.devmap;
with soc.pwr;
with soc.flash;
with soc.rcc.default;

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
           (PLLM   => default.PLL_M, -- Division factor for the main PLL
            PLLN   => default.PLL_N, -- Main PLL multiplication factor for VCO
            PLLP   => default.PLL_P, -- Main PLL division factor for main system clock
            PLLSRC => (if enable_hse then 1 else 0),
               -- HSE or HSI oscillator clock selected as PLL
            PLLQ   => default.PLL_Q);
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
                                              -- SPA or DPA side channel attacks
      soc.flash.FLASH.ACR.LATENCY   := 5;    -- Latency = 5 wait states

      -- Set clock dividers
      RCC.CFGR.HPRE  := default.AHB_DIV;  -- AHB prescaler
      RCC.CFGR.PPRE1 := default.APB1_DIV; -- APB1 low speed prescaler
      RCC.CFGR.PPRE2 := default.APB2_DIV; -- APB2 high speed prescaler

      if enable_pll then
         RCC.CFGR.SW := 2#10#; -- PLL selected as system clock
         loop
            exit when RCC.CFGR.SWS = 2#10#;
         end loop;
      end if;

      return types.c.SUCCESS;
   end init;


   procedure enable_clock (periph : in soc.devmap.t_periph_id)
   is
   begin
      case periph is
         when NO_PERIPH => return;
         when DMA1_INFO .. DMA1_STR7   => soc.rcc.RCC.AHB1ENR.DMA1EN := true;
         when DMA2_INFO .. DMA2_STR7   => soc.rcc.RCC.AHB1ENR.DMA2EN := true;
         when CRYP_CFG .. CRYP         => soc.rcc.RCC.AHB2ENR.CRYPEN := true;
         when HASH                     => soc.rcc.RCC.AHB2ENR.HASHEN := true;
         when USB_OTG_FS               => soc.rcc.RCC.AHB2ENR.OTGFSEN := true;
         when USB_OTG_HS               =>
                           soc.rcc.RCC.AHB1ENR.OTGHSEN      := true;
                           soc.rcc.RCC.AHB1ENR.OTGHSULPIEN  := true;
         when SDIO      => soc.rcc.RCC.APB2ENR.SDIOEN    := true;
         when ETH_MAC   => soc.rcc.RCC.AHB1ENR.ETHMACEN  := true;
         when CRC       => soc.rcc.RCC.AHB1ENR.CRCEN     := true;
         when SPI1      => soc.rcc.RCC.APB2ENR.SPI1EN    := true;
         when SPI2      => soc.rcc.RCC.APB1ENR.SPI2EN    := true;
         when SPI3      => soc.rcc.RCC.APB1ENR.SPI3EN    := true;
         when I2C1      => soc.rcc.RCC.APB1ENR.I2C1EN    := true;
         when I2C2      => soc.rcc.RCC.APB1ENR.I2C2EN    := true;
         when I2C3      => soc.rcc.RCC.APB1ENR.I2C3EN    := true;
         when CAN1      => soc.rcc.RCC.APB1ENR.CAN1EN    := true;
         when CAN2      => soc.rcc.RCC.APB1ENR.CAN2EN    := true;
         when USART1    => soc.rcc.RCC.APB2ENR.USART1EN  := true;
         when USART6    => soc.rcc.RCC.APB2ENR.USART6EN  := true;
         when USART2    => soc.rcc.RCC.APB1ENR.USART2EN  := true;
         when USART3    => soc.rcc.RCC.APB1ENR.USART3EN  := true;
         when UART4     => soc.rcc.RCC.APB1ENR.UART4EN   := true;
         when UART5     => soc.rcc.RCC.APB1ENR.UART5EN   := true;
         when TIM1      => soc.rcc.RCC.APB2ENR.TIM1EN    := true;
         when TIM8      => soc.rcc.RCC.APB2ENR.TIM8EN    := true;
         when TIM9      => soc.rcc.RCC.APB2ENR.TIM9EN    := true;
         when TIM10     => soc.rcc.RCC.APB2ENR.TIM10EN   := true;
         when TIM11     => soc.rcc.RCC.APB2ENR.TIM11EN   := true;
         when TIM2      => soc.rcc.RCC.APB1ENR.TIM2EN    := true;
         when TIM3      => soc.rcc.RCC.APB1ENR.TIM3EN    := true;
         when TIM4      => soc.rcc.RCC.APB1ENR.TIM4EN    := true;
         when TIM5      => soc.rcc.RCC.APB1ENR.TIM5EN    := true;
         when TIM6      => soc.rcc.RCC.APB1ENR.TIM6EN    := true;
         when TIM7      => soc.rcc.RCC.APB1ENR.TIM7EN    := true;
         when TIM12     => soc.rcc.RCC.APB1ENR.TIM12EN   := true;
         when TIM13     => soc.rcc.RCC.APB1ENR.TIM13EN   := true;
         when TIM14     => soc.rcc.RCC.APB1ENR.TIM14EN   := true;
         when FLASH_CTRL ..  FLASH_FLOP => null;
      end case;
   end enable_clock;

end soc.rcc;
