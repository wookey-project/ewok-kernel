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

package body m4.cpu
   with spark_mode => off
is

   procedure enable_irq
   is
   begin
      system.machine_code.asm
        ("cpsie i; isb",
         clobber  => "memory",
         volatile => true);
   end enable_irq;


   procedure disable_irq
   is
   begin
      system.machine_code.asm
        ("cpsid i",
         clobber  => "memory",
         volatile => true);
   end disable_irq;


   function get_control_register return t_control_register
   is
      cr : t_control_register;
   begin
      system.machine_code.asm
        ("mrs %0, control",
         outputs  => t_control_register'asm_output ("=r", cr),
         volatile => true);
      return cr;
   end get_control_register;


   procedure set_control_register (cr : t_control_register)
   is
   begin
      system.machine_code.asm
        ("msr control, %0",
         inputs   => t_control_register'asm_input ("r", cr),
         volatile => true);
   end set_control_register;


   function get_ipsr_register return t_ipsr_register
   is
      ipsr : t_ipsr_register;
   begin
      system.machine_code.asm
        ("mrs %0, ipsr",
         outputs  => t_ipsr_register'asm_output ("=r", ipsr),
         volatile => true);
      return ipsr;
   end get_ipsr_register;


   function get_apsr_register return t_apsr_register
   is
      apsr : t_apsr_register;
   begin
      system.machine_code.asm
        ("mrs %0, apsr",
         outputs  => t_apsr_register'asm_output ("=r", apsr),
         volatile => true);
      return apsr;
   end get_apsr_register;


   function get_epsr_register return t_epsr_register
   is
      epsr : t_epsr_register;
   begin
      system.machine_code.asm
        ("mrs %0, epsr",
         outputs  => t_epsr_register'asm_output ("=r", epsr),
         volatile => true);
      return epsr;
   end get_epsr_register;


   function get_lr_register return unsigned_32
   is
      val : unsigned_32;
   begin
      system.machine_code.asm
        ("mov %0, lr",
         outputs  => unsigned_32'asm_output ("=r", val),
         volatile => true);
      return val;
   end get_lr_register;


   function get_psp_register return system_address
   is
      addr : system_address;
   begin
      system.machine_code.asm
        ("mrs %0, psp",
         outputs  => system_address'asm_output ("=r", addr),
         volatile => true);
      return addr;
   end get_psp_register;


   procedure set_psp_register (addr : system_address)
   is
   begin
      system.machine_code.asm
        ("msr psp, %0",
         inputs   => system_address'asm_input ("r", addr),
         volatile => true);
   end set_psp_register;


   function get_msp_register return system_address
   is
      addr : system_address;
   begin
      system.machine_code.asm
        ("mrs %0, msp",
         outputs  => system_address'asm_output ("=r", addr),
         volatile => true);
      return addr;
   end get_msp_register;


   procedure set_msp_register (addr : system_address)
   is
   begin
      system.machine_code.asm
        ("msr msp, %0",
         inputs   => system_address'asm_input ("r", addr),
         volatile => true);
   end set_msp_register;


   function get_primask_register return unsigned_32
   is
      mask : unsigned_32;
   begin
      system.machine_code.asm
        ("mrs %0, primask",
         outputs  => unsigned_32'asm_output ("=r", mask),
         volatile => true);
      return mask;
   end get_primask_register;


   procedure set_primask_register (mask : unsigned_32)
   is
   begin
      system.machine_code.asm
        ("msr primask, %0",
         inputs   => unsigned_32'asm_input ("r", mask),
         volatile => true);
   end set_primask_register;


end m4.cpu;
