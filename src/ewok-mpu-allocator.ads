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


package ewok.mpu.allocator
   with spark_mode => on
is

   type t_region_entry is record
      used     : boolean := false;  -- Is region used?
      addr     : system_address;    -- Base address
   end record;

   -------------------------------
   -- Pool of available regions --
   -------------------------------

   regions_pool   : array
     (m4.mpu.t_region_number range USER_FREE_1_REGION .. USER_FREE_2_REGION)
      of t_region_entry
         := (others => (false, 0));

   function free_region_exist return boolean;

   procedure map_in_pool
     (addr           : in  system_address;
      size           : in  unsigned_32;
      region_type    : in  ewok.mpu.t_region_type;
      subregion_mask : in  unsigned_8;
      success        : out boolean)
      with
         pre =>
           (size >= 32
            and
            (size and (size - 1)) = 0   -- Size is a power of 2
            and
            (addr and (size - 1)) = 0); -- Addr is aligned on size

   procedure unmap_from_pool
     (addr           : in  system_address);

   procedure unmap_all_from_pool;

end ewok.mpu.allocator;


