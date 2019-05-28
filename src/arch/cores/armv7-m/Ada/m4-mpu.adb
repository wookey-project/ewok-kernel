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

with m4.scb; use m4.scb;

package body m4.mpu
   with spark_mode => on
is

   function address_to_bits_27 (addr : system_address)
      return bits_27
   is
      pragma warnings (off);
      function to_bits_27 is
         new ada.unchecked_conversion (unsigned_32, bits_27);
      pragma warnings (on);
   begin
      return to_bits_27 (shift_right (addr, 5));
   end address_to_bits_27;


   procedure is_mpu_available
     (success  : out boolean)
   is
   begin
      if to_unsigned_32 (MPU.TYPER) = 0 then
         success := false;
      else
         success := true;
      end if;
   end is_mpu_available;


   procedure enable is
   begin
      MPU.CTRL.ENABLE := true;
   end enable;


   procedure disable is
   begin
      MPU.CTRL.ENABLE := false;
   end disable;


   procedure init
   is
   begin
      -- Kernel has *no access* to default memory map
      m4.mpu.MPU.CTRL.PRIVDEFENA := false;

      -- Enable the memory fault exception
      m4.scb.SCB.SHCSR.MEMFAULTENA := true;
   end init;


   procedure enable_unrestricted_kernel_access
   is
   begin
      m4.mpu.MPU.CTRL.PRIVDEFENA := true;
   end enable_unrestricted_kernel_access;


   procedure disable_unrestricted_kernel_access
   is
   begin
      m4.mpu.MPU.CTRL.PRIVDEFENA := false;
   end disable_unrestricted_kernel_access;


   procedure configure_region
     (region   : in  t_region_config)
   is
   begin

      -- Selects which memory region is referenced
      MPU.RNR.REGION := region.region_number;

      -- Defines the base address of the MPU region
      MPU.RBAR :=
        (VALID    => false,
         REGION   => 0,
         ADDR     => address_to_bits_27 (region.addr));

      -- Defines the region size and memory attributes
      MPU.RASR :=
        (ENABLE   => true,
         SIZE     => region.size,
         SRD      => 0,
         B        => region.b,
         C        => false,
         S        => region.S,
         TEX      => 0,
         AP       => region.access_perm,
         XN       => region.xn);

   end configure_region;


   procedure disable_region
     (region_number : in t_region_number)
   is
   begin
      MPU.RNR.REGION    := region_number;
      MPU.RASR.ENABLE   := false;
   end disable_region;


   procedure update_subregion_mask
     (region   : in t_region_config)
   is
   begin
      -- Selects which memory region is referenced
      MPU.RNR.REGION  := region.region_number;

      -- Defines the region size and memory attributes
      MPU.RASR.SRD := region.subregion_mask;
   end update_subregion_mask;

end m4.mpu;
