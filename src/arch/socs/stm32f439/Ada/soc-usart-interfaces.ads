
package soc.usart.interfaces
   with spark_mode => on
is

   procedure configure
     (usart_id : in  unsigned_8;
      baudrate : in  unsigned_32;
      data_len : in  t_data_len;
      parity   : in  t_parity;
      stop     : in  t_stop_bits;
      success  : out boolean);

   procedure transmit
     (usart_id : in  unsigned_8;
      data     : in  t_USART_DR);

end soc.usart.interfaces;
