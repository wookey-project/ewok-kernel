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

with m4.layout;

package m4.systick
   with spark_mode => on
is

   -- FIXME - Should be defined in arch/boards
   MAIN_CLOCK_FREQUENCY    : constant := 168_000_000;
   TICKS_PER_SECOND        : constant := 1000;

   subtype t_tick is unsigned_64;

   ----------------------------------------------------
   -- SysTick control and status register (STK_CTRL) --
   ----------------------------------------------------

   type t_clock_type is
     (EXT_CLOCK, PROCESSOR_CLOCK)
      with size => 1;

   for t_clock_type use
     (EXT_CLOCK => 0, PROCESSOR_CLOCK => 1);

   type t_STK_CTRL is record
      ENABLE      : boolean;  -- Enables the counter
      TICKINT     : boolean;  -- Enables exception request
      CLKSOURCE   : t_clock_type;
      COUNTFLAG   : bit;
   end record
      with size => 32, volatile_full_access;

   for t_STK_CTRL use record
      ENABLE      at 0 range 0 .. 0;
      TICKINT     at 0 range 1 .. 1;
      CLKSOURCE   at 0 range 2 .. 2;
      COUNTFLAG   at 0 range 16 .. 16;
   end record;

   ----------------------------------------------
   -- SysTick reload value register (STK_LOAD) --
   ----------------------------------------------

   -- Note: To generate a timer with a period of N processor clock
   -- cycles, use a RELOAD value of N-1.

   type t_STK_LOAD is record
      RELOAD   : bits_24;
   end record
      with size => 32, volatile_full_access;

   ----------------------------------------------
   -- SysTick current value register (STK_VAL) --
   ----------------------------------------------

   type t_STK_VAL is record
      CURRENT  : bits_24;
   end record
      with size => 32, volatile_full_access;

   ----------------------------------------------------
   -- SysTick calibration value register (STK_CALIB) --
   ----------------------------------------------------

   type t_STK_CALIB is record
      TENMS : bits_24;
      SKEW  : bit;
      NOREF : bit;
   end record
      with size => 32, volatile_full_access;

   for t_STK_CALIB use record
      TENMS at 0 range 0 .. 23;
      SKEW  at 0 range 30 .. 30;
      NOREF at 0 range 31 .. 31;
   end record;

   ----------------
   -- Peripheral --
   ----------------

   type t_SYSTICK_peripheral is record
      CTRL     : t_STK_CTRL;
      LOAD     : t_STK_LOAD;
      VAL      : t_STK_VAL;
      CALIB    : t_STK_CALIB;
   end record
      with volatile;

   for t_SYSTICK_peripheral use record
      CTRL     at 16#00# range 0 .. 31;
      LOAD     at 16#04# range 0 .. 31;
      VAL      at 16#08# range 0 .. 31;
      CALIB    at 16#0C# range 0 .. 31;
   end record;

   SYSTICK : t_SYSTICK_peripheral
      with
         import,
         volatile,
         address => m4.layout.SYS_TIMER_base;

   ---------------
   -- Functions --
   ---------------

   -- Initialize the systick module
   procedure init;

   -- Get the number of milliseconds elapsed since booting
   function get_ticks return unsigned_64
      with
         volatile_function;

   function get_milliseconds return milliseconds
      with
         volatile_function;


   function get_microseconds return microseconds
      with
         volatile_function;

   function to_ticks (ms : milliseconds) return t_tick
      with inline;

   function to_milliseconds (t : t_tick) return milliseconds
      with inline;

   function to_microseconds (t : t_tick) return microseconds
      with inline;

   -- Note: default Systick IRQ handler is defined in package
   --       ewok.interrupts.handler and call 'increment' procedure
   procedure increment;

private

   ticks : t_tick
      with volatile, async_writers;

end m4.systick;
