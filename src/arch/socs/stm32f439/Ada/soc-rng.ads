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

package soc.rng
   with spark_mode => off
is

   -----------------------------------
   -- RNG control register (RNG_CR) --
   -----------------------------------

   type t_RNG_CR is record
      reserved_0_1   : bits_2;
      RNGEN          : boolean;
      IE             : boolean;
   end record
     with volatile_full_access, size => 32;

   for t_RNG_CR use record
      reserved_0_1   at 0 range 0 .. 1;
      RNGEN          at 0 range 2 .. 2; -- RNG is enabled
      IE             at 0 range 3 .. 3; -- RNG Interrupt is enabled
   end record;

   ----------------------------------
   -- RNG status register (RNG_SR) --
   ----------------------------------

   type t_RNG_SR is record
      DRDY           : boolean;  -- Data ready
      CECS           : boolean;  -- Clock error current status
      SECS           : boolean;  -- Seed error current status
      reserved_3_4   : bits_2;
      CEIS           : boolean;  -- Clock error interrupt status
      SEIS           : boolean;  -- Seed error interrupt status
   end record
     with volatile_full_access, size => 32;

   for t_RNG_SR use record
      DRDY           at 0 range 0 .. 0;
      CECS           at 0 range 1 .. 1;
      SECS           at 0 range 2 .. 2;
      reserved_3_4   at 0 range 3 .. 4;
      CEIS           at 0 range 5 .. 5;
      SEIS           at 0 range 6 .. 6;
   end record;

   --------------------------------
   -- RNG data register (RNG_DR) --
   --------------------------------

   type t_RNG_DR is record
      RNDATA   : unsigned_32; -- Random data
   end record
     with volatile_full_access, size => 32;

   --------------------
   -- RNG peripheral --
   --------------------

   type t_RNG_peripheral is record
      CR : t_RNG_CR;
      SR : t_RNG_SR;
      DR : t_RNG_DR;
   end record
      with volatile;

   for t_RNG_peripheral use record
      CR at 16#00# range 0 .. 31;
      SR at 16#04# range 0 .. 31;
      DR at 16#08# range 0 .. 31;
   end record;

   RNG   : t_RNG_peripheral
      with
         import,
         volatile,
         address => system'to_address(16#5006_0800#);

   procedure init
     (success : out boolean);

   procedure random
     (rand     : out unsigned_32;
      success  : out boolean);

end soc.rng;
