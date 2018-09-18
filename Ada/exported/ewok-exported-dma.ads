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

with ewok.tasks_shared; use ewok.tasks_shared;
with soc.dma.interfaces;
with types.c;

package ewok.exported.dma
   with spark_mode => off
is

   -- Specify DMA elements to (re)configure
   type t_config_mask is new soc.dma.interfaces.t_config_mask;

   --
   -- User defined DMA configuration
   --

   type t_mode is new soc.dma.interfaces.t_mode;
   type t_transfer_dir is new soc.dma.interfaces.t_transfer_dir;
   type t_priority_level is new soc.dma.interfaces.t_priority_level;
   type t_data_size is new soc.dma.interfaces.t_data_size;
   type t_burst_size is new soc.dma.interfaces.t_burst_size;
   type t_flow_controller is new soc.dma.interfaces.t_flow_controller;

   type t_controller is new soc.dma.t_dma_periph_index with size => 8;
   subtype t_stream  is unsigned_8 range 0 .. 7;
   subtype t_channel is unsigned_8 range 0 .. 7;

   type t_dma_user_config is record
      in_addr        : system_address;
      out_addr       : system_address;
      in_priority    : t_priority_level;
      out_priority   : t_priority_level;
      size           : unsigned_16; -- size in bytes
      controller     : t_controller := ID_DMA1;
      channel        : t_channel    := 0;
      stream         : t_stream     := 0;
      flow_controller   : t_flow_controller;
      transfer_dir   : t_transfer_dir;
      mode           : t_mode;
      memory_inc     : types.c.bool;
      periph_inc     : types.c.bool;
      data_size      : t_data_size;
      mem_burst_size : t_burst_size;
      periph_burst_size : t_burst_size;
      in_handler     : system_address; -- ISR
      out_handler    : system_address; -- ISR
   end record;

   type t_dma_user_config_access is access all t_dma_user_config;

   type t_dma_shm_access is (SHM_ACCESS_READ, SHM_ACCESS_WRITE);

   -- The caller (accessed_id) grant access to another task (granted_id)
   -- to a range in its inner memory space. That mechanism permits to the
   -- 'granted' to configure the DMA with an address that belongs to
   -- the 'accessed' task.
   type t_dma_shm_info is record
      granted_id     : t_task_id;
      accessed_id    : t_task_id; -- caller
      base           : system_address;
      size           : unsigned_16;
      access_type    : t_dma_shm_access;
   end record;

end ewok.exported.dma;
