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

with m4.cpu.instructions;

package body m4.scb
   with spark_mode => on
is

   procedure reset
   is
      aircr_value : t_SCB_AIRCR;
   begin
      aircr_value := SCB.AIRCR;
      aircr_value.VECTKEY     := 16#5FA#;
      aircr_value.SYSRESETREQ := 1;
      m4.cpu.instructions.DSB;
      SCB.AIRCR := aircr_value;
      m4.cpu.instructions.DSB;
      loop
         null; -- Wait until reset
      end loop;
   end reset;

end m4.scb;
