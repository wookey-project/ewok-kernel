pragma restrictions (no_secondary_stack);
pragma restrictions (no_elaboration_code);
pragma restrictions (no_finalization);
pragma restrictions (no_exception_handlers);

-- These types are not SPARK compliant

package types.unsafe
   with spark_mode => off
is

   type string_access is access all string;

end types.unsafe;
