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

package soc.flash is

   -----------------------------------------------
   -- Flash access control register (FLASH_ACR) --
   -- for STM32F42xxx and STM32F43xxx           --
   -----------------------------------------------

   type t_FLASH_ACR is record
      LATENCY        : bits_4;
      -- reserved_04_07
      PRFTEN         : boolean;
      ICEN           : boolean;
      DCEN           : boolean;
      ICRST          : boolean;
      DCRST          : boolean;
      -- reserved_13_31
   end record
     with volatile_full_access, size => 32;

   for t_FLASH_ACR use record
      LATENCY        at 0 range 0 .. 3;
      -- reserved_04_07
      PRFTEN         at 0 range 8 .. 8;
      ICEN           at 0 range 9 .. 9;
      DCEN           at 0 range 10 .. 10;
      ICRST          at 0 range 11 .. 11;
      DCRST          at 0 range 12 .. 12;
      -- reserved_13_31
   end record;

   ----------------------
   -- FLASH peripheral --
   ----------------------

   type t_FLASH_peripheral is record
      ACR   : t_FLASH_ACR;
   end record
      with volatile;

   for t_FLASH_peripheral use record
      ACR   at 16#00# range 0 .. 31;
   end record;

   FLASH : t_FLASH_peripheral
      with
         import,
         volatile,
         address => system'to_address(16#4002_3C00#);

end soc.flash;
