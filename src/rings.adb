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


package body rings
   with spark_mode => off
is

   procedure init
     (r : out ring)
   is
   begin
      r.buf    := (others => default_object);
      r.top    := ring_range'first;
      r.bottom := ring_range'first;
      r.state  := EMPTY;
   end init;


   procedure write
     (r        : out ring;
      item     : in  object;
      success  : out boolean)
   is
   begin

      if r.state = FULL then
         success := false;
         return;
      end if;

      -- write
      r.buf(r.top) := item;

      -- increment top
      if r.top = r.buf'last then
         r.top := r.buf'first;
      else
         r.top := r.top + 1;
      end if;

      -- adjust state
      if r.top = r.bottom then
         r.state := FULL;
      else
         r.state := USED;
      end if;

      success := true;

   end write;


   procedure read
     (r        : in out ring;
      item     : out object;
      success  : out boolean)
   is
   begin

      -- read data only if buffer is not empty
      if r.state = EMPTY then
         success := false;
         return;
      end if;

      -- read
      item := r.buf(r.bottom);

      -- incrementing bottom
      if r.bottom = r.buf'last then
         r.bottom := r.buf'first;
      else
         r.bottom := r.bottom + 1;
      end if;

      -- adjust state
      if r.bottom = r.top then
         r.state := EMPTY;
      else
         r.state := USED;
      end if;

      success := true;

   end read;


   procedure unwrite
     (r        : out ring;
      success  : out boolean)
   is
   begin

      if r.state = EMPTY then
         success := false;
         return;
      end if;

      -- decrementing top counter
      if r.top = r.buf'first then
         r.top := r.buf'last;
      else
         r.top := r.top - 1;
      end if;

      -- adjust state
      if r.bottom = r.top then
         r.state := EMPTY;
      else
         r.state := USED;
      end if;

      success := true;

   end unwrite;


   function state
     (r : in ring)
      return ring_state
   is
   begin
      return r.state;
   end state;

end rings;
