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


package soc.exti
   with spark_mode => on
is

   subtype t_exti_line_index is natural range 0 .. 22;

   type t_exti_trigger is
     (EXTI_TRIGGER_NONE,
      EXTI_TRIGGER_RISE,
      EXTI_TRIGGER_FALL,
      EXTI_TRIGGER_BOTH);


   -- Initialize EXTI by enabling SYSCFG.APB2 clock
   procedure init;

   procedure deinit;

   function is_line_pending
     (line : t_exti_line_index)
      return boolean;

   procedure clear_pending
     (line : in t_exti_line_index);

   procedure enable
     (line : in t_exti_line_index);

   procedure disable
     (line : in t_exti_line_index);

   function is_enabled
     (line : in t_exti_line_index)
      return boolean;


   type t_mask is  (MASKED, NOT_MASKED) with size => 1;
   for  t_mask use (MASKED => 0, NOT_MASKED => 1);

   type t_masks is array (t_exti_line_index) of t_mask
      with volatile_components, pack, size => 23;

   ----------------------------------------
   -- Interrupt mask register (EXTI_IMR) --
   ----------------------------------------

   type t_EXTI_IMR is record
      line  : t_masks;
   end record
     with volatile_full_access, size => 32;

   for t_EXTI_IMR use record
      line  at 0 range  0 .. 22;
   end record;

   ------------------------------------
   -- Event mask register (EXTI_EMR) --
   ------------------------------------

   type t_EXTI_EMR is record
      line  : t_masks;
   end record
     with volatile_full_access, size => 32;

   for t_EXTI_EMR use record
      line  at 0 range  0 .. 22;
   end record;

   ---------------------------------------------------
   -- Rising trigger selection register (EXTI_RTSR) --
   ---------------------------------------------------

   type t_trigger is (TRIGGER_DISABLED, TRIGGER_ENABLED) with size => 1;
   for t_trigger use (TRIGGER_DISABLED => 0, TRIGGER_ENABLED  => 1);

   type t_triggers is array (t_exti_line_index) of t_trigger
      with pack, size => 23;

   type t_EXTI_RTSR is record
      line  : t_triggers;
   end record
     with volatile_full_access, size => 32;

   for t_EXTI_RTSR use record
      line  at 0 range  0 .. 22;
   end record;

   ----------------------------------------------------
   -- Falling trigger selection register (EXTI_FTSR) --
   ----------------------------------------------------

   type t_EXTI_FTSR is record
      line  : t_triggers;
   end record
     with volatile_full_access, size => 32;

   for t_EXTI_FTSR use record
      line  at 0 range  0 .. 22;
   end record;

   ----------------------------------------------------
   -- Software interrupt event register (EXTI_SWIER) --
   ----------------------------------------------------

   type t_exti_lines is array (t_exti_line_index) of bit
      with pack, size => 23;

   type t_EXTI_SWIER is record
      line  : t_exti_lines;
   end record
     with volatile_full_access, size => 32;

   for t_EXTI_SWIER use record
      line  at 0 range  0 .. 22;
   end record;

   --------------------------------
   -- Pending register (EXTI_PR) --
   --------------------------------

   type t_request is (NO_REQUEST, PENDING_REQUEST) with size => 1;
   for  t_request use (NO_REQUEST => 0, PENDING_REQUEST => 1);

   -- Set the bit to '1' to clear it!
   CLEAR_REQUEST : constant t_request := PENDING_REQUEST;

   type t_requests is array (t_exti_line_index) of t_request
      with pack, size => 23;

   type t_EXTI_PR is record
      line  : t_requests;
   end record
     with volatile_full_access, size => 32;

   for t_EXTI_PR use record
      line  at 0 range  0 .. 22;
   end record;

   ---------------------
   -- EXTI peripheral --
   ---------------------

   type t_EXTI_periph is record
      IMR   : t_EXTI_IMR;
      EMR   : t_EXTI_EMR;
      RTSR  : t_EXTI_RTSR;
      FTSR  : t_EXTI_FTSR;
      SWIER : t_EXTI_SWIER;
      PR    : t_EXTI_PR;
   end record
      with volatile;

   for t_EXTI_periph use record
      IMR    at 16#00# range 0 .. 31;
      EMR    at 16#04# range 0 .. 31;
      RTSR   at 16#08# range 0 .. 31;
      FTSR   at 16#0C# range 0 .. 31;
      SWIER  at 16#10# range 0 .. 31;
      PR     at 16#14# range 0 .. 31;
   end record;

   EXTI : t_EXTI_periph
      with
         import,
         volatile,
         address => system'to_address (16#4001_3C00#); -- 0x40013C00

end soc.exti;
