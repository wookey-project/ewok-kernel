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


package soc.dma.interfaces
   with spark_mode => on
is

   type t_dma_interrupts is
     (FIFO_ERROR, DIRECT_MODE_ERROR, TRANSFER_ERROR,
      HALF_COMPLETE, TRANSFER_COMPLETE);

   type t_config_mask is record
      handlers    : boolean;
      buffer_in   : boolean;
      buffer_out  : boolean;
      buffer_size : boolean;
      mode        : boolean;
      priority    : boolean;
      direction   : boolean;
   end record;

   for t_config_mask use record
      handlers    at 0 range 0 .. 0;
      buffer_in   at 0 range 1 .. 1;
      buffer_out  at 0 range 2 .. 2;
      buffer_size at 0 range 3 .. 3;
      mode        at 0 range 4 .. 4;
      priority    at 0 range 5 .. 5;
      direction   at 0 range 6 .. 6;
   end record;

   type t_mode is (DIRECT_MODE, FIFO_MODE, CIRCULAR_MODE);

   type t_transfer_dir is
     (PERIPHERAL_TO_MEMORY, MEMORY_TO_PERIPHERAL, MEMORY_TO_MEMORY);

   type t_priority_level is (LOW, MEDIUM, HIGH, VERY_HIGH);

   type t_data_size is (TRANSFER_BYTE, TRANSFER_HALF_WORD, TRANSFER_WORD);

   type t_burst_size is
     (SINGLE_TRANSFER, INCR_4_BEATS, INCR_8_BEATS, INCR_16_BEATS);

   type t_flow_controller is (DMA_FLOW_CONTROLLER, PERIPH_FLOW_CONTROLLER);

   type t_dma_config is record
      dma_id         : soc.dma.t_dma_periph_index;
      stream         : soc.dma.t_stream_index;
      channel        : soc.dma.t_channel_index;
      bytes          : unsigned_16;
      in_addr        : system_address;
      in_priority    : t_priority_level;
      in_handler     : system_address; -- ISR
      out_addr       : system_address;
      out_priority   : t_priority_level;
      out_handler    : system_address; -- ISR
      flow_controller   : t_flow_controller;
      transfer_dir   : t_transfer_dir;
      mode           : t_mode;
      data_size      : t_data_size;
      memory_inc     : boolean;
      periph_inc     : boolean;
      mem_burst_size : t_burst_size;
      periph_burst_size : t_burst_size;
   end record;

   procedure enable_stream
     (dma_id  : in  soc.dma.t_dma_periph_index;
      stream  : in  soc.dma.t_stream_index);

   procedure disable_stream
     (dma_id  : in  soc.dma.t_dma_periph_index;
      stream  : in  soc.dma.t_stream_index);

   procedure clear_interrupt
     (dma_id      : in  soc.dma.t_dma_periph_index;
      stream      : in  soc.dma.t_stream_index;
      interrupt   : in  t_dma_interrupts);

   procedure clear_all_interrupts
     (dma_id  : in  soc.dma.t_dma_periph_index;
      stream  : in  soc.dma.t_stream_index);

   function get_interrupt_status
     (dma_id  : in  soc.dma.t_dma_periph_index;
      stream  : in  soc.dma.t_stream_index)
      return t_dma_stream_int_status;

   procedure configure_stream
     (dma_id      : in  soc.dma.t_dma_periph_index;
      stream      : in  soc.dma.t_stream_index;
      user_config : in  t_dma_config);

   procedure reconfigure_stream
     (dma_id      : in  soc.dma.t_dma_periph_index;
      stream      : in  soc.dma.t_stream_index;
      user_config : in  t_dma_config;
      to_configure: in  t_config_mask);

   procedure reset_stream
     (dma_id      : in  soc.dma.t_dma_periph_index;
      stream      : in  soc.dma.t_stream_index);

end soc.dma.interfaces;
