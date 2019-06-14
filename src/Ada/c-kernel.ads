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

with types.c;

package c.kernel is

   function get_random
     (s    : out types.c.c_string;
      len  : in  unsigned_16)
      return types.c.t_retval
   with
      convention     => c,
      import         => true,
      external_name  => "get_random",
      global         => null;

   function get_random_u32
      return unsigned_32
   with
      convention     => c,
      import         => true,
      external_name  => "get_random_u32",
      global         => null;

end c.kernel;
