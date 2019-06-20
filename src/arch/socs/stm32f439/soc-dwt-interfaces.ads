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

package soc.dwt.interfaces
   with spark_mode => on
is

   -- get the DWT timer (without overflow support, keep a 32bit value)
   function get_cycles_32
     return Unsigned_32
   with
      convention      => c,
      export          => true,
       external_name  => "soc_dwt_getcycles";

   -- get the DWT timer with overflow support. permits linear measurement
   -- on 64 bits cycles time window (approx. 1270857 days)
   function get_cycles
     return Unsigned_64
   with
      convention     => c,
      export         => true,
      external_name  => "soc_dwt_getcycles_64";

end soc.dwt.interfaces;
