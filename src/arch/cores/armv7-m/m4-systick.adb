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


package body m4.systick
   with spark_mode => on
is

   procedure init
   is
   begin
      SYSTICK.LOAD.RELOAD  := bits_24
        (MAIN_CLOCK_FREQUENCY / TICKS_PER_SECOND);
      SYSTICK.VAL.CURRENT  := 0;
      SYSTICK.CTRL         := (ENABLE     => true,
                               TICKINT    => true,
                               CLKSOURCE  => PROCESSOR_CLOCK,
                               COUNTFLAG  => 0);
   end init;


   procedure increment
   is
      current  : constant t_tick := ticks;
   begin
      ticks := current + 1;
   end increment;


   function get_ticks return unsigned_64
   is
      current  : constant t_tick := ticks;
   begin
      return unsigned_64 (current);
   end get_ticks;


   function to_milliseconds (t : t_tick)
      return milliseconds
   is
   begin
      return t * (1000 / TICKS_PER_SECOND);
   end to_milliseconds;


   function to_microseconds (t : t_tick)
      return microseconds
   is
   begin
      return t * (1000000 / TICKS_PER_SECOND);
   end to_microseconds;


   function to_ticks (ms : milliseconds) return t_tick
   is
   begin
      return ms * TICKS_PER_SECOND / 1000;
   end to_ticks;


   function get_milliseconds return milliseconds
   is
      current  : constant t_tick := ticks;
   begin
      return to_milliseconds (current);
   end get_milliseconds;


   function get_microseconds return microseconds
   is
      current  : constant t_tick := ticks;
   begin
      return to_microseconds (current);
   end get_microseconds;

end m4.systick;
