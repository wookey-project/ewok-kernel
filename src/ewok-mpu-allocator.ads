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

   function is_free_region return boolean is
     (for some R in regions_pool'range => regions_pool(R).used = false)
      with ghost;

   function free_region_exist return boolean;

   function is_power_of_2 (n : unsigned_32)
      return boolean
   with
      post =>
         (if is_power_of_2'result then
            (n and (n - 1)) = 0);

   function to_next_power_of_2 (n : unsigned_32)
      return unsigned_32
   with
      pre  => n > 0 and n <= 2*GBYTE,
      post =>
         to_next_power_of_2'result >= n and
         is_power_of_2 (to_next_power_of_2'result);

   procedure map_in_pool
     (addr           : in  system_address;
      size           : in  unsigned_32;
      region_type    : in  ewok.mpu.t_region_type;
      subregion_mask : in  m4.mpu.t_subregion_mask;
      success        : out boolean);

   procedure unmap_from_pool
     (addr           : in  system_address);

   procedure unmap_all_from_pool;

   -- SPARK
   function is_in_pool
     (addr : system_address) return boolean;

end ewok.mpu.allocator;
