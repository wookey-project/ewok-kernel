
package types.c
   with spark_mode => on
is

   type t_retval is (SUCCESS, FAILURE) with size => 8;
   for t_retval use (SUCCESS  => 0, FAILURE  => 1);

   --
   -- C string
   --

   type c_string is array (positive range <>) of aliased character;
   for c_string'component_size use character'size;

   -- C_string length (without nul character)
   function len (s : c_string) return natural;

   -- String conversion
   procedure to_c
     (dst : out c_string;  src : in string);

   procedure to_ada
     (dst : out string;    src : in c_string);

   --
   -- C buffer
   --

   subtype c_buffer is byte_array;

   --
   -- Boolean
   --

   type bool is new boolean with size => 8;
   for bool use (true => 1, false => 0);

end types.c;
