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

with system;

package m4.fpu
   with spark_mode => off
is

   -------------------------------------------------
   -- Coprocessor access control register (CPACR) --
   -------------------------------------------------

   type t_cp_access is
     (ACCESS_DENIED, ACCESS_PRIV, ACCESS_UNDEF, ACCESS_FULL)
      with size => 2;

   for t_cp_access use
     (ACCESS_DENIED  => 2#00#,
      ACCESS_PRIV    => 2#01#,
      ACCESS_UNDEF   => 2#10#,
      ACCESS_FULL    => 2#11#);

   type t_CPACR is record
      CP10  : t_cp_access;
      CP11  : t_cp_access;
   end record
     with volatile_full_access, size => 32;

   for t_CPACR use record
      CP10  at 0 range 20 .. 21;
      CP11  at 0 range 22 .. 23;
   end record;


   -----------------------------------------------------
   -- Floating-point context control register (FPCCR) --
   -----------------------------------------------------

   type t_FPU_FPCCR is record
      LSPACT   : boolean;
      USER     : boolean;
      THREAD   : boolean;
      HFRDY    : boolean;
      MMRDY    : boolean;
      BFRDY    : boolean;
      MONRDY   : boolean;
      LSPEN    : boolean;
      ASPEN    : boolean;
   end record
     with volatile_full_access, size => 32;

   for t_FPU_FPCCR use record
      LSPACT   at 0 range 0 .. 0;
      USER     at 0 range 1 .. 1;
      THREAD   at 0 range 3 .. 3;
      HFRDY    at 0 range 4 .. 4;
      MMRDY    at 0 range 5 .. 5;
      BFRDY    at 0 range 6 .. 6;
      MONRDY   at 0 range 8 .. 8;
      LSPEN    at 0 range 30 .. 30;
      ASPEN    at 0 range 31 .. 31;
   end record;

   -----------------------------------------------------
   -- Floating-point context address register (FPCAR) --
   -----------------------------------------------------

   type t_FPU_FPCAR is record
      ADDRESS  : unsigned_32;
   end record
     with volatile_full_access, size => 32;

   ----------------------------------------------------
   -- Floating-point status control register (FPSCR) --
   ----------------------------------------------------

   type t_FPU_FPSCR is record
      IOC            : bit;
      DZC            : bit;
      OFC            : bit;
      UFC            : bit;
      IXC            : bit;
      reserved_5_6   : bits_2;
      IDC            : bit;
      reserved_8_15  : unsigned_8;
      reserved_16_21 : bits_6;
      RMode          : bits_2;
      FZ             : bit;
      DN             : bit;
      AHP            : bit;
      reserved_27_27 : bit;
      V              : bit;
      C              : bit;
      Z              : bit;
      N              : bit;
   end record
     with volatile_full_access, size => 32;

   for t_FPU_FPSCR use record
      IOC            at 0 range 0 .. 0;
      DZC            at 0 range 1 .. 1;
      OFC            at 0 range 2 .. 2;
      UFC            at 0 range 3 .. 3;
      IXC            at 0 range 4 .. 4;
      reserved_5_6   at 0 range 5 .. 6;
      IDC            at 0 range 7 .. 7;
      reserved_8_15  at 0 range 8 .. 15;
      reserved_16_21 at 0 range 16 .. 21;
      RMode          at 0 range 22 .. 23;
      FZ             at 0 range 24 .. 24;
      DN             at 0 range 25 .. 25;
      AHP            at 0 range 26 .. 26;
      reserved_27_27 at 0 range 27 .. 27;
      V              at 0 range 28 .. 28;
      C              at 0 range 29 .. 29;
      Z              at 0 range 30 .. 30;
      N              at 0 range 31 .. 31;
   end record;

   -------------------------------------------------------------
   -- Floating-point default status control register (FPDSCR) --
   -------------------------------------------------------------

   type t_FPU_FPDSCR is record
      RMode    : bits_2;
      FZ       : bit;
      DN       : bit;
      AHP      : bit;
   end record
      with size => 32, volatile_full_access;

   for t_FPU_FPDSCR use record
      RMode    at 0 range 22 .. 23;
      FZ       at 0 range 24 .. 24;
      DN       at 0 range 25 .. 25;
      AHP      at 0 range 26 .. 26;
   end record;

   --------------------
   -- FPU peripheral --
   --------------------

   type t_FPU_peripheral is record
      FPCCR  : t_FPU_FPCCR;
      FPCAR  : t_FPU_FPCAR;
      FPDSCR : t_FPU_FPDSCR;
   end record
      with volatile;

   for t_FPU_peripheral use record
      FPCCR  at 16#04# range 0 .. 31;
      FPCAR  at 16#08# range 0 .. 31;
      FPDSCR at 16#0C# range 0 .. 31;
   end record;

   FPU   : t_FPU_peripheral
      with
         import,
         volatile,
         address => system'to_address(16#E000_EF30#);

   CPACR : t_CPACR
      with
         import,
         volatile,
         address => system'to_address(16#E000_ED88#);


end m4.fpu;
