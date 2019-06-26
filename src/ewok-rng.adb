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

with ewok.debug;
with soc.rng;

package body ewok.rng
   with spark_mode => off
is


   procedure random_array
     (tab      : out unsigned_8_array;
      success  : out boolean)
   is
      rand        : unsigned_32;
      rand_bytes  : unsigned_8_array (1 .. 4)
         with
            address  => rand'address,
            size     => 4 * byte'size;
      index       : unsigned_32;
      ok          : boolean;
   begin

      index := tab'first;
      while index < tab'last loop

         soc.rng.random (rand, ok);
         if not ok then
            pragma DEBUG (debug.log (debug.ERROR, "RNG failed!"));
            success := false;
            return;
         end if;

         if index + 3 <= tab'last then
            tab(index .. index + 3) := rand_bytes;
         else
            tab(index .. tab'last)  := rand_bytes(1 .. tab'last - index + 1);
         end if;

         index := index + 4;

      end loop;

      success := true;

   end random_array;


   procedure random
     (rand     : out unsigned_32;
      success  : out boolean)
   is
   begin
      soc.rng.random (rand, success);
      if not success then
         pragma DEBUG (debug.log (debug.ERROR, "RNG failed!"));
      end if;
   end random;

end ewok.rng;
