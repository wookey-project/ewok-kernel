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


with m4.mpu;
with m4.scb;

package ewok.mpu
  with spark_mode => on
is

   type t_region_type is
     (REGION_TYPE_USER_DATA,
      REGION_TYPE_USER_CODE,
      REGION_TYPE_USER_DEV,
      REGION_TYPE_RO_USER_DEV,
      REGION_TYPE_BOOT_ROM,
      REGION_TYPE_ISR_DATA)
   with size => 32;

   KERN_CODE_REGION        : constant m4.mpu.t_region_number := 0;
   KERN_DEVICES_REGION     : constant m4.mpu.t_region_number := 1;
   KERN_DATA_REGION        : constant m4.mpu.t_region_number := 2;

   USER_DATA_REGION        : constant m4.mpu.t_region_number := 3; -- USER_RAM
   USER_CODE_REGION        : constant m4.mpu.t_region_number := 4; -- USER_TXT
   USER_ISR_STACK_REGION   : constant m4.mpu.t_region_number := 5;
   USER_DEV1_REGION        : constant m4.mpu.t_region_number := 5;
   USER_ISR_DEVICE_REGION  : constant m4.mpu.t_region_number := 6;
   USER_DEV2_REGION        : constant m4.mpu.t_region_number := 6;
   USER_SHARED_REGION      : constant m4.mpu.t_region_number := 7;

   -- How many devices can be mapped in memory
   MAX_DEVICE_REGIONS   : constant := 2;
   device_regions       : array (unsigned_8 range 1 .. MAX_DEVICE_REGIONS)
      of m4.mpu.t_region_number := (USER_DEV1_REGION, USER_DEV2_REGION);

   ---------------
   -- Functions --
   ---------------

   pragma assertion_policy (pre => IGNORE, post => IGNORE, assert => IGNORE);

   -- Initialize the MPU
   procedure init
     (success : out boolean)
      with global => (in_out => (m4.mpu.MPU, m4.scb.SCB));

   --
   -- Utilities so that the kernel can temporary access the whole memory space
   --

   procedure enable_unrestricted_kernel_access
      with
         global => (in_out => (m4.mpu.MPU));

   procedure disable_unrestricted_kernel_access
      with
         global => (in_out => (m4.mpu.MPU));

   -- That function is only used by SPARK prover
   function get_region_size_mask (size : m4.mpu.t_region_size) return unsigned_32
      is (2**(natural (size) + 1) - 1)
      with ghost;

   pragma warnings
     (off, "condition can only be False if invalid values present");

   procedure regions_schedule
     (region_number  : in  m4.mpu.t_region_number;
      addr           : in  system_address;
      size           : in  m4.mpu.t_region_size;
      region_type    : in  t_region_type;
      subregion_mask : in  unsigned_8)
      with
         global => (in_out => (m4.mpu.MPU)),
         pre =>
           (region_number < 8
            and
            (addr and 2#11111#) = 0
            and
            size >= 4
            and
            (addr and get_region_size_mask(size)) = 0);

   pragma warnings (on);

   procedure bytes_to_region_size
     (bytes       : in  unsigned_32;
      region_size : out m4.mpu.t_region_size;
      success     : out boolean)
      with global => null;

end ewok.mpu;
