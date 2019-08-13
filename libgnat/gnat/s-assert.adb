package body System.Assertions is

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

   --------------------------
   -- Raise_Assert_Failure --
   --------------------------

   procedure Raise_Assert_Failure (Msg : String) is
   begin
      Ewok_Debug_Alert (Msg);
      Ewok_Debug_Newline;
      loop
         null;
      end loop;
   end Raise_Assert_Failure;

end System.Assertions;
