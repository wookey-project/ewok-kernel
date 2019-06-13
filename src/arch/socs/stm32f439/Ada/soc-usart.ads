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

with system;

package soc.usart
   with spark_mode => off
is

   --------------------------------
   -- Status register (USART_SR) --
   --------------------------------

   type t_USART_SR is record
      PE    : boolean;  -- Parity error
      FE    : boolean;  -- Framing error
      NF    : boolean;  -- Noise detected flag
      ORE   : boolean;  -- Overrun error
      IDLE  : boolean;  -- IDLE line detected
      RXNE  : boolean;  -- Read data register not empty
      TC    : boolean;  -- Transmission complete
      TXE   : boolean;  -- Transmit data register empty
      LBD   : boolean;  -- LIN break detection flag
      CTS   : boolean;  -- CTS flag
   end record
     with volatile_full_access, size => 32;

   for t_USART_SR use record
      PE    at 0 range 0 .. 0;
      FE    at 0 range 1 .. 1;
      NF    at 0 range 2 .. 2;
      ORE   at 0 range 3 .. 3;
      IDLE  at 0 range 4 .. 4;
      RXNE  at 0 range 5 .. 5;
      TC    at 0 range 6 .. 6;
      TXE   at 0 range 7 .. 7;
      LBD   at 0 range 8 .. 8;
      CTS   at 0 range 9 .. 9;
   end record;

   ------------------------------
   -- Data register (USART_DR) --
   ------------------------------

   type t_USART_DR is new bits_9
      with volatile_full_access, size => 32;

   ------------------------------------
   -- Baud rate register (USART_BRR) --
   ------------------------------------

   type t_USART_BRR is record
      DIV_FRACTION   : bits_4;
      DIV_MANTISSA   : bits_12;
   end record
     with volatile_full_access, size => 32;

   for t_USART_BRR use record
      DIV_FRACTION   at 0 range 0 .. 3;
      DIV_MANTISSA   at 0 range 4 .. 15;
   end record;

   ------------------------------------
   -- Control register 1 (USART_CR1) --
   ------------------------------------

   type t_parity is (PARITY_EVEN, PARITY_ODD) with size => 1;
   for t_parity use
     (PARITY_EVEN => 0,
      PARITY_ODD  => 1);

   type t_data_len is (DATA_8BITS, DATA_9BITS) with size => 1;                   
   for t_data_len use
     (DATA_8BITS => 0,
      DATA_9BITS => 1);

   type t_USART_CR1 is record
      SBK            : boolean;     -- Send break
      RWU            : boolean;     -- Receiver wakeup
      RE             : boolean;     -- Receiver enable
      TE             : boolean;     -- Transmitter enable
      IDLEIE         : boolean;     -- IDLE interrupt enable
      RXNEIE         : boolean;     -- RXNE interrupt enable
      TCIE           : boolean;     -- Transmission complete interrupt enable
      TXEIE          : boolean;     -- TXE interrupt enable
      PEIE           : boolean;     -- PE interrupt enable
      PS             : t_parity;    -- Parity selection
      PCE            : boolean;     -- Parity control enable
      WAKE           : boolean;     -- Wakeup method
      M              : t_data_len;  -- Word length
      UE             : boolean;     -- USART enable
      reserved_14_14 : bit;
      OVER8          : boolean;     -- Oversampling mode
   end record
     with volatile_full_access, size => 32;

   for t_USART_CR1 use record
      SBK            at 0 range 0 .. 0;
      RWU            at 0 range 1 .. 1;
      RE             at 0 range 2 .. 2;
      TE             at 0 range 3 .. 3;
      IDLEIE         at 0 range 4 .. 4;
      RXNEIE         at 0 range 5 .. 5;
      TCIE           at 0 range 6 .. 6;
      TXEIE          at 0 range 7 .. 7;
      PEIE           at 0 range 8 .. 8;
      PS             at 0 range 9 .. 9;
      PCE            at 0 range 10 .. 10;
      WAKE           at 0 range 11 .. 11;
      M              at 0 range 12 .. 12;
      UE             at 0 range 13 .. 13;
      Reserved_14_14 at 0 range 14 .. 14;
      OVER8          at 0 range 15 .. 15;
   end record;

   ------------------------------------
   -- Control register 2 (USART_CR2) --
   ------------------------------------

   type t_stop_bits is (STOP_1, STOP_0_dot_5, STOP_2, STOP_1_dot_5)
      with size => 2;
   for t_stop_bits use
     (STOP_1         => 2#00#,
      STOP_0_dot_5   => 2#01#,
      STOP_2         => 2#10#,
      STOP_1_dot_5   => 2#11#);

   type t_USART_CR2 is record
      ADD            : bits_4;   -- Address of the USART node
      reserved_4_4   : bit;
      LBDL           : boolean;  -- lin break detection length
      LBDIE          : boolean;  -- LIN break detection interrupt enable
      reserved_7_7   : bit;
      LBCL           : boolean;  -- Last bit clock pulse
      CPHA           : boolean;  -- Clock phase
      CPOL           : boolean;  -- Clock polarity
      CLKEN          : boolean;  -- Clock enable
      STOP           : t_stop_bits; --  STOP bits
      LINEN          : boolean;  --  LIN mode enable
   end record
     with volatile_full_access, size => 32;

   for t_USART_CR2 use record
      ADD            at 0 range 0 .. 3;
      reserved_4_4   at 0 range 4 .. 4;
      LBDL           at 0 range 5 .. 5;
      LBDIE          at 0 range 6 .. 6;
      reserved_7_7   at 0 range 7 .. 7;
      LBCL           at 0 range 8 .. 8;
      CPHA           at 0 range 9 .. 9;
      CPOL           at 0 range 10 .. 10;
      CLKEN          at 0 range 11 .. 11;
      STOP           at 0 range 12 .. 13;
      LINEN          at 0 range 14 .. 14;
   end record;

   ------------------------------------
   -- Control register 3 (USART_CR3) --
   ------------------------------------

   type t_USART_CR3 is record
      EIE      : boolean; -- Error interrupt enable
      IREN     : boolean; -- IrDA mode enable
      IRLP     : boolean; -- IrDA low-power
      HDSEL    : boolean; -- Half-duplex selection
      NACK     : boolean; -- Smartcard NACK enable
      SCEN     : boolean; -- Smartcard mode enable
      DMAR     : boolean; -- DMA enable receiver
      DMAT     : boolean; -- DMA enable transmitter
      RTSE     : boolean; -- RTS enable
      CTSE     : boolean; -- CTS enable
      CTSIE    : boolean; -- CTS interrupt enable
      ONEBIT   : boolean; -- One sample bit method enable
   end record
     with volatile_full_access, size => 32;

   for t_USART_CR3 use record
      EIE            at 0 range 0 .. 0;
      IREN           at 0 range 1 .. 1;
      IRLP           at 0 range 2 .. 2;
      HDSEL          at 0 range 3 .. 3;
      NACK           at 0 range 4 .. 4;
      SCEN           at 0 range 5 .. 5;
      DMAR           at 0 range 6 .. 6;
      DMAT           at 0 range 7 .. 7;
      RTSE           at 0 range 8 .. 8;
      CTSE           at 0 range 9 .. 9;
      CTSIE          at 0 range 10 .. 10;
      ONEBIT         at 0 range 11 .. 11;
   end record;

   ----------------------------------------------------
   -- Guard time and prescaler register (USART_GTPR) --
   ----------------------------------------------------

   type t_USART_GTPR is record
      PSC   : unsigned_8; -- Prescaler value
      GT    : unsigned_8; -- Guard time value
   end record
     with volatile_full_access, size => 32;

   for t_USART_GTPR use record
      PSC   at 0 range 0 .. 7;
      GT    at 0 range 8 .. 15;
   end record;

   ----------------------
   -- USART peripheral --
   ----------------------

   type t_USART_peripheral is record
      SR    : t_USART_SR;
      DR    : t_USART_DR;
      BRR   : t_USART_BRR;
      CR1   : t_USART_CR1;
      CR2   : t_USART_CR2;
      CR3   : t_USART_CR3;
      GTPR  : t_USART_GTPR;
   end record
      with volatile;

   for t_USART_peripheral use record
      SR    at 16#00# range 0 .. 31;
      DR    at 16#04# range 0 .. 31;
      BRR   at 16#08# range 0 .. 31;
      CR1   at 16#0C# range 0 .. 31;
      CR2   at 16#10# range 0 .. 31;
      CR3   at 16#14# range 0 .. 31;
      GTPR  at 16#18# range 0 .. 31;
   end record;

   type t_USART_peripheral_access is access all t_USART_peripheral;

   USART1   : aliased t_USART_peripheral
      with
         import,
         volatile,
         address => system'to_address(16#4001_1000#);

   USART6   : aliased t_USART_peripheral
      with
         import,
         volatile,
         address => system'to_address(16#4001_1400#);

   UART4   : aliased t_USART_peripheral
      with
         import,
         volatile,
         address => system'to_address(16#4000_4C00#);


   procedure set_baudrate
     (usart    : in  t_USART_peripheral_access;
      baudrate : in  unsigned_32);

   procedure transmit
     (usart : in  t_USART_peripheral_access;
      data  : in  t_USART_DR);

   procedure receive
     (usart : in  t_USART_peripheral_access;
      data  : out t_USART_DR);

end soc.usart;
