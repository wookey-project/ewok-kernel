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

with m4.layout;
with m4.scb;

package m4.mpu
   with spark_mode => on
is

   ------------
   -- Config --
   ------------

   subtype t_region_number is unsigned_8 range 0 .. 7;
   subtype t_region_size   is bits_5     range 4 .. 31;
   subtype t_region_perm   is bits_3;

   subtype t_subregion     is unsigned_8 range 1 .. 8;

   type t_subregion_status is
     (SUB_REGION_ENABLED,
      SUB_REGION_DISABLED)
      with size => 1;

   for t_subregion_status use
     (SUB_REGION_ENABLED   => 0,
      SUB_REGION_DISABLED  => 1);

   type t_subregion_mask is
      array (t_subregion) of t_subregion_status
         with pack, size => 8;

   function to_subregion_mask is new ada.unchecked_conversion
      (unsigned_8, t_subregion_mask);

   function to_unsigned_8 is new ada.unchecked_conversion
      (t_subregion_mask, unsigned_8);

   type t_region_config is record
      region_number  : t_region_number;
      addr           : system_address;
      size           : t_region_size;
      access_perm    : t_region_perm;
      xn             : boolean;  -- Execute Never
      b              : boolean;
      s              : boolean;
      subregion_mask : t_subregion_mask;
   end record;

   REGION_SIZE_32B   : constant t_region_size := 4;
   REGION_SIZE_64B   : constant t_region_size := 5;
   REGION_SIZE_128B  : constant t_region_size := 6;
   REGION_SIZE_256B  : constant t_region_size := 7;
   REGION_SIZE_512B  : constant t_region_size := 8;
   REGION_SIZE_1KB   : constant t_region_size := 9;
   REGION_SIZE_2KB   : constant t_region_size := 10;
   REGION_SIZE_4KB   : constant t_region_size := 11;
   REGION_SIZE_8KB   : constant t_region_size := 12;
   REGION_SIZE_16KB  : constant t_region_size := 13;
   REGION_SIZE_32KB  : constant t_region_size := 14;
   REGION_SIZE_64KB  : constant t_region_size := 15;
   REGION_SIZE_128KB : constant t_region_size := 16;
   REGION_SIZE_256KB : constant t_region_size := 17;
   REGION_SIZE_512KB : constant t_region_size := 18;
   REGION_SIZE_1MB   : constant t_region_size := 19;
   REGION_SIZE_2MB   : constant t_region_size := 20;
   REGION_SIZE_4MB   : constant t_region_size := 21;
   REGION_SIZE_8MB   : constant t_region_size := 22;
   REGION_SIZE_16MB  : constant t_region_size := 23;
   REGION_SIZE_32MB  : constant t_region_size := 24;
   REGION_SIZE_64MB  : constant t_region_size := 25;
   REGION_SIZE_128MB : constant t_region_size := 26;
   REGION_SIZE_256MB : constant t_region_size := 27;
   REGION_SIZE_512MB : constant t_region_size := 28;
   REGION_SIZE_1GB   : constant t_region_size := 29;
   REGION_SIZE_2GB   : constant t_region_size := 30;
   REGION_SIZE_4GB   : constant t_region_size := 31;

   -- Access Permissions
   -- Note: Describes privileged and user access.
   --       For example, REGION_PERM_PRIV_RW_USER_NO means
   --       - privileged : read/write access
   --       - user       : no access

   REGION_PERM_PRIV_NO_USER_NO   : constant t_region_perm := 2#000#;
   REGION_PERM_PRIV_RW_USER_NO   : constant t_region_perm := 2#001#;
   REGION_PERM_PRIV_RW_USER_RO   : constant t_region_perm := 2#010#;
   REGION_PERM_PRIV_RW_USER_RW   : constant t_region_perm := 2#011#;
   REGION_PERM_UNUSED            : constant t_region_perm := 2#100#;
   REGION_PERM_PRIV_RO_USER_NO   : constant t_region_perm := 2#101#;
   REGION_PERM_PRIV_RO_USER_RO   : constant t_region_perm := 2#110#;
   REGION_PERM_PRIV_RO_USER_RO2  : constant t_region_perm := 2#111#;

   ---------------
   -- Functions --
   ---------------

   procedure is_mpu_available
     (success  : out boolean)
      with
         inline_always,
         Global         => (In_Out => MPU);

   procedure enable
      with
         inline_always,
         global => (in_out => (MPU));

   procedure disable
      with
         inline_always,
         global => (in_out => (MPU));

   procedure disable_region
     (region_number : in t_region_number)
      with
         inline_always,
         global => (in_out => (MPU));

   -- Return true if configured region is executable and writable 
   -- by the CPU in privileged or unprivileged mode
   function region_rwx(region : t_region_config) return boolean
      is (region.xn = false and
          (region.access_perm = REGION_PERM_PRIV_RW_USER_NO or
           region.access_perm = REGION_PERM_PRIV_RW_USER_RO or
           region.access_perm = REGION_PERM_PRIV_RW_USER_RW))
      with ghost;

   procedure init
      with
         global => (in_out => (MPU, m4.scb.SCB));

   procedure enable_unrestricted_kernel_access
      with
         inline_always,
         global => (in_out => (MPU));

   procedure disable_unrestricted_kernel_access
      with
         inline_always,
         global => (in_out => (MPU));

   -- That function is only used by SPARK prover
   function get_region_size_mask (size : t_region_size) return unsigned_32
      is (2**(natural (size) + 1) - 1)
      with ghost;

   pragma assertion_policy (pre => IGNORE, post => IGNORE, assert => IGNORE);
   pragma warnings (off, "explicit membership test may be optimized");
   pragma warnings (off, "condition can only be False if invalid values present");

   procedure configure_region
     (region   : in t_region_config)
      with
         global => (in_out => (MPU)),
         pre =>
           (region.region_number in 0 .. 7
            and
            (region.addr and 2#11111#) = 0
            and
            region.size >= 4
            and
            (region.addr and get_region_size_mask(region.size)) = 0)
            and not region_rwx (region);

   procedure update_subregion_mask
     (region_number  : in t_region_number;
      subregion_mask : in t_subregion_mask)
      with
         inline_always,
         global => (in_out => (MPU));

   pragma warnings (on);

   -----------------------
   -- MPU Type Register --
   -----------------------

   type t_MPU_TYPE is record
      SEPARAT  : boolean    := true;   -- Support for separate instruction and date memory maps
      DREGION  : unsigned_8 := 8;      -- Number of supported MPU data regions
      IREGION  : unsigned_8 := 0;      -- Number of supported MPU instruction regions
   end record
   with size => 32;

   for t_MPU_TYPE use
   record
      SEPARAT  at 0 range 0 .. 0;
      DREGION  at 0 range 8 .. 15;
      IREGION  at 0 range 16 .. 23;
   end record;

   function to_unsigned_32 is new ada.unchecked_conversion
     (t_MPU_TYPE, unsigned_32);

   --------------------------
   -- MPU Control Register --
   --------------------------

   type t_MPU_CTRL is record
      ENABLE      : boolean;  -- Enables the MPU
      HFNMIENA    : boolean;  -- Enables the operation of MPU during hard fault,
                              -- NMI, and FAULTMASK handlers
      PRIVDEFENA  : boolean;  -- Enables privileged software access to the
                              -- default memory map
   end record
   with size => 32;

   for t_MPU_CTRL use record
      ENABLE      at 0 range 0 .. 0;
      HFNMIENA    at 0 range 1 .. 1;
      PRIVDEFENA  at 0 range 2 .. 2;
   end record;

   --------------------------------
   -- MPU Region Number Register --
   --------------------------------

   type t_MPU_RNR is record
      REGION : unsigned_8 range 0 .. 7; -- Indicates the region referenced by
                                        -- MPU_RBAR and MPU_RASR
   end record
   with size => 32;

   for t_MPU_RNR use record
      REGION   at 0 range 0 .. 7;
   end record;

   --------------------------------------
   -- MPU Region Base Address Register --
   --------------------------------------

   --
   -- Defines the base address of the MPU region selected by the MPU_RNR
   --

   type t_MPU_RBAR is record
      REGION   : bits_4 range 0 .. 7;
      VALID    : boolean;
      ADDR     : bits_27;
   end record
   with size => 32;

   for t_MPU_RBAR use record
      REGION   at 0 range 0 .. 3;
      VALID    at 0 range 4 .. 4;
      ADDR     at 0 range 5 .. 31;
   end record;

   function address_to_bits_27 (addr : system_address)
      return bits_27
   with pre => (addr and 2#11111#) = 0;

   --------------------------------------------
   -- MPU Region Attribute and Size Register --
   --------------------------------------------

   type t_MPU_RASR is record
      ENABLE   : boolean;        -- Enable region
      SIZE     : t_region_size;
      SRD      : unsigned_8;     -- Subregion disable bits (0 = enabled, 1 = disabled)
      B        : boolean;
      C        : boolean;
      S        : boolean;        -- Shareable
      TEX      : bits_3;         -- Memory attributes
      AP       : t_region_perm;  -- Permissions
      XN       : boolean;        -- Instruction fetches disabled
   end record
   with size => 32;

   for t_MPU_RASR use record
      ENABLE   at 0 range 0 .. 0;
      SIZE     at 0 range 1 .. 5;
      SRD      at 0 range 8 .. 15;
      B        at 0 range 16 .. 16;
      C        at 0 range 17 .. 17;
      S        at 0 range 18 .. 18;
      TEX      at 0 range 19 .. 21;
      AP       at 0 range 24 .. 26;
      XN       at 0 range 28 .. 28;
   end record;

   function to_MPU_RASR is new ada.unchecked_conversion
     (unsigned_32, t_MPU_RASR);

   --------------------
   -- MPU peripheral --
   --------------------

   type t_MPU_peripheral is record
      TYPER    : t_MPU_TYPE;
      CTRL     : t_MPU_CTRL;
      RNR      : t_MPU_RNR;
      RBAR     : t_MPU_RBAR;
      RASR     : t_MPU_RASR;
      RBAR_A1  : t_MPU_RBAR;
      RASR_A1  : t_MPU_RASR;
      RBAR_A2  : t_MPU_RBAR;
      RASR_A2  : t_MPU_RASR;
      RBAR_A3  : t_MPU_RBAR;
      RASR_A3  : t_MPU_RASR;
   end record;

   for t_MPU_peripheral use record
      TYPER    at 16#00# range 0 .. 31;
      CTRL     at 16#04# range 0 .. 31;
      RNR      at 16#08# range 0 .. 31;
      RBAR     at 16#0C# range 0 .. 31;
      RASR     at 16#10# range 0 .. 31;
      RBAR_A1  at 16#14# range 0 .. 31;
      RASR_A1  at 16#18# range 0 .. 31;
      RBAR_A2  at 16#1C# range 0 .. 31;
      RASR_A2  at 16#20# range 0 .. 31;
      RBAR_A3  at 16#24# range 0 .. 31;
      RASR_A3  at 16#28# range 0 .. 31;
   end record;

   ----------------
   -- Peripheral --
   ----------------

   MPU   : t_MPU_peripheral
      with
         import,
         volatile,
         address => m4.layout.MPU_base;

end m4.mpu;
