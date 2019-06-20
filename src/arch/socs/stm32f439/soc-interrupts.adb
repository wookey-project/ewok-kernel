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

with m4.cpu;

package body soc.interrupts
   with spark_mode => on
is

   function get_interrupt
      return t_interrupt
   is
      ipsr : constant m4.cpu.t_IPSR_register := m4.cpu.get_ipsr_register;
   begin
      return t_interrupt'val (ipsr.ISR_NUMBER);
   end get_interrupt;

end soc.interrupts;
