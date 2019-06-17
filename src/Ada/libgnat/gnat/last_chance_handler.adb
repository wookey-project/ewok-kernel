with Ada.Unchecked_Conversion;

package body Last_Chance_Handler is

   procedure Ewok_Debug_Alert (S : String)
   with
      Convention     => Ada,
      Import         => True,
      External_name  => "ewok_debug_alert";

   procedure Ewok_Debug_Newline
   with
      Convention     => Ada,
      Import         => True,
      External_name  => "ewok_debug_newline";

   -------------------------
   -- Last_chance_handler --
   -------------------------

   procedure Last_Chance_Handler (File : System.Address; Line : Integer)
   is

      type c_string_ptr is access all String (Positive)
         with Storage_Size => 0, Size => Standard'Address_Size;

      function to_c_string_ptr is new Ada.Unchecked_Conversion
        (System.Address, c_string_ptr);

      N : Integer := 0;

   begin

      loop
         exit when to_c_string_ptr (File)(N + 1) = ASCII.NUL;
         N := N + 1;
      end loop;

      declare
         msg : constant String :=
           to_c_string_ptr (File)(1 .. N) & ":" & Integer'Image (Line);
      begin
         Ewok_Debug_Alert (msg);
         Ewok_Debug_Newline;
      end;

      loop
         null;
      end loop;

   end Last_Chance_Handler;

end Last_Chance_Handler;
