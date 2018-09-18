
package body types
   with SPARK_Mode => Off
is

   function to_bit
     (u : unsigned_8) return types.bit
   is
      pragma warnings (off);
      function conv is new ada.unchecked_conversion
        (unsigned_8, bit);
      pragma warnings (on);
   begin
      if u > 1 then
         raise program_error;
      end if;
      return conv (u);
   end to_bit;


   function to_bit
     (u : unsigned_32) return types.bit
   is
      pragma warnings (off);
      function conv is new ada.unchecked_conversion
        (unsigned_32, bit);
      pragma warnings (on);
   begin
      if u > 1 then
         raise program_error;
      end if;
      return conv (u);
   end to_bit;

end types;
