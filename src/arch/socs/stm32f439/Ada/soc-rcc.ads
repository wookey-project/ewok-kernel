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

with system;
with soc.devmap;

package soc.rcc
   with spark_mode => off
is

   -----------------------------------------
   -- RCC clock control register (RCC_CR) --
   -----------------------------------------

   type t_RCC_CR is record
      HSION          : boolean;  -- Internal high-speed clock enable
      HSIRDY         : boolean;  -- Internal high-speed clock ready flag
      Reserved_2_2   : bit;
      HSITRIM        : bits_5;      -- Internal high-speed clock trimming
      HSICAL         : unsigned_8;  -- Internal high-speed clock calibration
      HSEON          : boolean;  -- HSE clock enable
      HSERDY         : boolean;  -- HSE clock ready flag
      HSEBYP         : boolean;  -- HSE clock bypassed (with an ext. clock)
      CSSON          : boolean;  -- Clock security system enable
      Reserved_20_23 : bits_4;
      PLLON          : boolean;  -- Main PLL enable
      PLLRDY         : boolean;  -- Main PLL clock ready flag
      PLLI2SON       : boolean;  -- PLLI2S enable
      PLLI2SRDY      : boolean;  -- PLLI2S clock ready flag
      PLLSAION       : boolean;  -- PLLSAI enable
      PLLSAIRDY      : boolean;  -- PLLSAI clock ready flag
      Reserved_30_31 : bits_2;
   end record
     with volatile_full_access, size => 32;

   for t_RCC_CR use record
      HSION          at 0 range 0 .. 0;
      HSIRDY         at 0 range 1 .. 1;
      Reserved_2_2   at 0 range 2 .. 2;
      HSITRIM        at 0 range 3 .. 7;
      HSICAL         at 0 range 8 .. 15;
      HSEON          at 0 range 16 .. 16;
      HSERDY         at 0 range 17 .. 17;
      HSEBYP         at 0 range 18 .. 18;
      CSSON          at 0 range 19 .. 19;
      Reserved_20_23 at 0 range 20 .. 23;
      PLLON          at 0 range 24 .. 24;
      PLLRDY         at 0 range 25 .. 25;
      PLLI2SON       at 0 range 26 .. 26;
      PLLI2SRDY      at 0 range 27 .. 27;
      PLLSAION       at 0 range 28 .. 28;
      PLLSAIRDY      at 0 range 29 .. 29;
      Reserved_30_31 at 0 range 30 .. 31;
   end record;

   --------------------------------------------------
   -- RCC PLL configuration register (RCC_PLLCFGR) --
   --------------------------------------------------

   type t_PLLP is
     (PLLP2, PLLP4, PLLP6, PLLP8)
      with size => 2;

   for t_PLLP use
     (PLLP2 => 2#00#,
      PLLP4 => 2#01#,
      PLLP6 => 2#10#,
      PLLP8 => 2#11#);

   type t_RCC_PLLCFGR is record
      PLLM           : bits_6;
      PLLN           : bits_9;
      PLLP           : t_PLLP;
      PLLSRC         : bit;
      PLLQ           : bits_4;
   end record
      with size => 32, volatile_full_access;

   for t_RCC_PLLCFGR use record
      PLLM           at 0 range 0 .. 5;
      PLLN           at 0 range 6 .. 14;
      PLLP           at 0 range 16 .. 17;
      PLLSRC         at 0 range 22 .. 22;
      PLLQ           at 0 range 24 .. 27;
   end record;

   PLLCFGR_RESET : constant unsigned_32 := 16#2400_3010#;

   -------------------------------------------------
   -- RCC clock configuration register (RCC_CFGR) --
   -------------------------------------------------

   type t_HPRE is
     (HPRE_NODIV,
      HPRE_DIV2,
      HPRE_DIV4,
      HPRE_DIV8,
      HPRE_DIV16,
      HPRE_DIV64,
      HPRE_DIV128,
      HPRE_DIV256,
      HPRE_DIV512)
      with size => 4;

   for t_HPRE use
     (HPRE_NODIV  => 2#0000#,
      HPRE_DIV2   => 2#1000#,
      HPRE_DIV4   => 2#1001#,
      HPRE_DIV8   => 2#1010#,
      HPRE_DIV16  => 2#1011#,
      HPRE_DIV64  => 2#1100#,
      HPRE_DIV128 => 2#1101#,
      HPRE_DIV256 => 2#1110#,
      HPRE_DIV512 => 2#1111#);

   type t_PPRE is
     (PPRE_NODIV,
      PPRE_DIV2,
      PPRE_DIV4,
      PPRE_DIV8,
      PPRE_DIV16)
      with size => 3;

   for t_PPRE use
     (PPRE_NODIV => 2#000#,
      PPRE_DIV2  => 2#100#,
      PPRE_DIV4  => 2#101#,
      PPRE_DIV8  => 2#110#,
      PPRE_DIV16 => 2#111#);

   type t_RCC_CFGR is record
      SW             : bits_2;   -- System clock switch
      SWS            : bits_2;   -- System clock switch status
      HPRE           : t_HPRE;   -- AHB prescaler
      reserved_8_9   : bits_2;
      PPRE1          : t_PPRE;   -- APB Low speed prescaler (APB1)
      PPRE2          : t_PPRE;   -- APB high-speed prescaler (APB2)
      RTCPRE         : bits_5;   -- HSE division factor for RTC clock
      MCO1           : bits_2;   -- Microcontroller clock output 1
      I2SSCR         : bit;      -- I2S clock selection
      MCO1PRE        : bits_3;   -- MCO1 prescaler
      MCO2PRE        : bits_3;   -- MCO2 prescaler
      MCO2           : bits_2;   -- Microcontroller clock output 2
   end record
      with size => 32, volatile_full_access;

   for t_RCC_CFGR use record
      SW             at 0 range 0 .. 1;
      SWS            at 0 range 2 .. 3;
      HPRE           at 0 range 4 .. 7;
      reserved_8_9   at 0 range 8 .. 9;
      PPRE1          at 0 range 10 .. 12;
      PPRE2          at 0 range 13 .. 15;
      RTCPRE         at 0 range 16 .. 20;
      MCO1           at 0 range 21 .. 22;
      I2SSCR         at 0 range 23 .. 23;
      MCO1PRE        at 0 range 24 .. 26;
      MCO2PRE        at 0 range 27 .. 29;
      MCO2           at 0 range 30 .. 31;
   end record;

   ------------------------------------------------------
   -- RCC AHB1 peripheral clock register (RCC_AHB1ENR) --
   ------------------------------------------------------

   type t_RCC_AHB1ENR is record
      GPIOAEN        : boolean;   -- IO port A clock enable
      GPIOBEN        : boolean;   -- IO port B clock enable
      GPIOCEN        : boolean;   -- IO port C clock enable
      GPIODEN        : boolean;   -- IO port D clock enable
      GPIOEEN        : boolean;   -- IO port E clock enable
      GPIOFEN        : boolean;   -- IO port F clock enable
      GPIOGEN        : boolean;   -- IO port G clock enable
      GPIOHEN        : boolean;   -- IO port H clock enable
      GPIOIEN        : boolean;   -- IO port I clock enable
      reserved_9_11  : bits_3;
      CRCEN          : boolean;   -- CRC clock enable
      reserved_13_17 : bits_5;
      BKPSRAMEN      : boolean;   -- Backup SRAM interface clock enable
      reserved_19    : bit;
      CCMDATARAMEN   : boolean;   -- CCM data RAM clock enable
      DMA1EN         : boolean;   -- DMA1 clock enable
      DMA2EN         : boolean;   -- DMA2 clock enable
      reserved_23_24 : bits_2;
      ETHMACEN       : boolean;   -- Ethernet MAC clock enable
      ETHMACTXEN     : boolean;   -- Ethernet Transmission clock enable
      ETHMACRXEN     : boolean;   -- Ethernet Reception clock enable
      ETHMACPTPEN    : boolean;   -- Ethernet PTP clock enable
      OTGHSEN        : boolean;   -- USB OTG HS clock enable
      OTGHSULPIEN    : boolean;   -- USB OTG HSULPI clock enable
      reserved_31    : bit;
   end record
      with size => 32, volatile_full_access;

   for t_RCC_AHB1ENR use record
      GPIOAEN        at 0 range 0 .. 0;
      GPIOBEN        at 0 range 1 .. 1;
      GPIOCEN        at 0 range 2 .. 2;
      GPIODEN        at 0 range 3 .. 3;
      GPIOEEN        at 0 range 4 .. 4;
      GPIOFEN        at 0 range 5 .. 5;
      GPIOGEN        at 0 range 6 .. 6;
      GPIOHEN        at 0 range 7 .. 7;
      GPIOIEN        at 0 range 8 .. 8;
      reserved_9_11  at 0 range 9 .. 11;
      CRCEN          at 0 range 12 .. 12;
      reserved_13_17 at 0 range 13 .. 17;
      BKPSRAMEN      at 0 range 18 .. 18;
      reserved_19    at 0 range 19 .. 19;
      CCMDATARAMEN   at 0 range 20 .. 20;
      DMA1EN         at 0 range 21 .. 21;
      DMA2EN         at 0 range 22 .. 22;
      reserved_23_24 at 0 range 23 .. 24;
      ETHMACEN       at 0 range 25 .. 25;
      ETHMACTXEN     at 0 range 26 .. 26;
      ETHMACRXEN     at 0 range 27 .. 27;
      ETHMACPTPEN    at 0 range 28 .. 28;
      OTGHSEN        at 0 range 29 .. 29;
      OTGHSULPIEN    at 0 range 30 .. 30;
      reserved_31    at 0 range 31 .. 31;
   end record;

   -------------------------------------------------------------
   -- RCC AHB2 peripheral clock enable register (RCC_AHB2ENR) --
   -------------------------------------------------------------

   type t_RCC_AHB2ENR is record
      DCMIEN         : boolean;   -- DCMI clock enable
      reserved_1_3   : bits_3;
      CRYPEN         : boolean;   -- CRYP clock enable
      HASHEN         : boolean;   -- HASH clock enable
      RNGEN          : boolean;   -- RNG clock enable
      OTGFSEN        : boolean;   -- USB OTG Full Speed clock enable
   end record
      with size => 32, volatile_full_access;

   for t_RCC_AHB2ENR use record
      DCMIEN         at 0 range 0 .. 0;
      reserved_1_3   at 0 range 1 .. 3;
      CRYPEN         at 0 range 4 .. 4;
      HASHEN         at 0 range 5 .. 5;
      RNGEN          at 0 range 6 .. 6;
      OTGFSEN        at 0 range 7 .. 7;
   end record;

   -------------------------------------------------------------
   -- RCC APB1 peripheral clock enable register (RCC_APB1ENR) --
   -------------------------------------------------------------

   type t_RCC_APB1ENR is record
      TIM2EN         : boolean;  -- TIM2 clock enable
      TIM3EN         : boolean;  -- TIM3 clock enable
      TIM4EN         : boolean;  -- TIM4 clock enable
      TIM5EN         : boolean;  -- TIM5 clock enable
      TIM6EN         : boolean;  -- TIM6 clock enable
      TIM7EN         : boolean;  -- TIM7 clock enable
      TIM12EN        : boolean;  -- TIM12 clock enable
      TIM13EN        : boolean;  -- TIM13 clock enable
      TIM14EN        : boolean;  -- TIM14 clock enable
      reserved_9_10  : bits_2;
      WWDGEN         : boolean;  -- Window watchdog clock enable
      reserved_12_13 : bits_2;
      SPI2EN         : boolean;  -- SPI2 clock enable
      SPI3EN         : boolean;  -- SPI3 clock enable
      reserved_16    : boolean;
      USART2EN       : boolean;  -- USART2 clock enable
      USART3EN       : boolean;  -- USART3 clock enable
      UART4EN        : boolean;  -- UART4 clock enable
      UART5EN        : boolean;  -- UART5 clock enable
      I2C1EN         : boolean;  -- I2C1 clock enable
      I2C2EN         : boolean;  -- I2C2 clock enable
      I2C3EN         : boolean;  -- I2C3 clock enable
      reserved_24    : bit;
      CAN1EN         : boolean;  -- CAN 1 clock enable
      CAN2EN         : boolean;  -- CAN 2 clock enable
      reserved_27    : bit;
      PWREN          : boolean;  -- Power interface clock enable
      DACEN          : boolean;  -- DAC interface clock enable
      reserved_30_31 : boolean;
   end record
      with size => 32, volatile_full_access;

   for t_RCC_APB1ENR use record
      TIM2EN         at 0 range 0 .. 0;
      TIM3EN         at 0 range 1 .. 1;
      TIM4EN         at 0 range 2 .. 2;
      TIM5EN         at 0 range 3 .. 3;
      TIM6EN         at 0 range 4 .. 4;
      TIM7EN         at 0 range 5 .. 5;
      TIM12EN        at 0 range 6 .. 6;
      TIM13EN        at 0 range 7 .. 7;
      TIM14EN        at 0 range 8 .. 8;
      reserved_9_10  at 0 range 9 .. 10;
      WWDGEN         at 0 range 11 .. 11;
      reserved_12_13 at 0 range 12 .. 13;
      SPI2EN         at 0 range 14 .. 14;
      SPI3EN         at 0 range 15 .. 15;
      reserved_16    at 0 range 16 .. 16;
      USART2EN       at 0 range 17 .. 17;
      USART3EN       at 0 range 18 .. 18;
      UART4EN        at 0 range 19 .. 19;
      UART5EN        at 0 range 20 .. 20;
      I2C1EN         at 0 range 21 .. 21;
      I2C2EN         at 0 range 22 .. 22;
      I2C3EN         at 0 range 23 .. 23;
      reserved_24    at 0 range 24 .. 24;
      CAN1EN         at 0 range 25 .. 25;
      CAN2EN         at 0 range 26 .. 26;
      reserved_27    at 0 range 27 .. 27;
      PWREN          at 0 range 28 .. 28;
      DACEN          at 0 range 29 .. 29;
      reserved_30_31 at 0 range 30 .. 31;
   end record;

   -------------------------------------------------------------
   -- RCC APB2 peripheral clock enable register (RCC_APB2ENR) --
   -------------------------------------------------------------

   type t_RCC_APB2ENR is record
      TIM1EN         : boolean;  -- TIM1 clock enable
      TIM8EN         : boolean;  -- TIM8 clock enable
      reserved_2_3   : bits_2;
      USART1EN       : boolean;  -- USART1 clock enable
      USART6EN       : boolean;  -- USART6 clock enable
      reserved_6_7   : bits_2;
      ADC1EN         : boolean;  -- ADC1 clock enable
      ADC2EN         : boolean;  -- ADC2 clock enable
      ADC3EN         : boolean;  -- ADC3 clock enable
      SDIOEN         : boolean;  -- SDIO clock enable
      SPI1EN         : boolean;  -- SPI1 clock enable
      reserved_13    : bit;
      SYSCFGEN       : boolean;
         -- System configuration controller clock enable
      reserved_15    : bit;
      TIM9EN         : boolean;  -- TIM9 clock enable
      TIM10EN        : boolean;  -- TIM10 clock enable
      TIM11EN        : boolean;  -- TIM11 clock enable
      reserved_19_23 : bits_5;
      reserved_24_31 : unsigned_8;
   end record
      with size => 32, volatile_full_access;

   for t_RCC_APB2ENR use record
      TIM1EN         at 0 range 0 .. 0;
      TIM8EN         at 0 range 1 .. 1;
      reserved_2_3   at 0 range 2 .. 3;
      USART1EN       at 0 range 4 .. 4;
      USART6EN       at 0 range 5 .. 5;
      reserved_6_7   at 0 range 6 .. 7;
      ADC1EN         at 0 range 8 .. 8;
      ADC2EN         at 0 range 9 .. 9;
      ADC3EN         at 0 range 10 .. 10;
      SDIOEN         at 0 range 11 .. 11;
      SPI1EN         at 0 range 12 .. 12;
      reserved_13    at 0 range 13 .. 13;
      SYSCFGEN       at 0 range 14 .. 14;
      reserved_15    at 0 range 15 .. 15;
      TIM9EN         at 0 range 16 .. 16;
      TIM10EN        at 0 range 17 .. 17;
      TIM11EN        at 0 range 18 .. 18;
      reserved_19_23 at 0 range 19 .. 23;
      reserved_24_31 at 0 range 24 .. 31;
   end record;

   --------------------
   -- RCC peripheral --
   --------------------

   type t_RCC_peripheral is record
      CR       : t_RCC_CR;
      PLLCFGR  : t_RCC_PLLCFGR;
      CFGR     : t_RCC_CFGR;
      CIR      : unsigned_32;
      AHB1ENR  : t_RCC_AHB1ENR;
      AHB2ENR  : t_RCC_AHB2ENR;
      APB1ENR  : t_RCC_APB1ENR;
      APB2ENR  : t_RCC_APB2ENR;
   end record
      with volatile;

   for t_RCC_peripheral use record
      CR       at 16#00# range 0 .. 31;
      PLLCFGR  at 16#04# range 0 .. 31;
      CFGR     at 16#08# range 0 .. 31;
      CIR      at 16#0C# range 0 .. 31;
      AHB1ENR  at 16#30# range 0 .. 31;
      AHB2ENR  at 16#34# range 0 .. 31;
      APB1ENR  at 16#40# range 0 .. 31;
      APB2ENR  at 16#44# range 0 .. 31;
   end record;

   RCC   : t_RCC_peripheral
      with
         import,
         volatile,
         address => system'to_address(16#4002_3800#);


   procedure reset;

   procedure init;

   procedure enable_clock (periph : in soc.devmap.t_periph_id);

end soc.rcc;
