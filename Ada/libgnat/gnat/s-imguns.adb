with System.Unsigned_Types; use System.Unsigned_Types;

package body System.Img_Uns is

   --------------------
   -- Image_Unsigned --
   --------------------

   procedure Image_Unsigned
     (V : System.Unsigned_Types.Unsigned;
      S : in out String;
      P : out Natural)
   is
      pragma Assert (S'First = 1);
   begin
      P := 0;
      Set_Image_Unsigned (V, S, P);
   end Image_Unsigned;

   ------------------------
   -- Set_Image_Unsigned --
   ------------------------

   Hex : constant array (System.Unsigned_Types.Unsigned range 0 .. 15)
         of Character := "0123456789ABCDEF";

   procedure Set_Image_Unsigned
     (V : System.Unsigned_Types.Unsigned;
      S : in out String;
      P : in out Natural)
   is
   begin
      if V >= 16 then
         Set_Image_Unsigned (V / 16, S, P);
         P := P + 1;
         S (P) := Hex (V rem 16);
      else
         P := P + 1;
         S (P) := Hex (V);
      end if;
   end Set_Image_Unsigned;

end System.Img_Uns;
