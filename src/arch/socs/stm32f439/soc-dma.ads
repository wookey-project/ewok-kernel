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

with soc.layout;
with soc.interrupts;
with system;

package soc.dma
   with spark_mode => on
is

   type t_dma_periph_index is (ID_DMA1, ID_DMA2);
   for t_dma_periph_index use (ID_DMA1 => 1, ID_DMA2 => 2);

   type t_stream_index  is range 0 .. 7;
   type t_channel_index is range 0 .. 7 with size => 3;

   ------------------------------------------
   -- DMA interrupt status registers (ISR) --
   ------------------------------------------

   type t_dma_stream_int_status is record
      -- Stream FIFO error interrupt flag (FEIF)
      FIFO_ERROR        : boolean;
      -- Stream direct mode error interrupt flag (DMEIF)
      DIRECT_MODE_ERROR : boolean;
      -- Stream transfer error interrupt flag (TEIF)
      TRANSFER_ERROR    : boolean;
      -- Stream half transfer interrupt flag (HTIF)
      HALF_COMPLETE     : boolean;
      -- Stream transfer complete interrupt flag (TCIF)
      TRANSFER_COMPLETE : boolean;
   end record
      with size => 6;

   for t_dma_stream_int_status use record
      FIFO_ERROR        at 0 range 0 .. 0;
      DIRECT_MODE_ERROR at 0 range 2 .. 2;
      TRANSFER_ERROR    at 0 range 3 .. 3;
      HALF_COMPLETE     at 0 range 4 .. 4;
      TRANSFER_COMPLETE at 0 range 5 .. 5;
   end record;

   --
   -- DMA low interrupt status register (DMA_LISR)
   --

   type t_DMA_LISR is record
      stream_0       : t_dma_stream_int_status;
      stream_1       : t_dma_stream_int_status;
      reserved_12_15 : bits_4;
      stream_2       : t_dma_stream_int_status;
      stream_3       : t_dma_stream_int_status;
      reserved_28_31 : bits_4;
   end record
      with pack, size => 32, volatile_full_access;

   --
   -- DMA high interrupt status register (DMA_HISR)
   --

   type t_DMA_HISR is record
      stream_4       : t_dma_stream_int_status;
      stream_5       : t_dma_stream_int_status;
      reserved_12_15 : bits_4;
      stream_6       : t_dma_stream_int_status;
      stream_7       : t_dma_stream_int_status;
      reserved_28_31 : bits_4;
   end record
      with pack, size => 32, volatile_full_access;

   ----------------------------------------
   -- DMA interrupt flag clear registers --
   ----------------------------------------

   type t_dma_stream_clear_interrupts is record
      -- Stream clear FIFO error interrupt flag (CFEIF)
      CLEAR_FIFO_ERROR        : boolean;
      -- Stream clear direct mode error interrupt flag (CDMEIF)
      CLEAR_DIRECT_MODE_ERROR : boolean;
      -- Stream clear transfer error interrupt flag (CTEIF)
      CLEAR_TRANSFER_ERROR    : boolean;
      -- Stream clear half transfer interrupt flag (CHTIF)
      CLEAR_HALF_TRANSFER     : boolean;
      -- Stream clear transfer complete interrupt flag (CTCIF)
      CLEAR_TRANSFER_COMPLETE : boolean;
   end record
      with size => 6;

   for t_dma_stream_clear_interrupts use record
      CLEAR_FIFO_ERROR           at 0 range 0 .. 0;
      CLEAR_DIRECT_MODE_ERROR    at 0 range 2 .. 2;
      CLEAR_TRANSFER_ERROR       at 0 range 3 .. 3;
      CLEAR_HALF_TRANSFER        at 0 range 4 .. 4;
      CLEAR_TRANSFER_COMPLETE    at 0 range 5 .. 5;
   end record;

   --
   -- DMA low interrupt flag clear register (DMA_LIFCR)
   --

   type t_DMA_LIFCR is record
      stream_0       : t_dma_stream_clear_interrupts;
      stream_1       : t_dma_stream_clear_interrupts;
      reserved_12_15 : bits_4;
      stream_2       : t_dma_stream_clear_interrupts;
      stream_3       : t_dma_stream_clear_interrupts;
      reserved_28_31 : bits_4;
   end record
      with pack, size => 32, volatile_full_access;

   --
   -- DMA high interrupt flag clear register (DMA_HIFCR)
   --

   type t_DMA_HIFCR is record
      stream_4       : t_dma_stream_clear_interrupts;
      stream_5       : t_dma_stream_clear_interrupts;
      reserved_12_15 : bits_4;
      stream_6       : t_dma_stream_clear_interrupts;
      stream_7       : t_dma_stream_clear_interrupts;
      reserved_28_31 : bits_4;
   end record
      with pack, size => 32, volatile_full_access;


   ----------------------------------------------------
   -- DMA stream x configuration register (DMA_SxCR) --
   ----------------------------------------------------

   type t_flow_controller is (DMA_FLOW_CONTROLLER, PERIPH_FLOW_CONTROLLER)
      with size => 1;
   for t_flow_controller use
     (DMA_FLOW_CONTROLLER     => 0,
      PERIPH_FLOW_CONTROLLER  => 1);

   type t_transfer_dir is
     (PERIPHERAL_TO_MEMORY, MEMORY_TO_PERIPHERAL, MEMORY_TO_MEMORY)
      with size => 2;
   for t_transfer_dir use
     (PERIPHERAL_TO_MEMORY => 2#00#,
      MEMORY_TO_PERIPHERAL => 2#01#,
      MEMORY_TO_MEMORY     => 2#10#);

   type t_data_size is
     (TRANSFER_BYTE, TRANSFER_HALF_WORD, TRANSFER_WORD)
      with size => 2;
   for t_data_size use
     (TRANSFER_BYTE        => 2#00#,
      TRANSFER_HALF_WORD   => 2#01#,
      TRANSFER_WORD        => 2#10#);

   type t_increment_offset_size is (INCREMENT_PSIZE, INCREMENT_WORD)
      with size => 1;
   for t_increment_offset_size use
     (INCREMENT_PSIZE   => 0,
      INCREMENT_WORD    => 1);

   type t_priority_level is (LOW, MEDIUM, HIGH, VERY_HIGH) with size => 2;
   for t_priority_level use
     (LOW         => 2#00#,
      MEDIUM      => 2#01#,
      HIGH        => 2#10#,
      VERY_HIGH   => 2#11#);

   type t_current_target is (MEMORY_0, MEMORY_1) with size => 1;
   for t_current_target use
     (MEMORY_0 => 0,
      MEMORY_1 => 1);

   type t_burst_size is
     (SINGLE_TRANSFER, INCR_4_BEATS, INCR_8_BEATS, INCR_16_BEATS)
      with size => 2;
   for t_burst_size use
     (SINGLE_TRANSFER   => 2#00#,
      INCR_4_BEATS      => 2#01#,
      INCR_8_BEATS      => 2#10#,
      INCR_16_BEATS     => 2#11#);

   type t_DMA_SxCR is record
      EN                : boolean            := false; -- Stream enable
      DIRECT_MODE_ERROR : boolean            := false; -- DMEIE
      TRANSFER_ERROR    : boolean            := false; -- TEIE
      HALF_COMPLETE     : boolean            := false; -- HTIE
      TRANSFER_COMPLETE : boolean            := false; -- TCIE
      PFCTRL            : t_flow_controller  := DMA_FLOW_CONTROLLER;
      DIR               : t_transfer_dir     := PERIPHERAL_TO_MEMORY;
      CIRC              : boolean            := false; -- Circular mode enable
      PINC              : boolean            := false; -- Peripheral incr. mode enable
      MINC              : boolean            := false; -- Memory incr. mode enable
      PSIZE             : t_data_size        := TRANSFER_BYTE; -- Peripheral data size
      MSIZE             : t_data_size        := TRANSFER_BYTE; -- Memory data size
      PINCOS            : t_increment_offset_size := INCREMENT_PSIZE;
      PL                : t_priority_level   := LOW;
      DBM               : boolean            := false; -- Double buffer mode
      CT                : t_current_target   := MEMORY_0;
      reserved_20       : bit                := 0;
      PBURST            : t_burst_size       := SINGLE_TRANSFER; -- Periph. burst transfer
      MBURST            : t_burst_size       := SINGLE_TRANSFER; -- Memory burst transfer
      CHSEL             : t_channel_index    := 0; -- Channel selection (0..7)
      reserved_28_31    : bits_4             := 0;
   end record
      with size => 32, volatile_full_access;

   for t_DMA_SxCR use record
      EN                      at 0 range 0 .. 0;
      DIRECT_MODE_ERROR       at 0 range 1 .. 1;
      TRANSFER_ERROR          at 0 range 2 .. 2;
      HALF_COMPLETE  at 0 range 3 .. 3;
      TRANSFER_COMPLETE       at 0 range 4 .. 4;
      PFCTRL   			      at 0 range 5 .. 5;
      DIR      			      at 0 range 6 .. 7;
      CIRC     			      at 0 range 8 .. 8;
      PINC     			      at 0 range 9 .. 9;
      MINC     			      at 0 range 10 .. 10;
      PSIZE    			      at 0 range 11 .. 12;
      MSIZE    			      at 0 range 13 .. 14;
      PINCOS   			      at 0 range 15 .. 15;
      PL       			      at 0 range 16 .. 17;
      DBM      			      at 0 range 18 .. 18;
      CT       			      at 0 range 19 .. 19;
      reserved_20             at 0 range 20 .. 20;
      PBURST   			      at 0 range 21 .. 22;
      MBURST   			      at 0 range 23 .. 24;
      CHSEL    			      at 0 range 25 .. 27;
      reserved_28_31          at 0 range 28 .. 31;
   end record;

   -------------------------------------------------------
   -- DMA stream x number of data register (DMA_SxNDTR) --
   -------------------------------------------------------

   type t_DMA_SxNDTR is record
      NDT : short;
         -- Number of data items to be transferred (0 up to 65535)
      reserved_16_31 : short;
   end record
      with pack, size => 32, volatile_full_access;

   ----------------------------------------------------------
   -- DMA stream x peripheral address register (DMA_SxPAR) --
   ----------------------------------------------------------

   subtype t_DMA_SxPAR is system_address;

   ---------------------------------------------------------
   -- DMA stream x memory 0 address register (DMA_SxM0AR) --
   ---------------------------------------------------------

   subtype t_DMA_SxM0AR is system_address;

   ---------------------------------------------------------
   -- DMA stream x memory 1 address register (DMA_SxM1AR) --
   ---------------------------------------------------------

   subtype t_DMA_SxM1AR is system_address;

   ----------------------------------------------------
   -- DMA stream x FIFO control register (DMA_SxFCR) --
   ----------------------------------------------------

   type t_FIFO_threshold is
     (FIFO_1DIV4_FULL, FIFO_1DIV2_FULL, FIFO_3DIV4_FULL, FIFO_FULL)
      with size => 2;

   for t_FIFO_threshold use
     (FIFO_1DIV4_FULL   => 2#00#,
      FIFO_1DIV2_FULL   => 2#01#,
      FIFO_3DIV4_FULL   => 2#10#,
      FIFO_FULL         => 2#11#);

   type t_FIFO_status is
     (FIFO_LESS_1DIV4,
      FIFO_LESS_1DIV2,
      FIFO_LESS_3DIV4,
      FIFO_LESS_FULL,
      FIFO_IS_EMPTY,
      FIFO_IS_FULL)
      with size => 3;

   for t_FIFO_status use
     (FIFO_LESS_1DIV4   => 2#000#,
      FIFO_LESS_1DIV2   => 2#001#,
      FIFO_LESS_3DIV4   => 2#010#,
      FIFO_LESS_FULL    => 2#011#,
      FIFO_IS_EMPTY     => 2#100#,
      FIFO_IS_FULL      => 2#101#);

   type t_DMA_SxFCR is record
      FTH         : t_FIFO_threshold   := FIFO_1DIV2_FULL; -- FIFO threshold
      DMDIS       : boolean            := false; -- Direct mode disable
      FS          : t_FIFO_status      := FIFO_IS_EMPTY; -- FIFO status
      reserved_6  : bit                := 0;
      FIFO_ERROR  : boolean            := false; -- FIFO error intr. enable (FEIE)
      reserved_8_15  : byte            := 0;
      reserved_16_31 : short           := 0;
   end record
      with pack, size => 32, volatile_full_access;

   --------------------
   -- DMA peripheral --
   --------------------

   type t_stream_registers is record
      CR       : t_DMA_SxCR;     -- Control register
      NDTR     : t_DMA_SxNDTR;   -- Number of data register
      PAR      : t_DMA_SxPAR;    -- Peripheral address register
      M0AR     : t_DMA_SxM0AR;   -- memory 0 address register
      M1AR     : t_DMA_SxM1AR;   -- memory 1 address register
      FCR      : t_DMA_SxFCR;    -- FIFO control register
   end record
      with volatile;

   for t_stream_registers use record
      CR       at 16#00# range 0 .. 31;
      NDTR     at 16#04# range 0 .. 31;
      PAR      at 16#08# range 0 .. 31;
      M0AR     at 16#0C# range 0 .. 31;
      M1AR     at 16#10# range 0 .. 31;
      FCR      at 16#14# range 0 .. 31;
   end record;

   type t_streams_registers is array (t_stream_index) of t_stream_registers
      with pack;

   type t_dma_periph is record
      LISR     : t_DMA_LISR;  -- Interrupt status register (0 .. 3)
      HISR     : t_DMA_HISR;  -- Interrupt status register (4 .. 7)
      LIFCR    : t_DMA_LIFCR; -- Interrupt clear register (0 .. 3)
      HIFCR    : t_DMA_HIFCR; -- Interrupt clear register (4 .. 7)
      streams  : t_streams_registers;
   end record
      with volatile;

   for t_dma_periph use record
      LISR     at 16#00# range 0 .. 31;
      HISR     at 16#04# range 0 .. 31;
      LIFCR    at 16#08# range 0 .. 31;
      HIFCR    at 16#0C# range 0 .. 31;
      streams  at 16#10# range 0 .. (32 * 6 * 8) - 1;
   end record;


   DMA1  : aliased t_dma_periph
      with import, volatile, address => system'to_address (soc.layout.DMA1_BASE);

   DMA2  : aliased t_dma_periph
      with import, volatile, address => system'to_address (soc.layout.DMA2_BASE);


   ---------------
   -- Utilities --
   ---------------

   procedure enable_clocks;

   procedure enable
     (controller  : in out t_dma_periph;
      stream      : in     t_stream_index)
   with inline_always;

   procedure disable
     (controller  : in out t_dma_periph;
      stream      : in     t_stream_index);

   procedure get_dma_stream_from_interrupt
     (intr        : in  soc.interrupts.t_interrupt;
      dma_id      : out t_dma_periph_index;
      stream      : out t_stream_index;
      success     : out boolean);

   function soc_is_dma_irq
      (intr : soc.interrupts.t_interrupt)
      return boolean;

   function get_interrupt_status
     (controller  : t_dma_periph;
      stream      : t_stream_index) return t_dma_stream_int_status
   with volatile_function;

   procedure set_IFCR
     (controller  : in out t_dma_periph;
      stream      : in     t_stream_index;
      IFCR        : in     t_dma_stream_clear_interrupts);

   procedure clear_all_interrupts
     (controller  : in out t_dma_periph;
      stream      : in     t_stream_index);

   procedure reset_stream
     (controller  : in out t_dma_periph;
      stream      : in     t_stream_index);

   procedure reset_streams;

end soc.dma;
