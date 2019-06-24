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
      INT_98, INT_99,
      INT_100, INT_101, INT_102, INT_103, INT_104, INT_105, INT_106, INT_107, INT_108, INT_109,
      INT_110, INT_111, INT_112, INT_113, INT_114, INT_115, INT_116, INT_117, INT_118, INT_119,
      INT_120, INT_121, INT_122, INT_123, INT_124, INT_125, INT_126, INT_127, INT_128, INT_129,
      INT_130, INT_131, INT_132, INT_133, INT_134, INT_135, INT_136, INT_137, INT_138, INT_139,
      INT_140, INT_141, INT_142, INT_143, INT_144, INT_145, INT_146, INT_147, INT_148, INT_149,
      INT_150, INT_151, INT_152, INT_153, INT_154, INT_155, INT_156, INT_157, INT_158, INT_159,
      INT_160, INT_161, INT_162, INT_163, INT_164, INT_165, INT_166, INT_167, INT_168, INT_169,
      INT_170, INT_171, INT_172, INT_173, INT_174, INT_175, INT_176, INT_177, INT_178, INT_179,
      INT_180, INT_181, INT_182, INT_183, INT_184, INT_185, INT_186, INT_187, INT_188, INT_189,
      INT_190, INT_191, INT_192, INT_193, INT_194, INT_195, INT_196, INT_197, INT_198, INT_199,
      INT_200, INT_201, INT_202, INT_203, INT_204, INT_205, INT_206, INT_207, INT_208, INT_209,
      INT_210, INT_211, INT_212, INT_213, INT_214, INT_215, INT_216, INT_217, INT_218, INT_219,
      INT_220, INT_221, INT_222, INT_223, INT_224, INT_225, INT_226, INT_227, INT_228, INT_229,
      INT_230, INT_231, INT_232, INT_233, INT_234, INT_235, INT_236, INT_237, INT_238, INT_239,
      INT_240, INT_241, INT_242, INT_243, INT_244, INT_245, INT_246, INT_247, INT_248, INT_249,
      INT_250, INT_251, INT_252, INT_253, INT_254, INT_255)
      with size => 8;

   function get_interrupt return t_interrupt
      with
         inline;

end soc.interrupts;
