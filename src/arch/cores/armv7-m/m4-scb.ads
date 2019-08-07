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
with ada.unchecked_conversion;
with m4.layout;

package m4.scb
   with spark_mode => on
is

   ------------------------------------------
   -- Interrupt Control and State Register --
   ------------------------------------------

   -- Provides software control of the NMI, PendSV, and SysTick exceptions, and
   -- provides interrupt status information (ARMv7-M Arch. Ref. Manual, p.655).

   type t_SCB_ICSR is record
      VECTACTIVE  : bits_9;
      RETTOBASE   : bit;
      VECTPENDING : bits_10;
      ISRPENDING  : boolean;
      PENDSTCLR   : bit;
      PENDSTSET   : bit;
      PENDSVCLR   : bit;
      PENDSVSET   : bit;
      NMIPENDSET  : bit;
   end record
      with size => 32;

   for t_SCB_ICSR use record
      VECTACTIVE  at 0 range 0 .. 8;
      RETTOBASE   at 0 range 11 .. 11;
      VECTPENDING at 0 range 12 .. 21;
      ISRPENDING  at 0 range 22 .. 22;
      PENDSTCLR   at 0 range 25 .. 25;
      PENDSTSET   at 0 range 26 .. 26;
      PENDSVCLR   at 0 range 27 .. 27;
      PENDSVSET   at 0 range 28 .. 28;
      NMIPENDSET  at 0 range 31 .. 31;
   end record;

   ------------------------------------------------------
   -- Application interrupt and reset control register --
   ------------------------------------------------------

   type t_SCB_AIRCR is record
      VECTKEY        : unsigned_16;
      ENDIANESS      : bit;
      reserved_11_14 : bits_4;
      PRIGROUP       : bits_3;
      reserved_3_7   : bits_5;
      SYSRESETREQ    : bit;
      VECTCLRACTIVE  : bit;
      VECTRESET      : bit;
   end record
      with size => 32;

   for t_SCB_AIRCR use record
      VECTKEY        at 0 range 16 .. 31;
      ENDIANESS      at 0 range 15 .. 15;
      reserved_11_14 at 0 range 11 .. 14;
      PRIGROUP       at 0 range 8 .. 10;
      reserved_3_7   at 0 range 3 .. 7;
      SYSRESETREQ    at 0 range 2 .. 2;
      VECTCLRACTIVE  at 0 range 1 .. 1;
      VECTRESET      at 0 range 0 .. 0;
   end record;

   ----------------------------------------------
   -- Configuration and control register (CCR) --
   ----------------------------------------------

   -- The CCR controls entry to Thread mode
   type t_SCB_CCR is record
      NONBASETHRDENA : boolean;  -- If true, processor can enter Thread mode
                                 -- from any level under the control of an
                                 -- EXC_RETURN
      USERSETMPEND   : boolean;
      UNALIGN_TRP    : boolean;
      DIV_0_TRP      : boolean;
      BFHFNMIGN      : boolean;
      STKALIGN       : boolean;
   end record
      with size => 32;

   for t_SCB_CCR use record
      NONBASETHRDENA at 0 range 0 .. 0;
      USERSETMPEND   at 0 range 1 .. 1;
      UNALIGN_TRP    at 0 range 3 .. 3;
      DIV_0_TRP      at 0 range 4 .. 4;
      BFHFNMIGN      at 0 range 8 .. 8;
      STKALIGN       at 0 range 9 .. 9;
   end record;

   -----------------------------------------------
   -- System handler priority registers (SHPRx) --
   -----------------------------------------------

   type t_priority is record
      reserved : bits_4;
      priority : bits_4;
   end record
      with pack, size => 8;

   -- SHPR1

   type t_SCB_SHPR1 is record
      mem_fault   : t_priority;
      bus_fault   : t_priority;
      usage_fault : t_priority;
   end record
      with size => 32;

   for t_SCB_SHPR1 use record
      mem_fault   at 0 range 0 .. 7;
      bus_fault   at 0 range 8 .. 15;
      usage_fault at 0 range 16 .. 23;
   end record;

   -- SHPR2

   type t_SCB_SHPR2 is record
      svc_call : t_priority;
   end record
      with size => 32;

   for t_SCB_SHPR2 use record
      svc_call at 0 range 24 .. 31;
   end record;

   -- SHPR3

   type t_SCB_SHPR3 is record
      pendsv   : t_priority;
      systick  : t_priority;
   end record
      with size => 32;

   for t_SCB_SHPR3 use record
      pendsv   at 0 range 16 .. 23;
      systick  at 0 range 24 .. 31;
   end record;

   -----------------------------------------------
   -- System Handler Control and State Register --
   -----------------------------------------------

   type t_SCB_SHCSR is record
      MEMFAULTACT    : boolean;  -- MemManage exception active
      BUSFAULTACT    : boolean;  -- BusFault exception active
      reserved_3     : bit;
      USGFAULTACT    : boolean;  -- UsageFault exception active
      reserved_4_6   : bits_3;
      SVCALLACT      : boolean;  -- SVCall active
      MONITORACT     : boolean;  -- Debug monitor active
      reserved_9     : bit;
      PENDSVACT      : boolean;  -- PendSV exception active
      SYSTICKACT     : boolean;  -- SysTick exception active
      USGFAULTPENDED : boolean;  -- UsageFault pending
      MEMFAULTPENDED : boolean;  -- MemManage pending
      BUSFAULTPENDED : boolean;  -- BusFault pending
      SVCALLPENDED   : boolean;  -- SVCall pending
      MEMFAULTENA    : boolean;  -- MemManage enable
      BUSFAULTENA    : boolean;  -- BusFault enable
      USGFAULTENA    : boolean;  -- UsageFault enable
   end record
      with size => 32;

   for t_SCB_SHCSR use record
      MEMFAULTACT    at 0 range 0 .. 0;
      BUSFAULTACT    at 0 range 1 .. 1;
      reserved_3     at 0 range 2 .. 2;
      USGFAULTACT    at 0 range 3 .. 3;
      reserved_4_6   at 0 range 4 .. 6;
      SVCALLACT      at 0 range 7 .. 7;
      MONITORACT     at 0 range 8 .. 8;
      reserved_9     at 0 range 9 .. 9;
      PENDSVACT      at 0 range 10 .. 10;
      SYSTICKACT     at 0 range 11 .. 11;
      USGFAULTPENDED at 0 range 12 .. 12;
      MEMFAULTPENDED at 0 range 13 .. 13;
      BUSFAULTPENDED at 0 range 14 .. 14;
      SVCALLPENDED   at 0 range 15 .. 15;
      MEMFAULTENA    at 0 range 16 .. 16;
      BUSFAULTENA    at 0 range 17 .. 17;
      USGFAULTENA    at 0 range 18 .. 18;
   end record;

   ----------------------------------------
   -- Configurable Fault Status Register --
   ----------------------------------------

   --
   -- Memory Management Fault Status Register
   --

   type t_MMFSR is record
      IACCVIOL    : boolean;
      DACCVIOL    : boolean;
      reserved_2  : bit;
      MUNSTKERR   : boolean;
      MSTKERR     : boolean;
      MLSPERR     : boolean;
      reserved_6  : bit;
      MMARVALID   : boolean;
   end record
   with size => 8;
   pragma pack (t_MMFSR);

   --
   -- Bus Fault Status Register
   --

   type t_BFSR is record
      IBUSERR     : boolean;
      PRECISERR   : boolean;
      IMPRECISERR : boolean;
      UNSTKERR    : boolean;
      STKERR      : boolean;
      LSPERR      : boolean;
      reserved_6  : bit;
      BFARVALID   : boolean;
   end record
   with size => 8;
   pragma pack (t_BFSR);

   --
   -- Usage Fault Status Register
   --

   type t_UFSR is record
      UNDEFINSTR  : boolean;
      INVSTATE    : boolean;
      INVPC       : boolean;
      NOCP        : boolean;
      UNALIGNED   : boolean;
      DIVBYZERO   : boolean;
   end record
   with size => 16;

   for t_UFSR use record
      UNDEFINSTR  at 0 range 0 .. 0;
      INVSTATE    at 0 range 1 .. 1;
      INVPC       at 0 range 2 .. 2;
      NOCP        at 0 range 3 .. 3;
      UNALIGNED   at 0 range 8 .. 8;
      DIVBYZERO   at 0 range 9 .. 9;
   end record;

   type t_SCB_CFSR is record
      MMFSR : t_MMFSR;
      BFSR  : t_BFSR;
      UFSR  : t_UFSR;
   end record
   with size => 32;

   function to_unsigned_32 is new ada.unchecked_conversion
     (t_SCB_CFSR, unsigned_32);

   --------------------------------
   -- Hard fault status register --
   --------------------------------

   type t_SCB_HFSR is record
      VECTTBL  : boolean;  -- Vector table hard fault
      FORCED   : boolean;  -- Forced hard fault
      DEBUG_VT : bit;      -- Reserved for Debug use
   end record
   with size => 32;

   for t_SCB_HFSR use record
      VECTTBL  at 0 range  1 .. 1;
      FORCED   at 0 range 30 .. 30;
      DEBUG_VT at 0 range 31 .. 31;
   end record;

   --------------------------------------
   -- MemManage Fault Address Register --
   --------------------------------------

   type t_SCB_MMFAR is record
      ADDRESS  : system_address;
   end record
      with size => 32;

   --------------------------------
   -- Bus Fault Address Register --
   --------------------------------

   type t_SCB_BFAR is record
      ADDRESS  : system_address;
   end record
      with size => 32;

   --------------------
   -- SCB peripheral --
   --------------------

   -- /!\ ACTLR register is not in the same record

   type t_SCB_peripheral is record
      ICSR  : t_SCB_ICSR;
      VTOR  : system_address;
      AIRCR : t_SCB_AIRCR;
      CCR   : t_SCB_CCR;
      SHPR1 : t_SCB_SHPR1;
      SHPR2 : t_SCB_SHPR2;
      SHPR3 : t_SCB_SHPR3;
      SHCSR : t_SCB_SHCSR;
      CFSR  : t_SCB_CFSR;
      HFSR  : t_SCB_HFSR;
      MMFAR : t_SCB_MMFAR;
      BFAR  : t_SCB_BFAR;
   end record;

   for t_SCB_peripheral use record
      ICSR  at 16#04# range 0 .. 31;
      VTOR  at 16#08# range 0 .. 31;
      AIRCR at 16#0C# range 0 .. 31;
      CCR   at 16#14# range 0 .. 31;
      SHPR1 at 16#18# range 0 .. 31;
      SHPR2 at 16#1C# range 0 .. 31;
      SHPR3 at 16#20# range 0 .. 31;
      SHCSR at 16#24# range 0 .. 31;
      CFSR  at 16#28# range 0 .. 31;
      HFSR  at 16#2C# range 0 .. 31;
      MMFAR at 16#34# range 0 .. 31;
      BFAR  at 16#38# range 0 .. 31;
   end record;

   -----------------
   -- Peripherals --
   -----------------

   SCB   : t_SCB_peripheral
      with
         import,
         volatile,
         address => m4.layout.SCB_base2;

   procedure reset;

end m4.scb;
