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


package body ewok.mpu.allocator
   with spark_mode => off
is

   function free_region_exist return boolean
   is
   begin
      for region in regions_pool'range loop
         if not regions_pool(region).used then
            return true;
         end if;
      end loop;
      return false;
   end free_region_exist;


   procedure map_in_pool
     (addr           : in  system_address;
      size           : in  unsigned_32; -- in bytes
      region_type    : in  ewok.mpu.t_region_type;
      subregion_mask : in  unsigned_8;
      success        : out boolean)
   is
      region_size    : m4.mpu.t_region_size;
      ok             : boolean;
   begin

      ewok.mpu.bytes_to_region_size (size, region_size, ok);
      if not ok then
         success := false;
         return;
      end if;

      -- Verifying region alignement
      if (unsigned_32 (addr) and (size - 1)) > 0 then
         success := false;
         return;
      end if;

      for region in regions_pool'range loop
         if not regions_pool(region).used then
            regions_pool(region) := (used => true, addr => addr);
            ewok.mpu.set_region
              (region, addr, region_size, region_type, subregion_mask);
            success := true;
            return;
         end if;
      end loop;

      success  := false;

   end map_in_pool;


   procedure unmap_from_pool
     (addr     : in  system_address)
   is
   begin
      for region in regions_pool'range loop
         if regions_pool(region).addr = addr and
            regions_pool(region).used
         then
            m4.mpu.disable_region (region);
            regions_pool(region) := (used => false, addr => 0);
            return;
         end if;
      end loop;
      raise program_error;
   end unmap_from_pool;


   procedure unmap_all_from_pool
   is
   begin
      for region in regions_pool'range loop
         m4.mpu.disable_region (region);
         regions_pool(region) := (used => false, addr => 0);
      end loop;
   end unmap_all_from_pool;

end ewok.mpu.allocator;
