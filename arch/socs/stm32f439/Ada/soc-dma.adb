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

with soc.interrupts; use soc.interrupts;
with soc.rcc;


package body soc.dma
   with spark_mode => off
is

   procedure enable_clocks
   is
   begin
      soc.rcc.RCC.AHB1ENR.DMA1EN := true;
      soc.rcc.RCC.AHB1ENR.DMA2EN := true;
   end enable_clocks;


   procedure enable
     (controller  : in out t_dma_periph;
      stream      : in  t_stream_index)
   is begin
      controller.streams(stream).CR.EN := true;
   end enable;


   procedure disable
     (controller  : in out t_dma_periph;
      stream      : in  t_stream_index)
   is begin
      controller.streams(stream).CR.EN := false;
   end disable;


   procedure get_dma_stream_from_interrupt
     (intr        : in  soc.interrupts.t_interrupt;
      dma_id      : out t_dma_periph_index;
      stream      : out t_stream_index;
      success     : out boolean)
   is
   begin
      case intr is
         when INT_DMA1_STREAM0 => dma_id := ID_DMA1; stream := 0; success := true;
         when INT_DMA1_STREAM1 => dma_id := ID_DMA1; stream := 1; success := true;
         when INT_DMA1_STREAM2 => dma_id := ID_DMA1; stream := 2; success := true;
         when INT_DMA1_STREAM3 => dma_id := ID_DMA1; stream := 3; success := true;
         when INT_DMA1_STREAM4 => dma_id := ID_DMA1; stream := 4; success := true;
         when INT_DMA1_STREAM5 => dma_id := ID_DMA1; stream := 5; success := true;
         when INT_DMA1_STREAM6 => dma_id := ID_DMA1; stream := 6; success := true;
         when INT_DMA1_STREAM7 => dma_id := ID_DMA1; stream := 7; success := true;
         when INT_DMA2_STREAM0 => dma_id := ID_DMA2; stream := 0; success := true;
         when INT_DMA2_STREAM1 => dma_id := ID_DMA2; stream := 1; success := true;
         when INT_DMA2_STREAM2 => dma_id := ID_DMA2; stream := 2; success := true;
         when INT_DMA2_STREAM3 => dma_id := ID_DMA2; stream := 3; success := true;
         when INT_DMA2_STREAM4 => dma_id := ID_DMA2; stream := 4; success := true;
         when INT_DMA2_STREAM5 => dma_id := ID_DMA2; stream := 5; success := true;
         when INT_DMA2_STREAM6 => dma_id := ID_DMA2; stream := 6; success := true;
         when INT_DMA2_STREAM7 => dma_id := ID_DMA2; stream := 7; success := true;
         when others => success := false;
      end case;
   end get_dma_stream_from_interrupt;


   function soc_is_dma_irq
      (intr : soc.interrupts.t_interrupt)
      return boolean
   is
      dma_id   : soc.dma.t_dma_periph_index;
      stream   : soc.dma.t_stream_index;
      pragma unreferenced (dma_id);
      pragma unreferenced (stream);
      ok       : boolean;
   begin
      soc.dma.get_dma_stream_from_interrupt (intr, dma_id, stream, ok);
      return ok;
   end soc_is_dma_irq;


   function get_interrupt_status
     (controller  : t_dma_periph;
      stream      : t_stream_index) return t_dma_stream_int_status
   is
      status : t_dma_stream_int_status;
   begin
      case stream is
         when 0 => status := controller.LISR.stream_0;
         when 1 => status := controller.LISR.stream_1;
         when 2 => status := controller.LISR.stream_2;
         when 3 => status := controller.LISR.stream_3;
         when 4 => status := controller.HISR.stream_4;
         when 5 => status := controller.HISR.stream_5;
         when 6 => status := controller.HISR.stream_6;
         when 7 => status := controller.HISR.stream_7;
      end case;
      return status;
   end get_interrupt_status;


   procedure set_IFCR
     (controller  : in out t_dma_periph;
      stream      : in     t_stream_index;
      IFCR        : in     t_dma_stream_clear_interrupts)
   is
   begin
      case stream is
         when 0 => controller.LIFCR.stream_0 := IFCR;
         when 1 => controller.LIFCR.stream_1 := IFCR;
         when 2 => controller.LIFCR.stream_2 := IFCR;
         when 3 => controller.LIFCR.stream_3 := IFCR;
         when 4 => controller.HIFCR.stream_4 := IFCR;
         when 5 => controller.HIFCR.stream_5 := IFCR;
         when 6 => controller.HIFCR.stream_6 := IFCR;
         when 7 => controller.HIFCR.stream_7 := IFCR;
      end case;
   end set_IFCR;


   procedure clear_all_interrupts
     (controller  : in out t_dma_periph;
      stream      : in     t_stream_index)
   is
      IFCR : constant t_dma_stream_clear_interrupts := (others => true);
   begin
      set_IFCR (controller, stream, IFCR);
   end clear_all_interrupts;


   procedure reset_stream
     (controller  : in out t_dma_periph;
      stream      : in     t_stream_index)
   is
   begin

      controller.streams(stream).CR.EN := false;

      clear_all_interrupts (controller, stream);

      -- Setting default values to CR register
      controller.streams(stream).CR := (others => <>);

      controller.streams(stream).NDTR.NDT := 0;
      controller.streams(stream).PAR      := 0;
      controller.streams(stream).M0AR     := 0;
      controller.streams(stream).M1AR     := 0;

      -- Setting default values to FCR register
      controller.streams(stream).FCR := (others => <>);

   end reset_stream;


   procedure reset_streams
   is
   begin

      for stream in t_stream_index'range loop
         reset_stream (DMA1, stream);
      end loop;

      for stream in t_stream_index'range loop
         reset_stream (DMA2, stream);
      end loop;

   end reset_streams;

end soc.dma;
