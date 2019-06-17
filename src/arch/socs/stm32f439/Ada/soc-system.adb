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

with soc.rcc;
with m4.cpu.instructions;
with m4.scb;

package body soc.system
   with spark_mode => off
is

   procedure init (vtor_addr : in  system_address)
   is
   begin
      soc.rcc.reset;
      soc.rcc.init;

      --
      -- Set VTOR
      --

      m4.cpu.instructions.DMB; -- Data Memory Barrier
      m4.scb.SCB.VTOR := vtor_addr;
      m4.cpu.instructions.DSB; -- Data Synchronization Barrier

   end init;

end soc.system;
