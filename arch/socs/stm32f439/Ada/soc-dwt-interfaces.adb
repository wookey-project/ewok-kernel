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

package body soc.dwt.interfaces
   with spark_mode => off
is

   -------------------
   -- get_cycles_32 --
   -------------------

   function get_cycles_32
      return Unsigned_32
   is
      val : unsigned_32;
   begin
      soc.dwt.get_cycles_32(val);
      return val;
   end get_cycles_32;

   ----------------
   -- get_cycles --
   ----------------

   function get_cycles
      return Unsigned_64
   is
      val : unsigned_64;
   begin
      soc.dwt.get_cycles(val);
      return val;
   end get_cycles;

end soc.dwt.interfaces;
