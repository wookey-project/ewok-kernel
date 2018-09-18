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

package body soc.dma.interfaces
   with spark_mode => off
is

   procedure enable_stream
     (dma_id  : in  soc.dma.t_dma_periph_index;
      stream  : in  soc.dma.t_stream_index)
   is
   begin
      case dma_id is
         when ID_DMA1 => soc.dma.enable (soc.dma.DMA1, stream);
         when ID_DMA2 => soc.dma.enable (soc.dma.DMA2, stream);
      end case;
   end enable_stream;


   procedure disable_stream
     (dma_id  : in  soc.dma.t_dma_periph_index;
      stream  : in  soc.dma.t_stream_index)
   is
   begin
      case dma_id is
         when ID_DMA1 => soc.dma.disable (soc.dma.DMA1, stream);
         when ID_DMA2 => soc.dma.disable (soc.dma.DMA2, stream);
      end case;
   end disable_stream;


   procedure clear_interrupt
     (dma_id      : in  soc.dma.t_dma_periph_index;
      stream      : in  soc.dma.t_stream_index;
      interrupt   : in  t_dma_interrupts)
   is
      reg : t_dma_stream_clear_interrupts := (others => false);
   begin
      case interrupt is
         when FIFO_ERROR         => reg.CLEAR_FIFO_ERROR        := true;
         when DIRECT_MODE_ERROR  => reg.CLEAR_DIRECT_MODE_ERROR := true;
         when TRANSFER_ERROR     => reg.CLEAR_TRANSFER_ERROR    := true;
         when HALF_COMPLETE      => reg.CLEAR_HALF_TRANSFER     := true;
         when TRANSFER_COMPLETE  => reg.CLEAR_TRANSFER_COMPLETE := true;
      end case;
      case dma_id is
         when ID_DMA1 => set_IFCR (soc.dma.DMA1, stream, reg);
         when ID_DMA2 => set_IFCR (soc.dma.DMA2, stream, reg);
      end case;
   end clear_interrupt;


   procedure clear_all_interrupts
     (dma_id  : in  soc.dma.t_dma_periph_index;
      stream  : in  soc.dma.t_stream_index)
   is
   begin
      case dma_id is
         when ID_DMA1 => soc.dma.clear_all_interrupts (soc.dma.DMA1, stream);
         when ID_DMA2 => soc.dma.clear_all_interrupts (soc.dma.DMA2, stream);
      end case;
   end clear_all_interrupts;


   function get_interrupt_status
     (dma_id  : in  soc.dma.t_dma_periph_index;
      stream  : in  soc.dma.t_stream_index)
      return t_dma_stream_int_status
   is
   begin
      case dma_id is
         when ID_DMA1 =>
            return soc.dma.get_interrupt_status (soc.dma.DMA1, stream);
         when ID_DMA2 =>
            return soc.dma.get_interrupt_status (soc.dma.DMA2, stream);
      end case;
   end get_interrupt_status;


   procedure configure_stream
     (dma_id      : in  soc.dma.t_dma_periph_index;
      stream      : in  soc.dma.t_stream_index;
      user_config : in  t_dma_config) -- FIXME - duplicate ewok.exported
   is
      controller  : t_dma_periph_access;
      size        : unsigned_16; -- Number of data items to transfer
   begin

      case dma_id is
         when ID_DMA1 => controller := soc.dma.DMA1'access;
         when ID_DMA2 => controller := soc.dma.DMA2'access;
      end case;

      controller.streams(stream).CR.EN := false;

      -- Direction
      -- The conversion below is due to the difference of representation
      -- between the field in the CR register and the more abstract
      -- type manipulated by the soc.dma.interfaces sub-package.
      controller.streams(stream).CR.DIR :=
         soc.dma.t_transfer_dir'val
           (t_transfer_dir'pos (user_config.transfer_dir));

      -- Input and output addresses
      case user_config.transfer_dir is
         when PERIPHERAL_TO_MEMORY =>
            controller.streams(stream).PAR   := user_config.in_addr;
            controller.streams(stream).M0AR  := user_config.out_addr;

         when MEMORY_TO_PERIPHERAL =>
            controller.streams(stream).M0AR  := user_config.in_addr;
            controller.streams(stream).PAR   := user_config.out_addr;

         when MEMORY_TO_MEMORY     =>
            controller.streams(stream).PAR   := user_config.in_addr;
            controller.streams(stream).M0AR  := user_config.out_addr;
      end case;

      -- Channel selection
      controller.streams(stream).CR.CHSEL    := user_config.channel;

      -- Burst size (single, 4 beats, 8 beats or 16 beats)
      controller.streams(stream).CR.MBURST   :=
         soc.dma.t_burst_size'val
           (t_burst_size'pos (user_config.mem_burst_size));

      controller.streams(stream).CR.PBURST   :=
         soc.dma.t_burst_size'val
           (t_burst_size'pos (user_config.periph_burst_size));

      -- Current target
      controller.streams(stream).CR.CT       := MEMORY_0;

      -- Double buffer mode
      controller.streams(stream).CR.DBM      := false;

      -- Peripheral incr. size (PSIZE or WORD)
      controller.streams(stream).CR.PINCOS   := INCREMENT_PSIZE;

      -- Memory and peripheral data size (byte, half word or word)
      controller.streams(stream).CR.MSIZE    :=
         soc.dma.t_data_size'val (t_data_size'pos (user_config.data_size));
      controller.streams(stream).CR.PSIZE    :=
         soc.dma.t_data_size'val (t_data_size'pos (user_config.data_size));

      -- Set if address pointer is incremented after each data transfer
      controller.streams(stream).CR.MINC  := user_config.memory_inc;
      controller.streams(stream).CR.PINC  := user_config.periph_inc;

      -- Circular mode is disabled
      controller.streams(stream).CR.CIRC  := false;

      -- DMA or peripheral flow controller
      controller.streams(stream).CR.PFCTRL :=
         soc.dma.t_flow_controller'val
           (t_flow_controller'pos (user_config.flow_controller));

      -- Number of data items to transfer
      if user_config.flow_controller = DMA_FLOW_CONTROLLER then

         -- In direct mode, item size in the DMA bufsize register is
         -- calculated using the data_size unit. In FIFO/circular mode,
         -- the increment is always in bytes.
         if user_config.mode = DIRECT_MODE then
            case user_config.data_size is
               when TRANSFER_BYTE      => size := user_config.bytes;
               when TRANSFER_HALF_WORD => size := user_config.bytes / 2;
               when TRANSFER_WORD      => size := user_config.bytes / 4;
            end case;
         else
            size := user_config.bytes;
         end if;

         controller.streams(stream).NDTR.NDT := size;
      end if;

      -- Priority
      if user_config.transfer_dir = PERIPHERAL_TO_MEMORY then
         -- Memory is the destination
         controller.streams(stream).CR.PL := soc.dma.t_priority_level'val
              (t_priority_level'pos (user_config.out_priority));
      else
         -- Memory is the source
         controller.streams(stream).CR.PL := soc.dma.t_priority_level'val
              (t_priority_level'pos (user_config.in_priority));
      end if;

      -- Enable interrupts
      case user_config.mode is
         when DIRECT_MODE     =>
            controller.streams(stream).FCR.FIFO_ERROR       := false;
            controller.streams(stream).CR.DIRECT_MODE_ERROR := true;
            controller.streams(stream).CR.TRANSFER_ERROR    := true;
            controller.streams(stream).CR.TRANSFER_COMPLETE := true;

         when FIFO_MODE       =>
            controller.streams(stream).FCR.DMDIS            := true; -- Disable direct mode
            controller.streams(stream).FCR.FIFO_ERROR       := true;
            controller.streams(stream).FCR.FTH              := FIFO_FULL;
            controller.streams(stream).CR.TRANSFER_ERROR    := true;
            controller.streams(stream).CR.TRANSFER_COMPLETE := true;

         when CIRCULAR_MODE   =>
            if user_config.transfer_dir = MEMORY_TO_MEMORY then
               raise program_error; -- Not implemented
            end if;
            controller.streams(stream).FCR.DMDIS            := true; -- Disable direct mode
            controller.streams(stream).FCR.FIFO_ERROR       := false;
            controller.streams(stream).CR.CIRC              := true; -- Enable circular mode
            controller.streams(stream).CR.TRANSFER_ERROR    := true;
            controller.streams(stream).CR.TRANSFER_COMPLETE := true;
      end case;

   end configure_stream;


   procedure reconfigure_stream
     (dma_id      : in  soc.dma.t_dma_periph_index;
      stream      : in  soc.dma.t_stream_index;
      user_config : in  t_dma_config; -- FIXME - duplicate ewok.exported
      to_configure: in  t_config_mask)
   is
      controller  : t_dma_periph_access;
      size        : unsigned_16; -- Number of data items to transfer
   begin

      case dma_id is
         when ID_DMA1 => controller := soc.dma.DMA1'access;
         when ID_DMA2 => controller := soc.dma.DMA2'access;
      end case;

      controller.streams(stream).CR.EN := false;

      -- Direction
      controller.streams(stream).CR.DIR :=
         soc.dma.t_transfer_dir'val
           (t_transfer_dir'pos (user_config.transfer_dir));

      -- Input and output addresses
      case user_config.transfer_dir is
         when PERIPHERAL_TO_MEMORY =>
            controller.streams(stream).PAR   := user_config.in_addr;
            controller.streams(stream).M0AR  := user_config.out_addr;

         when MEMORY_TO_PERIPHERAL =>
            controller.streams(stream).M0AR  := user_config.in_addr;
            controller.streams(stream).PAR   := user_config.out_addr;

         when MEMORY_TO_MEMORY     =>
            controller.streams(stream).PAR   := user_config.in_addr;
            controller.streams(stream).M0AR  := user_config.out_addr;
      end case;

      -- Number of data items to transfer
      if user_config.flow_controller = DMA_FLOW_CONTROLLER then
         -- In direct mode, item size in the DMA bufsize register is
         -- calculated using the data_size unit. In FIFO/circular mode,
         -- the increment is always in bytes.
         if user_config.mode = DIRECT_MODE then
            case user_config.data_size is
               when TRANSFER_BYTE      => size := user_config.bytes;
               when TRANSFER_HALF_WORD => size := user_config.bytes / 2;
               when TRANSFER_WORD      => size := user_config.bytes / 4;
            end case;
         else
            size := user_config.bytes;
         end if;

         controller.streams(stream).NDTR.NDT := size;
      end if;

      -- Priority
      if to_configure.priority then
         if user_config.transfer_dir = PERIPHERAL_TO_MEMORY then
            -- Memory is the destination
            controller.streams(stream).CR.PL := soc.dma.t_priority_level'val
              (t_priority_level'pos (user_config.out_priority));
         else
            -- Memory is the source
            controller.streams(stream).CR.PL := soc.dma.t_priority_level'val
              (t_priority_level'pos (user_config.in_priority));
         end if;
      end if;

      -- Enable interrupts
      if to_configure.mode then
         case user_config.mode is
            when DIRECT_MODE     =>
               controller.streams(stream).FCR.FIFO_ERROR       := false;
               controller.streams(stream).CR.DIRECT_MODE_ERROR := true;
               controller.streams(stream).CR.TRANSFER_ERROR    := true;
               controller.streams(stream).CR.TRANSFER_COMPLETE := true;

            when FIFO_MODE       =>
               controller.streams(stream).FCR.DMDIS            := true; -- Disable direct mode

               controller.streams(stream).FCR.FIFO_ERROR       := true;
               controller.streams(stream).FCR.FTH              := FIFO_FULL;
               controller.streams(stream).CR.TRANSFER_ERROR    := true;
               controller.streams(stream).CR.TRANSFER_COMPLETE := true;

            when CIRCULAR_MODE   =>
               if user_config.transfer_dir = MEMORY_TO_MEMORY then
                  raise program_error; -- Not implemented
               end if;
               controller.streams(stream).FCR.DMDIS            := true; -- Disable direct mode
               controller.streams(stream).FCR.FIFO_ERROR       := false;
               controller.streams(stream).CR.CIRC              := true; -- Enable circular mode
               controller.streams(stream).CR.TRANSFER_ERROR    := true;
               controller.streams(stream).CR.TRANSFER_COMPLETE := true;

         end case;
      end if;

   end reconfigure_stream;


   procedure reset_stream
     (dma_id      : in  soc.dma.t_dma_periph_index;
      stream      : in  soc.dma.t_stream_index)
   is
   begin
      case dma_id is
         when ID_DMA1 =>
            soc.dma.reset_stream (soc.dma.DMA1, stream);
         when ID_DMA2 =>
            soc.dma.reset_stream (soc.dma.DMA2, stream);
      end case;
   end reset_stream;


end soc.dma.interfaces;
