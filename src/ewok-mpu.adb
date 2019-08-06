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


with ada.unchecked_conversion;

with m4.mpu;   use m4.mpu;
with ewok.mpu.handler;
with ewok.layout;
with ewok.debug;
with soc.layout;
with applications; -- generated

package body ewok.mpu
  with spark_mode => on
is

   procedure init
     (success : out boolean)
     with spark_mode => off  -- handler is not SPARK compatible
   is
      -- Layout mapping validation of generated constants
      pragma assert
        (applications.txt_kern_size + applications.txt_kern_region_base
            <= applications.txt_user_region_base);

      function get_region_size (size : t_region_size) return unsigned_32
         is (2**(natural (size) + 1));

   begin

      --
      -- Initializing the MPU
      --

      -- Testing if there's an MPU
      m4.mpu.is_mpu_available (success);

      if not success then
         pragma DEBUG (debug.log (debug.ERROR, "No MPU!"));
         return;
      end if;

      -- Register memory fault handler
      -- Note: unproved because SPARK doesn't allow "'address" attribute
      ewok.mpu.handler.init; -- not PARK compatible

      -- Disable MPU
      m4.mpu.disable;

      -- Enable privileged software access (PRIVDEFENA) to default memory map
      -- and enable the memory fault exception. When ENABLE and PRIVDEFENA are
      -- both set to 1, privileged code can freely access the default memory
      -- map. Any access by unprivileged software that does not address an
      -- enabled memory region causes a memory management fault.
      m4.mpu.init;

      --
      -- Configuring MPU regions
      --

      -- Region: kernel code
      if get_region_size (REGION_SIZE_64KB) /= ewok.layout.FW1_KERN_SIZE then
         pragma DEBUG
           (debug.log (debug.ERROR, "MPU: invalid 'KERNEL CODE' size"));
         return;
      end if;

      set_region
        (region_number  => KERN_CODE_REGION,
         addr           => applications.txt_kern_region_base,
         size           => applications.txt_kern_region_size,
         region_type    => REGION_TYPE_KERN_CODE,
         subregion_mask => 0);

      -- Region: devices that may be accessed by the kernel
      set_region
        (region_number  => KERN_DEVICES_REGION,
         addr           => soc.layout.PERIPH_BASE,
         size           => REGION_SIZE_512MB,
         region_type    => REGION_TYPE_KERN_DEVICES,
         subregion_mask => 0);

      -- Region: kernel data + stack
      if get_region_size (REGION_SIZE_64KB) /= ewok.layout.KERN_DATA_SIZE then
         pragma DEBUG
           (debug.log (debug.ERROR, "MPU: invalid 'KERNEL DATA' size"));
         return;
      end if;

      set_region
        (region_number  => KERN_DATA_REGION,
         addr           => ewok.layout.KERN_DATA_BASE,
         size           => REGION_SIZE_64KB,
         region_type    => REGION_TYPE_KERN_DATA,
         subregion_mask => 0);

      -- Region: user data
      -- Note: This is for the whole area. Each task will use only a fixed
      --       number of sub-regions
      if get_region_size (REGION_SIZE_128KB) /= ewok.layout.USER_RAM_SIZE then
         pragma DEBUG (debug.log (debug.ERROR, "MPU: invalid 'USER DATA' size"));
         return;
      end if;

      set_region
        (region_number  => USER_DATA_REGION,
         addr           => ewok.layout.USER_DATA_BASE,
         size           => REGION_SIZE_128KB,
         region_type    => REGION_TYPE_USER_DATA,
         subregion_mask => 0);

      -- Region: user code
      -- Note: This is for the whole area. Each task will use only a fixed
      --       number of sub-regions
      if get_region_size (REGION_SIZE_256KB) /= ewok.layout.FW1_USER_SIZE then
         pragma DEBUG (debug.log (debug.ERROR, "MPU: invalid 'USER CODE' size"));
         return;
      end if;

      set_region
        (region_number  => USER_CODE_REGION,
         addr           => applications.txt_user_region_base,
         size           => applications.txt_user_region_size,
         region_type    => REGION_TYPE_USER_CODE,
         subregion_mask => 0);

      pragma DEBUG (debug.log (debug.INFO, "MPU is configured"));
      m4.mpu.enable;
      pragma DEBUG (debug.log (debug.INFO, "MPU is enabled"));

   end init;


   procedure enable_unrestricted_kernel_access
   is
   begin
      m4.mpu.enable_unrestricted_kernel_access;
   end enable_unrestricted_kernel_access;


   procedure disable_unrestricted_kernel_access
   is
   begin
      m4.mpu.disable_unrestricted_kernel_access;
   end disable_unrestricted_kernel_access;


   procedure set_region
     (region_number  : in  m4.mpu.t_region_number;
      addr           : in  system_address;
      size           : in  m4.mpu.t_region_size;
      region_type    : in  t_region_type;
      subregion_mask : in  unsigned_8)
   is
      access_perm    : m4.mpu.t_region_perm;
      xn, b, s       : boolean;
      region_config  : m4.mpu.t_region_config;
   begin
      -- A memory region must never be mapped RWX
      case (region_type) is

         when REGION_TYPE_KERN_CODE =>
            access_perm := REGION_PERM_PRIV_RO_USER_NO;
            xn          := false;
            b           := false;
            s           := false;

         when REGION_TYPE_KERN_DATA =>
            access_perm := REGION_PERM_PRIV_RW_USER_NO;
            xn          := true;
            b           := false;
            s           := true;

         when REGION_TYPE_KERN_DEVICES =>
            access_perm := REGION_PERM_PRIV_RW_USER_NO;
            xn          := true;
            b           := true;
            s           := true;

         when REGION_TYPE_USER_CODE =>
            access_perm := REGION_PERM_PRIV_RO_USER_RO;
            xn          := false;
            b           := false;
            s           := false;

         when REGION_TYPE_USER_DATA =>
            access_perm := REGION_PERM_PRIV_RW_USER_RW;
            xn          := true;
            b           := false;
            s           := true;

         when REGION_TYPE_USER_DEV =>
            access_perm := REGION_PERM_PRIV_RW_USER_RW;
            xn          := true;
            b           := true;
            s           := true;

         when REGION_TYPE_USER_DEV_RO =>
            access_perm := REGION_PERM_PRIV_RW_USER_RO;
            xn          := true;
            b           := true;
            s           := true;

         when REGION_TYPE_ISR_STACK =>
            access_perm := REGION_PERM_PRIV_RW_USER_RW;
            xn          := true;
            b           := false;
            s           := true;
      end case;

      region_config :=
        (region_number  => region_number,
         addr           => addr,
         size           => size,
         access_perm    => access_perm,
         xn             => xn,
         b              => b,
         s              => s,
         subregion_mask => subregion_mask);

      m4.mpu.configure_region (region_config);

   end set_region;


   procedure update_subregions
     (region_number  : in  m4.mpu.t_region_number;
      subregion_mask : in  unsigned_8)
   is
   begin
      m4.mpu.update_subregion_mask (region_number, subregion_mask);
   end update_subregions;


   procedure bytes_to_region_size
     (bytes       : in  unsigned_32;
      region_size : out m4.mpu.t_region_size;
      success     : out boolean)
   is
   begin
      success := true;
      case (bytes) is
         when 32        => region_size := REGION_SIZE_32B;
         when 64        => region_size := REGION_SIZE_64B;
         when 128       => region_size := REGION_SIZE_128B;
         when 256       => region_size := REGION_SIZE_256B;
         when 512       => region_size := REGION_SIZE_512B;
         when 1*KBYTE   => region_size := REGION_SIZE_1KB;
         when 2*KBYTE   => region_size := REGION_SIZE_2KB;
         when 4*KBYTE   => region_size := REGION_SIZE_4KB;
         when 8*KBYTE   => region_size := REGION_SIZE_8KB;
         when 16*KBYTE  => region_size := REGION_SIZE_16KB;
         when 32*KBYTE  => region_size := REGION_SIZE_32KB;
         when 64*KBYTE  => region_size := REGION_SIZE_64KB;
         when 128*KBYTE => region_size := REGION_SIZE_128KB;
         when 256*KBYTE => region_size := REGION_SIZE_256KB;
         when 512*KBYTE => region_size := REGION_SIZE_512KB;
         when 1*MBYTE   => region_size := REGION_SIZE_1MB;
         when 2*MBYTE   => region_size := REGION_SIZE_2MB;
         when 4*MBYTE   => region_size := REGION_SIZE_4MB;
         when 8*MBYTE   => region_size := REGION_SIZE_8MB;
         when 16*MBYTE  => region_size := REGION_SIZE_16MB;
         when 32*MBYTE  => region_size := REGION_SIZE_32MB;
         when 64*MBYTE  => region_size := REGION_SIZE_64MB;
         when 128*MBYTE => region_size := REGION_SIZE_128MB;
         when 256*MBYTE => region_size := REGION_SIZE_256MB;
         when 512*MBYTE => region_size := REGION_SIZE_512MB;
         when 1*GBYTE   => region_size := REGION_SIZE_1GB;
         when 2*GBYTE   => region_size := REGION_SIZE_2GB;
         when others    =>
            region_size := REGION_SIZE_32B;
            success     := false;
      end case;
   end bytes_to_region_size;


   function can_be_mapped return boolean
   is
   begin
      for region in regions_pool'range loop
         if not regions_pool(region).used then
            return true;
         end if;
      end loop;
      return false;
   end can_be_mapped;


   procedure map
     (addr           : in  system_address;
      size           : in  unsigned_32;
      region_type    : in  ewok.mpu.t_region_type;
      subregion_mask : in  unsigned_8;
      success        : out boolean)
   is
      region_size    : m4.mpu.t_region_size;
      ok             : boolean;
   begin
      for region in regions_pool'range loop
         if not regions_pool(region).used then
            ewok.mpu.bytes_to_region_size (size, region_size, ok);
            if not ok then
               raise program_error;
            end if;
            regions_pool(region).used := true;
            regions_pool(region).addr := addr;
            ewok.mpu.set_region
              (region, addr, region_size, region_type, subregion_mask);
            success := true;
            return;
         end if;
      end loop;
      success := false;
   end map;


   procedure unmap
     (addr           : in  system_address)
   is
   begin
      for region in regions_pool'range loop
         if regions_pool(region).addr = addr and then
            regions_pool(region).used
         then
            m4.mpu.disable_region (region);
            regions_pool(region) := (false, 0);
            return;
         end if;
      end loop;
      raise program_error;
   end unmap;

   procedure unmap_userspace
   is
   begin
      update_subregions
         (region_number  => USER_CODE_REGION,
         subregion_mask  => 16#FF#);
      update_subregions
         (region_number  => USER_DATA_REGION,
         subregion_mask  => 16#FF#);
   end unmap_userspace;

   procedure unmap_all
   is
   begin
      for region in regions_pool'range loop
         if regions_pool(region).used then
            regions_pool(region) := (false, 0);
            m4.mpu.disable_region (region);
         end if;
      end loop;
   end unmap_all;


end ewok.mpu;
