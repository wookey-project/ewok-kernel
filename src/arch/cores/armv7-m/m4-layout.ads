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

with system; use system;

package m4.layout
   with spark_mode => on
is

   --------------------
   -- Base addresses --
   --------------------

   SCB_BASE       : constant address := system'to_address (16#E000_E008#);
   SYS_TIMER_BASE : constant address := system'to_address (16#E000_E010#);
   NVIC_BASE      : constant address := system'to_address (16#E000_E100#);
   SCB_BASE2      : constant address := system'to_address (16#E000_ED00#);
   MPU_BASE       : constant address := system'to_address (16#E000_ED90#);
   NVIC_BASE2     : constant address := system'to_address (16#E000_EF00#);
   FPU_BASE       : constant address := system'to_address (16#E000_EF30#);

end m4.layout;
