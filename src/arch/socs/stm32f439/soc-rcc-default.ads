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


package soc.rcc.default
   with spark_mode => off
is

   --
   -- Those constant suit to disco407, disco429, disco430 and wookey
   --

   enable_HSE : constant boolean := false;
   enable_PLL : constant boolean := true;

   PLL_M : constant := 16;
   PLL_N : constant := 336;

   PLL_P : constant t_PLLP := PLLP2;

   PLL_Q : constant := 7;

   AHB_DIV  : constant t_HPRE := HPRE_NODIV;
   APB1_DIV : constant t_PPRE := PPRE_DIV4;
   APB2_DIV : constant t_PPRE := PPRE_DIV2;

   CLOCK_APB1     : constant := 42_000_000; -- Hz
   CLOCK_APB2     : constant := 84_000_000; -- Hz
   CORE_FREQUENCY : constant := 168_000_000; -- Hz

end soc.rcc.default;
