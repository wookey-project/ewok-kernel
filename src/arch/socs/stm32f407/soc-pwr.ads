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

package soc.pwr
   with spark_mode => off
is

   -------------------------------------------
   -- PWR power control register (PWR_CR)   --
   -- STM32F405xx/07xx and STM32F415xx/17xx --
   -------------------------------------------

   type t_vos is (VOS_SCALE2, VOS_SCALE1) with size => 1;
   for t_vos use
     (VOS_SCALE2 => 0,
      VOS_SCALE1 => 1);

   type t_PWR_CR is record
      LPDS           : bit;
      PDDS           : bit;
      CWUF           : bit;
      CSBF           : bit;
      PVDE           : bit;
      PLS            : bits_3;
      DBP            : bit;
      FPDS           : bit;
      reserved_10_13 : bits_4;
      VOS            : t_vos;
      reserved_15_31 : bits_17;
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
      reserved_10_13 at 0 range 10 .. 13;
      VOS            at 0 range 14 .. 14;
      reserved_15_31 at 0 range 15 .. 31;
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
