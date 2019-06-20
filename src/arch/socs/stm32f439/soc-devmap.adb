with soc.dma; use soc.dma;

package body soc.devmap
   with spark_mode => off
is

   function find_periph
     (addr     : system_address;
      size     : unsigned_32)
      return t_periph_id
   is
   begin
      for id in periphs'range loop
         if periphs(id).addr = addr and periphs(id).size = size then
            return id;
         end if;
      end loop;
      return NO_PERIPH;
   end find_periph;


   function find_dma_periph
     (id       : soc.dma.t_dma_periph_index;
      stream   : soc.dma.t_stream_index)
      return t_periph_id
   is
   begin
      case id is
         when ID_DMA1 =>
            case stream is
               when 0 => return DMA1_STR0;
               when 1 => return DMA1_STR1;
               when 2 => return DMA1_STR2;
               when 3 => return DMA1_STR3;
               when 4 => return DMA1_STR4;
               when 5 => return DMA1_STR5;
               when 6 => return DMA1_STR6;
               when 7 => return DMA1_STR7;
            end case;
         when ID_DMA2 =>
            case stream is
               when 0 => return DMA2_STR0;
               when 1 => return DMA2_STR1;
               when 2 => return DMA2_STR2;
               when 3 => return DMA2_STR3;
               when 4 => return DMA2_STR4;
               when 5 => return DMA2_STR5;
               when 6 => return DMA2_STR6;
               when 7 => return DMA2_STR7;
            end case;
      end case;
   end find_dma_periph;

end soc.devmap;
