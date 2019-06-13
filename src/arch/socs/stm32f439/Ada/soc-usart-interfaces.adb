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

package body soc.usart.interfaces
   with spark_mode => off
is

   procedure configure
     (usart_id : in  unsigned_8;
      baudrate : in  unsigned_32;
      data_len : in  t_data_len;
      parity   : in  t_parity;
      stop     : in  t_stop_bits;
      success  : out boolean)
   is
      usart    : t_USART_peripheral_access;
   begin

      case usart_id is
         when 1 => usart := USART1'access;
         when 4 => usart := UART4'access;
         when 6 => usart := USART6'access;
         when others =>
            success := false;
            return;
      end case;

      usart.all.CR1.UE     := true; -- USART enable
      usart.all.CR1.TE     := true; -- Transmitter enable
      usart.all.CR1.RE     := true; -- Receiver enable

      set_baudrate (usart, baudrate);

      usart.all.CR1.M      := data_len;
      usart.all.CR2.STOP   := stop;

      usart.all.CR1.PCE := true;    -- Parity control enable
      usart.all.CR1.PS  := parity;

      -- No flow control
      usart.all.CR3.RTSE := false;
      usart.all.CR3.CTSE := false;

      success := true;
      return;
   end configure;


   procedure transmit
     (usart_id : in  unsigned_8;
      data     : in  t_USART_DR)
   is
   begin
      case usart_id is
         when 1 => soc.usart.transmit (USART1'access, data);
         when 4 => soc.usart.transmit (UART4'access, data);
         when 6 => soc.usart.transmit (USART6'access, data);
         when others =>
            raise program_error;
      end case;
   end transmit;

end soc.usart.interfaces;
