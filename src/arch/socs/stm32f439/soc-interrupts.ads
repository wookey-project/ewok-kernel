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

package soc.interrupts
   with spark_mode => on
is

   -------------------------------------
   -- STM32F4xx interrupts and events --
   -------------------------------------

   type t_interrupt is
     (INT_NONE,        -- 0
      INT_RESET,
      INT_NMI,
      INT_HARDFAULT,
      INT_MEMMANAGE,
      INT_BUSFAULT,    -- 5
      INT_USAGEFAULT,
      INT_VOID1,
      INT_VOID2,
      INT_VOID3,
      INT_VOID4,       -- 10
      INT_SVC,
      INT_DEBUGON,
      INT_VOID5,
      INT_PENDSV,
      INT_SYSTICK,     -- 15
      INT_WWDG,
      INT_PVD,
      INT_TAMP_STAMP,
      INT_RTC_WKUP,
      INT_FLASH,       -- 20
      INT_RCC,
      INT_EXTI0,
      INT_EXTI1,
      INT_EXTI2,
      INT_EXTI3,       -- 25
      INT_EXTI4,
      INT_DMA1_STREAM0,
      INT_DMA1_STREAM1,
      INT_DMA1_STREAM2,
      INT_DMA1_STREAM3,   -- 30
      INT_DMA1_STREAM4,
      INT_DMA1_STREAM5,
      INT_DMA1_STREAM6,
      INT_ADC,
      INT_CAN1_TX,        -- 35
      INT_CAN1_RX0,
      INT_CAN1_RX1,
      INT_CAN1_SCE,
      INT_EXTI9_5,
      INT_TIM1_BRK_TIM9,  -- 40
      INT_TIM1_UP_TIM10,
      INT_TIM1_TRG_COM_TIM11,
      INT_TIM1_CC,
      INT_TIM2,
      INT_TIM3,           -- 45
      INT_TIM4,
      INT_I2C1_EV,
      INT_I2C1_ER,
      INT_I2C2_EV,
      INT_I2C2_ER,        -- 50
      INT_SPI1,
      INT_SPI2,
      INT_USART1,
      INT_USART2,
      INT_USART3,         -- 55
      INT_EXTI15_10,
      INT_RTC_ALARM,
      INT_OTG_FS_WKUP,
      INT_TIM8_BRK_TIM12,
      INT_TIM8_UP_TIM13,  -- 60
      INT_TIM8_TRG_COM_TIM14,
      INT_TIM8_CC,
      INT_DMA1_STREAM7,
      INT_FSMC,
      INT_SDIO,           -- 65
      INT_TIM5,
      INT_SPI3,
      INT_UART4,
      INT_UART5,
      INT_TIM6_DAC,       -- 70
      INT_TIM7,
      INT_DMA2_STREAM0,
      INT_DMA2_STREAM1,
      INT_DMA2_STREAM2,
      INT_DMA2_STREAM3,   -- 75
      INT_DMA2_STREAM4,
      INT_ETH,
      INT_ETH_WKUP,
      INT_CAN2_TX,
      INT_CAN2_RX0,       -- 80
      INT_CAN2_RX1,
      INT_CAN2_SCE,
      INT_OTG_FS,
      INT_DMA2_STREAM5,
      INT_DMA2_STREAM6,   -- 85
      INT_DMA2_STREAM7,
      INT_USART6,
      INT_I2C3_EV,
      INT_I2C3_ER,
      INT_OTG_HS_EP1_OUT, -- 90
      INT_OTG_HS_EP1_IN,
      INT_OTG_HS_WKUP,
      INT_OTG_HS,
      INT_DCMI,
      INT_CRYP,           -- 95
      INT_HASH_RNG,
      INT_FPU,
      INT_UART7,
      INT_UART8,
      INT_SPI4,           -- 100
      INT_SPI5,
      INT_SPI6,
      INT_SAI1,
      INT_LCD_TFT1,
      INT_LCD_TFT2,       -- 105
      INT_DMA2D)
      with size => 8;

   function get_interrupt return t_interrupt
      with
         inline;

end soc.interrupts;
