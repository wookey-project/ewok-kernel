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

with soc.rcc;
with soc.rcc.default;

package body soc.usart
   with spark_mode => off
is

   procedure set_baudrate
     (usart    : in  t_USART_peripheral_access;
      baudrate : in  unsigned_32)
   is
      APB_clock   : unsigned_32;
      mantissa    : unsigned_32;
      fraction    : unsigned_32;
   begin
      -- Configuring the baud rate is a tricky part. See RM0090 p. 982-983
      -- for further informations
      if usart = USART1'access or
         usart = USART6'access
      then
         APB_clock   := soc.rcc.default.CLOCK_APB2;
      else
         APB_clock   := soc.rcc.default.CLOCK_APB1;
      end if;

      mantissa    := APB_clock / (16 * baudrate);
      fraction    := ((APB_clock * 25) / (4 * baudrate)) - mantissa * 100;
      fraction    := (fraction * 16) / 100;

      usart.all.BRR.DIV_MANTISSA   := bits_12 (mantissa);
      usart.all.BRR.DIV_FRACTION   := bits_4  (fraction);
   end set_baudrate;


   procedure transmit
     (usart : in  t_USART_peripheral_access;
      data  : in  t_USART_DR)
   is
   begin
      loop
         exit when usart.all.SR.TXE;
      end loop;
      usart.all.DR := data;
   end transmit;


   procedure receive
     (usart : in  t_USART_peripheral_access;
      data  : out t_USART_DR)
   is
   begin
      loop
         exit when usart.all.SR.RXNE;
      end loop;
      data := usart.all.DR;
   end receive;


end soc.usart;
