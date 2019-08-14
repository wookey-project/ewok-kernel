pragma restrictions (no_secondary_stack);
pragma restrictions (no_elaboration_code);
pragma restrictions (no_finalization);
pragma restrictions (no_exception_handlers);
pragma restrictions (no_recursion);
pragma restrictions (no_wide_characters);

with system;
with ada.unchecked_conversion;
with interfaces;  use interfaces;

package types
   with spark_mode => on
is

   KBYTE  : constant := 2 ** 10;
   MBYTE  : constant := 2 ** 20;
   GBYTE  : constant := 2 ** 30;

   subtype byte  is unsigned_8;
   subtype short is unsigned_16;
   subtype word  is unsigned_32;

   subtype milliseconds is unsigned_64;
   subtype microseconds is unsigned_64;

   subtype system_address is unsigned_32;

   function to_address is new ada.unchecked_conversion
     (system_address, system.address);

   function to_system_address is new ada.unchecked_conversion
     (system.address, system_address);

   function to_word is new ada.unchecked_conversion
     (system.address, word);

   function to_unsigned_32 is new ada.unchecked_conversion
     (system.address, unsigned_32);

   pragma warnings (off);

   function to_unsigned_32 is new ada.unchecked_conversion
     (unsigned_8, unsigned_32);

   function to_unsigned_32 is new ada.unchecked_conversion
     (unsigned_16, unsigned_32);

   pragma warnings (on);

   type byte_array  is array (unsigned_32 range <>) of byte;
   for byte_array'component_size use byte'size;

   type short_array is array (unsigned_32 range <>) of short;
   for short_array'component_size use short'size;

   type word_array  is array (unsigned_32 range <>) of word;
   for word_array'component_size use word'size;

   type unsigned_8_array is new byte_array;
   type unsigned_16_array is new short_array;
   type unsigned_32_array is new word_array;

   nul : constant character := character'First;

   type bit     is mod 2**1  with size => 1;
   type bits_2  is mod 2**2  with size => 2;
   type bits_3  is mod 2**3  with size => 3;
   type bits_4  is mod 2**4  with size => 4;
   type bits_5  is mod 2**5  with size => 5;
   type bits_6  is mod 2**6  with size => 6;
   type bits_7  is mod 2**7  with size => 7;
   --
   type bits_9  is mod 2**9  with size => 9;
   type bits_10 is mod 2**10 with size => 10;
   type bits_11 is mod 2**11 with size => 11;
   type bits_12 is mod 2**12 with size => 12;
   --
   type bits_17 is mod 2**17 with size => 17;
   --
   type bits_24 is mod 2**24 with size => 24;
   --
   type bits_27 is mod 2**27 with size => 27;

   type bool is new boolean with size => 1;
   for bool use (true => 1, false => 0);

   function to_bit
     (u : unsigned_8) return types.bit
      with pre => u <= 1;

   function to_bit
     (u : unsigned_32) return types.bit
      with pre => u <= 1;

end types;
