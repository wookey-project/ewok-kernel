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

with system.machine_code;

package body m4.cpu.instructions
   with spark_mode => off
is


   procedure ISB
   is
   begin
      system.machine_code.asm ("isb", volatile => true);
   end ISB;


   procedure DSB
   is
   begin
      system.machine_code.asm ("dsb", volatile => true);
   end DSB;


   procedure DMB
   is
   begin
      system.machine_code.asm ("dmb", volatile => true);
   end DMB;


   procedure full_memory_barrier
   is
   begin
      system.machine_code.asm
        ("dsb"   & ascii.lf &
         "isb",
         volatile => true);
   end full_memory_barrier;


   procedure REV16 (value : in out unsigned_32)
   is
   begin
      system.machine_code.asm
        ("rev16 %0, %1",
         inputs   => unsigned_32'asm_input ("r", value),
         outputs  => unsigned_32'asm_output ("=r", value),
         volatile => true);
   end REV16;


   procedure REV (value : in out unsigned_32)
   is
   begin
      system.machine_code.asm
        ("rev %0, %1",
         inputs   => unsigned_32'asm_input ("r", value),
         outputs  => unsigned_32'asm_output ("=r", value),
         volatile => true);
   end REV;


   procedure BKPT
   is
   begin
      system.machine_code.asm ("bkpt", volatile => true);
   end BKPT;


   procedure WFI
   is
   begin
      system.machine_code.asm ("wfi", volatile => true);
   end WFI;

end m4.cpu.instructions;
