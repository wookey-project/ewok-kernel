pragma restrictions (no_secondary_stack);
pragma restrictions (no_elaboration_code);
pragma restrictions (no_finalization);
pragma restrictions (no_exception_handlers);

-- these types are not SPARK compliant. They should not be used in SPARK code
package unsafe_types
   with SPARK_Mode => Off -- access types forbidden in SPARK
is

   type string_access is access all string;

end unsafe_types;
