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

pragma Annotate (GNATprove,
                 Intentional,
                 "initialization of init_done is not mentioned in Initializes contract",
                 "init_done is not a register, while it is a volatile");

package soc.dwt
   with
      spark_mode => on,
      abstract_state => ((Ctrl         with external), -- this is a register
                         (Cnt          with external),  -- this is a register
                         (Lar_register with external), -- this is a register
                         (Dem          with external), -- this is a register
                          Ini_F, Loo, Last),
      initializes => (Ctrl, Cnt, Dem, Ini_F) -- assumed as initialized
is

   pragma assertion_policy (pre => IGNORE, post => IGNORE, assert => IGNORE);

   -----------------------------------------------------
   -- SPARK ghost functions and procedures
   -----------------------------------------------------

   function init_is_done return boolean
      with ghost;


   function check_32bits_overflow return boolean
      with ghost;

   --------------------------------------------------
   -- The Data Watchpoint and Trace unit (DWT)     --
   -- (Cf. ARMv7-M Arch. Ref. Manual, C1.8, p.779) --
   --------------------------------------------------

   -- Reset the DWT-based timer
   procedure reset_timer
      with
         pre      => not init_is_done,
         global   => (input   => Ini_F,
                      in_out  => (Dem, Ctrl),
                      output  => (Lar_register, Cnt)),
          depends => (Dem           =>+ null,
                      Lar_register  =>  null,
                      Cnt           =>  null,
                      Ctrl          =>+ null,
                      null          =>  Ini_F);

   -- Start the DWT timer. The register is counting the number of CPU cycles
   procedure start_timer
      with
         pre      => not init_is_done,
         global   => (input   => Ini_F,
                      in_out  => Ctrl),
         depends  => (Ctrl    =>+ null,
                      null    => Ini_F);

   -- Stop the DWT timer
   procedure stop_timer
      with
        pre       => init_is_done,
        global    => (input  => Ini_F,
                      in_out => Ctrl),
        depends   => (Ctrl   =>+ null,
                      null   => Ini_F);

   -- Periodically check the DWT CYCCNT register for overflow. This permit
   -- to detect each time an overflow happends and increment the
   -- overflow counter to keep a valid 64 bit time value
   -- precondition check that the package has been initialized and that
   -- dwt_loop doesn't overflow
   procedure ovf_manage
      with
         pre => check_32bits_overflow;

   -- Initialize the DWT module
   procedure init
      with
         pre      => not init_is_done,
         global   => (in_out => (Ini_F, Ctrl, Dem),
                      output => (Last, Loo, Cnt, Lar_register));

   -- Get the DWT timer (without overflow support, keep a 32bit value)
   procedure get_cycles_32(cycles : out unsigned_32)
      with
         inline,
         pre      => init_is_done,
         global   => (input   => Ini_F,
                      in_out  => Cnt),
         depends  => (Cnt     =>+ null,
                      cycles  => Cnt,
                      null    => Ini_F);

   -- Get the DWT timer with overflow support. permits linear measurement
   -- on 64 bits cycles time window (approx. 1270857 days)
   procedure get_cycles (cycles : out unsigned_64)
      with
         pre      => init_is_done,
         global   => (input   => (Ini_F, Loo),
                      in_out  => Cnt),
         depends  => (Cnt     =>+ null,
                      cycles  => (Cnt, Loo),
                      null    => Ini_F);

   procedure get_microseconds (micros : out unsigned_64)
      with
         inline,
         pre      => init_is_done,
         global   => (input   => (Ini_F, Loo),
                      in_out  => Cnt),
         depends  => (micros  => (Cnt, Loo),
                      Cnt     =>+ null,
                      null    => Ini_F);

   procedure get_milliseconds (milli : out unsigned_64)
      with
         inline,
         pre      => init_is_done,
         global   => (in_out  => Cnt,
                      input   => (Loo, Ini_F)),
         depends  => (milli   => (Cnt, Loo),
                      Cnt     =>+ null,
                      null    => Ini_F);

private

   --
   -- Control register
   --

   type t_DWT_CTRL is record
      CYCCNTENA      : boolean;  -- Enables CYCCNT
      POSTPRESET     : bits_4;
      POSTINIT       : bits_4;
      CYCTAP         : bit;
      SYNCTAP        : bits_2;
      PCSAMPLENA     : bit;
      reserved_13_15 : bits_3;
      EXCTRCENA      : bit;
      CPIEVTENA      : bit;
      EXCEVTENA      : bit;
      SLEEPEVTENA    : bit;
      LSUEVTENA      : bit;
      FOLDEVTENA     : bit;
      CYCEVTENA      : bit;
      reserved_23    : bit;
      NOPRFCNT       : bit;
      NOCYCCNT       : bit;
      NOEXTTRIG      : bit;
      NOTRCPKT       : bit;
      NUMCOMP        : bits_4;
   end record
      with size => 32;

   for t_DWT_CTRL use record
      CYCCNTENA      at 0 range 0 .. 0;
      POSTPRESET     at 0 range 1 .. 4;
      POSTINIT       at 0 range 5 .. 8;
      CYCTAP         at 0 range 9 .. 9;
      SYNCTAP        at 0 range 10 .. 11;
      PCSAMPLENA     at 0 range 12 .. 12;
      reserved_13_15 at 0 range 13 .. 15;
      EXCTRCENA      at 0 range 16 .. 16;
      CPIEVTENA      at 0 range 17 .. 17;
      EXCEVTENA      at 0 range 18 .. 18;
      SLEEPEVTENA    at 0 range 19 .. 19;
      LSUEVTENA      at 0 range 20 .. 20;
      FOLDEVTENA     at 0 range 21 .. 21;
      CYCEVTENA      at 0 range 22 .. 22;
      reserved_23    at 0 range 23 .. 23;
      NOPRFCNT       at 0 range 24 .. 24;
      NOCYCCNT       at 0 range 25 .. 25;
      NOEXTTRIG      at 0 range 26 .. 26;
      NOTRCPKT       at 0 range 27 .. 27;
      NUMCOMP        at 0 range 28 .. 31;
   end record;

   DWT_CONTROL : t_DWT_CTRL
      with
         import,
         volatile,
         address => system'to_address (16#E000_1000#),
         part_of => Ctrl;

   --
   -- CYCCNT register
   --

   subtype t_DWT_CYCCNT is unsigned_32;

   DWT_CYCCNT  : t_DWT_CYCCNT
      with
         import,
         volatile,
         address => system'to_address (16#E000_1004#),
         part_of => Cnt;

   -- Specify the package state. Set to true by init().
   init_done : boolean := false with part_of => Ini_F;

   --
   -- DWT CYCCNT register overflow counting
   -- This permit to support incremental getcycle
   -- with a time window of 64bits length (instead of 32bits)
   --

   dwt_loops : unsigned_64 with part_of => Loo;

   --
   -- Last measured DWT CYCCNT. Compared with current measurement,
   -- we can detect if the register has generated an overflow or not
   --

   last_dwt    : unsigned_32 with part_of => Last;

   --------------------------------------------------
   -- CoreSight Software Lock registers            --
   -- Ref.:                                        --
   --    - ARMv7-M Arch. Ref. Manual, D1.1, p.826) --
   --    - CoreSight Arch. Spec. B2.5.9, p.48      --
   --------------------------------------------------

   --
   -- Lock Access Register (LAR)
   --

   LAR               : unsigned_32
      with
         import,
         volatile,
         address => system'to_address (16#E000_1FB0#),
         part_of => Lar_register;

   LAR_ENABLE_WRITE_KEY : constant := 16#C5AC_CE55#;

   ---------------------------------------------------------
   -- Debug Exception and Monitor Control Register, DEMCR --
   -- (Cf. ARMv7-M Arch. Ref. Manual, C1.6.5, p.765)      --
   ---------------------------------------------------------

   type t_DEMCR is record
      VC_CORERESET   : boolean;  -- Reset Vector Catch enabled

      reserved_1_3   : bits_3;

      VC_MMERR       : boolean;  -- Debug trap on a MemManage exception

      VC_NOCPERR     : boolean;
         -- Debug trap on a UsageFault exception caused by an access to a
         -- Coprocessor

      VC_CHKERR      : boolean;
         -- Debug trap on a UsageFault exception caused by a checking error

      VC_STATERR     : boolean;
         -- Debug trap on a UsageFault exception caused by a state information
         -- error

      VC_BUSERR      : boolean;  -- Debug trap on a BusFault exception

      VC_INTERR      : boolean;
         -- Debug trap on a fault occurring during exception entry or exception
         -- return

      VC_HARDERR     : boolean;  -- Debug trap on a HardFault exception

      reserved_11_15 : bits_5;
      MON_EN         : boolean;  -- DebugMonitor exception enabled
      MON_PEND       : boolean;  -- Sets or clears the pending state of the
                                 -- DebugMonitor exception
      MON_STEP       : boolean;  -- Step the processor
      MON_REQ        : boolean;  -- DebugMonitor semaphore bit
      reserved_20_23 : bits_4;
      TRCENA         : boolean;  -- DWT and ITM units enabled
   end record
      with size => 32;

   for t_DEMCR use record
      VC_CORERESET   at 0 range 0 .. 0;
      reserved_1_3   at 0 range 1 .. 3;
      VC_MMERR       at 0 range 4 .. 4;
      VC_NOCPERR     at 0 range 5 .. 5;
      VC_CHKERR      at 0 range 6 .. 6;
      VC_STATERR     at 0 range 7 .. 7;
      VC_BUSERR      at 0 range 8 .. 8;
      VC_INTERR      at 0 range 9 .. 9;
      VC_HARDERR     at 0 range 10 .. 10;
      reserved_11_15 at 0 range 11 .. 15;
      MON_EN         at 0 range 16 .. 16;
      MON_PEND       at 0 range 17 .. 17;
      MON_STEP       at 0 range 18 .. 18;
      MON_REQ        at 0 range 19 .. 19;
      reserved_20_23 at 0 range 20 .. 23;
      TRCENA         at 0 range 24 .. 24;
   end record;

   DEMCR       : t_DEMCR
      with import,
           volatile,
           address => system'to_address (16#E000_EDFC#),
           part_of => Dem;

end soc.dwt;
