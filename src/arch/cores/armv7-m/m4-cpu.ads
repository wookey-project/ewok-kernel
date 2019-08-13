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

pragma Restrictions (No_Elaboration_Code);
with ada.unchecked_conversion;

package m4.cpu
   with spark_mode => on
is

   -------------
   -- Globals --
   -------------

   EXC_THREAD_MODE   : constant unsigned_32 := 16#FFFF_FFFD#;
   EXC_KERN_MODE     : constant unsigned_32 := 16#FFFF_FFF9#;
   EXC_HANDLER_MODE  : constant unsigned_32 := 16#FFFF_FFF1#;

   ---------------
   -- Registers --
   ---------------

   --
   -- CONTROL register
   --

   type t_SPSEL is (MSP, PSP) with size => 1;
   for t_SPSEL use (MSP => 0, PSP => 1);

   type t_PRIV is (PRIVILEGED, UNPRIVILEGED) with size => 1;
   for t_PRIV use (PRIVILEGED => 0, UNPRIVILEGED => 1);

   type t_control_register is record
      nPRIV : t_PRIV;  -- Thread mode is privileged (0), unprivileged (1)
      SPSEL : t_SPSEL; -- Current stack pointer
   end record
      with size => 32;

   for t_control_register use record
      nPRIV at 0 range 0 .. 0;
      SPSEL at 0 range 1 .. 1;
   end record;

   --
   -- PSR register that aggregates (A)(I)(E)PSR registers
   --

   type t_PSR_register is record
      ISR_NUMBER     : unsigned_8;
      ICI_IT_lo      : bits_6;
      GE             : bits_4;
      Thumb          : bit;
      ICI_IT_hi      : bits_2;
      DSP_overflow   : bit; -- Q
      Overflow       : bit; -- V
      Carry          : bit;
      Zero           : bit;
      Negative       : bit;
   end record
      with size => 32;

   for t_PSR_register use record
      ISR_NUMBER     at 0 range 0 .. 7;
      ICI_IT_lo      at 0 range 10 .. 15;
      GE             at 0 range 16 .. 19;
      Thumb          at 0 range 24 .. 24;
      ICI_IT_hi      at 0 range 25 .. 26;
      DSP_overflow   at 0 range 27 .. 27;
      Overflow       at 0 range 28 .. 28;
      Carry          at 0 range 29 .. 29;
      Zero           at 0 range 30 .. 30;
      Negative       at 0 range 31 .. 31;
   end record;

   function to_unsigned_32 is new ada.unchecked_conversion
     (t_PSR_register, unsigned_32);

   --
   -- APSR register
   --

   type t_APSR_register is record
      GE             : bits_4;
      DSP_overflow   : bit;
      Overflow       : bit;
      Carry          : bit;
      Zero           : bit;
      Negative       : bit;
   end record
      with size => 32;

   for t_APSR_register use record
      GE             at 0 range 16 .. 19;
      DSP_overflow   at 0 range 27 .. 27;
      Overflow       at 0 range 28 .. 28;
      Carry          at 0 range 29 .. 29;
      Zero           at 0 range 30 .. 30;
      Negative       at 0 range 31 .. 31;
   end record;

   function to_PSR_register is new ada.unchecked_conversion
     (t_APSR_register, t_PSR_register);

   --
   -- IPSR register
   --

   type t_IPSR_register is record
      ISR_NUMBER  : unsigned_8 range 0 .. 90;
   end record
      with size => 32;

   function to_PSR_register is new ada.unchecked_conversion
     (t_IPSR_register, t_PSR_register);

   --
   -- EPSR register
   --

   type t_EPSR_register is record
      ICI_IT_lo   : bits_6;
      Thumb       : bit;
      ICI_IT_hi   : bits_2;
   end record
      with size => 32;

   for t_EPSR_register use record
      ICI_IT_lo   at 0 range 10 .. 15;
      Thumb       at 0 range 24 .. 24;
      ICI_IT_hi   at 0 range 25 .. 26;
   end record;

   function to_PSR_register is new ada.unchecked_conversion
     (t_EPSR_register, t_PSR_register);

   ---------------
   -- Functions --
   ---------------

   -- Enable IRQs by clearing the I-bit in the CPSR.
   -- (privileged mode)
   procedure enable_irq
      with inline_always;

   -- Disable IRQs by setting the I-bit in the CPSR.
   -- (privileged mode)
   procedure disable_irq
      with inline_always;

   -- Get the Control register.
   function get_control_register return t_control_register
      with inline_always;

   -- Set the Control register.
   procedure set_control_register (cr : in t_control_register)
      with inline_always;

   -- Get the IPSR register.
   function get_ipsr_register return t_IPSR_register
      with inline_always;

   -- Get the APSR register.
   function get_apsr_register return t_APSR_register
      with inline_always;

   -- Get the EPSR register.
   function get_epsr_register return t_EPSR_register
      with inline_always;

   -- Get the LR register
   function get_lr_register return unsigned_32
      with inline_always;

   -- Get the process stack pointer (PSP)
   function get_psp_register return system_address
      with inline_always;

   -- Set the process stack pointer (PSP)
   procedure set_psp_register (addr : in system_address)
      with inline_always;

   -- Get the main stack pointer (MSP)
   function get_msp_register return system_address
      with inline_always;

   -- Set the main stack pointer (MSP)
   procedure set_msp_register (addr : system_address)
      with inline_always;

   -- Get the priority mask value
   function get_primask_register return unsigned_32
      with inline_always;

   -- Set the priority mask value
   procedure set_primask_register (mask : in unsigned_32)
      with inline_always;

end m4.cpu;
