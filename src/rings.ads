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


--
-- Ring buffer generic implementation
--

generic
   type object is private;
   size           : in integer := 512;
   default_object : object;

package rings
   with spark_mode => off
is
   pragma Preelaborate;

   type ring is private;
   type ring_state is (EMPTY, USED, FULL);

   procedure init
     (r : out ring);

   -- write some new data and increment top counter
   procedure write
     (r        : out ring;
      item     : in  object;
      success  : out boolean);

   -- read some data and increment bottom counter
   procedure read
     (r        : in out ring;
      item     : out object;
      success  : out boolean);

   -- decrement top counter
   procedure unwrite
     (r        : out ring;
      success  : out boolean);

   -- return ring state (empty, used or full)
   function state
     (r : in ring)
      return ring_state;
   pragma inline (state);

private

   type ring_range is new integer range 1 .. size;
   type buffer is array (ring_range) of object;

   type ring is record
      buf      : buffer       := (others => default_object);
      top      : ring_range   := ring_range'first; -- place to write
      bottom   : ring_range   := ring_range'first; -- place to read
      state    : ring_state   := EMPTY;
   end record;

end rings;
