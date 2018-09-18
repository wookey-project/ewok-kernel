
package body types.c
   with SPARK_Mode => Off
is

   function len (s : c_string) return natural
   is
      len : natural := 0;
   begin
      for i in s'range loop
         exit when s(i) = nul;
         len := len + 1;
      end loop;
      return len;
   end len;


   procedure to_ada
     (dst : out string;
      src : in  c_string)
   is
   begin
      for i in src'range loop
         exit when src(i) = nul;
         dst(i) := src(i);
      end loop;
   end to_ada;


   procedure to_c
     (dst : out c_string;
      src : in  string)
   is
      len : natural := 0;
   begin
      for i in src'range loop
         dst(i) := src(i);
         len    := len + 1;
      end loop;
      dst(len)  := nul;
   end to_c;


end types.c;
