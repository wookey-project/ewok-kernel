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

with m4.systick;

package body soc.dwt
   with spark_mode => on
is
   -----------------------------------------------------
   -- SPARK ghost functions and procedures
   -----------------------------------------------------

   function init_is_done
      return boolean
   is
   begin
      return init_done;
   end init_is_done;


   function check_32bits_overflow
      return boolean
   is
   begin
      return (init_done and then dwt_loops < unsigned_64(unsigned_32'Last));
   end;

   --------------------------------------------------
   -- The Data Watchpoint and Trace unit (DWT)     --
   -- (Cf. ARMv7-M Arch. Ref. Manual, C1.8, p.779) --
   --------------------------------------------------

   procedure reset_timer
   is
   begin
      DEMCR.TRCENA   := true;
      LAR            := LAR_ENABLE_WRITE_KEY;
      DWT_CYCCNT     := 0; -- reset the counter
      DWT_CONTROL.CYCCNTENA   := false;
   end reset_timer;


   procedure start_timer
   is
   begin
      DWT_CONTROL.CYCCNTENA   := true; -- enable the counter
   end start_timer;


   procedure stop_timer
   is
   begin
      DWT_CONTROL.CYCCNTENA   := false; -- stop the counter
   end stop_timer;


   procedure ovf_manage
   --with
   --   Refined_Post   => (dwt_loops = dwt_loops'Old
   --                      or dwt_loops = (dwt_loops'Old + 1))
   is
      dwt : unsigned_32;
   begin
      dwt := DWT_CYCCNT;
      if dwt < last_dwt then
         dwt_loops := dwt_loops + 1;
      end if;
      last_dwt := dwt;
   end ovf_manage;


   procedure init
   is
   begin
      last_dwt    := 0;
      dwt_loops   := 0;
      reset_timer;
      start_timer;
      init_done   := true;
   end init;


   procedure get_cycles_32 (cycles : out unsigned_32)
   is
   begin
      cycles := DWT_CYCCNT; -- can't return volatile (SPARK RM 7.1.3(12))
   end get_cycles_32;


   procedure get_cycles (cycles : out unsigned_64)
   is
      cyccnt : unsigned_64;
   begin
      cyccnt := unsigned_64 (DWT_CYCCNT);
      cycles := dwt_loops * 16#1_0000_0000# + cyccnt;
   end get_cycles;


   procedure get_microseconds (micros : out unsigned_64)
   is
      cycles : unsigned_64;
   begin
      get_cycles(cycles);
      micros := cycles / (m4.systick.MAIN_CLOCK_FREQUENCY / 1000_000);
   end get_microseconds;


   procedure get_milliseconds (milli : out unsigned_64)
   is
      cycles : unsigned_64;
   begin
      get_cycles(cycles);
      milli := cycles / (m4.systick.MAIN_CLOCK_FREQUENCY / 1000);
   end get_milliseconds;


end soc.dwt;
