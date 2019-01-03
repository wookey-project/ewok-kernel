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
with ewok.perm;
with ewok.exported.dma;
with ewok.exported.devices;
with soc.interrupts;
with types.c;

package c.socinfo
   with spark_mode => off
is
   subtype t_dev_interrupt_range is
      unsigned_8 range 1 .. ewok.exported.devices.MAX_INTERRUPTS;

   type t_interrupt_list is array (t_dev_interrupt_range) of soc.interrupts.t_interrupt;

   type t_device_soc_infos is record
      name_ptr        : system_address;
      base_addr       : system_address;
      rcc_enr         : system_address;
      rcc_enb         : unsigned_32;
      size            : unsigned_32;
      subregions      : unsigned_8;
      interrupt_list  : t_interrupt_list;
      ro              : types.c.bool;
      minperm         : ewok.perm.t_perm_name;
   end record;

   type t_device_soc_infos_access is access all t_device_soc_infos;

   function to_device_soc_infos is new ada.unchecked_conversion
     (system_address, t_device_soc_infos_access);

   function soc_devmap_find_device
     (addr : system_address;
      size : unsigned_32)
      return t_device_soc_infos_access
   with
      convention     => c,
      import         => true,
      external_name  => "soc_devmap_find_device";

   function soc_devmap_find_dma_device
     (dma_controller : ewok.exported.dma.t_controller;
      stream         : ewok.exported.dma.t_stream)
      return t_device_soc_infos_access
   with
      convention     => c,
      import         => true,
      external_name  => "soc_devices_get_dma";

   procedure soc_devmap_enable_clock
     (socdev   : t_device_soc_infos)
   with
      convention     => c,
      import         => true,
      external_name  => "soc_devmap_enable_clock";

end c.socinfo;
