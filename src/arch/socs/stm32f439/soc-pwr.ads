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

package soc.pwr is

   -----------------------------------------
   -- PWR power control register (PWR_CR) --
   -- for STM32F42xxx and STM32F43xxx     --
   -----------------------------------------

   type t_vos is (VOS_SCALE3, VOS_SCALE2, VOS_SCALE1) with size => 2;
   for t_vos use
     (VOS_SCALE3 => 2#01#,
      VOS_SCALE2 => 2#10#,
      VOS_SCALE1 => 2#11#);

   type t_PWR_CR is record
      LPDS           : bit;
      PDDS           : bit;
      CWUF           : bit;
      CSBF           : bit;
      PVDE           : bit;
      PLS            : bits_3;
      DBP            : bit;
      FPDS           : bit;
      LPUDS          : bit;
      MRUDS          : bit;
      reserved_12_12 : bit;
      ADCDC1         : bit;
      VOS            : t_vos;
      ODEN           : bit;
      ODSWEN         : bit;
      UDEN           : bits_2;
      reserved_20_31 : bits_12;
   end record
     with volatile_full_access, size => 32;

   for t_PWR_CR use record
      LPDS           at 0 range 0 .. 0;
      PDDS           at 0 range 1 .. 1;
      CWUF           at 0 range 2 .. 2;
      CSBF           at 0 range 3 .. 3;
      PVDE           at 0 range 4 .. 4;
      PLS            at 0 range 5 .. 7;
      DBP            at 0 range 8 .. 8;
      FPDS           at 0 range 9 .. 9;
      LPUDS          at 0 range 10 .. 10;
      MRUDS          at 0 range 11 .. 11;
      reserved_12_12 at 0 range 12 .. 12;
      ADCDC1         at 0 range 13 .. 13;
      VOS            at 0 range 14 .. 15;
      ODEN           at 0 range 16 .. 16;
      ODSWEN         at 0 range 17 .. 17;
      UDEN           at 0 range 18 .. 19;
      reserved_20_31 at 0 range 20 .. 31;
   end record;

   --------------------
   -- PWR peripheral --
   --------------------

   type t_PWR_peripheral is record
      CR    : t_PWR_CR;
   end record
      with volatile;

   for t_PWR_peripheral use record
      CR    at 16#00# range 0 .. 31;
   end record;

   PWR   : t_PWR_peripheral
      with
         import,
         volatile,
         address => system'to_address(16#4000_7000#);

end soc.pwr;
