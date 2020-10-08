
with config.memlayout;
with ewok.debug;

package body ewok.tasks.init
   with spark_mode => off
is

   procedure zeroify_bss
     (id    : in  t_real_task_id)
   is
   begin
      if config.applications.list(id).bss_size > 0 then
         declare
            -- Important info:
            -- Here we add 4, because there is a Ldscript variable between .data and .bss region
            -- As a consequence, .bss start 4 bytes later.
            -- As a conservative measure, this variable, as a ldscript variable (accessed only
            -- for its address) is also set to 0.
            bss_region : byte_array (1 .. to_unsigned_32 (config.applications.list(id).bss_size))
                                with address =>
                                  to_address (
                                     config.memlayout.apps_region.ram_memory_addr
                                     + config.applications.list(id).data_off
                                     + to_unsigned_32 (config.applications.list(id).data_size)
                                     + to_unsigned_32 (config.applications.list(id).stack_size));
         begin
            debug.log(debug.INFO, "task " & id'image & ": zeroify bss: from " &
                      system_address'image (to_system_address(bss_region'address)) & " with size: " &
                      system_address'image (to_unsigned_32(config.applications.list(id).bss_size)));

            bss_region := (others => 0 );
         end;
      end if;

   end zeroify_bss;


   procedure copy_data_to_ram
     (id    : in  t_real_task_id)
   is
   begin
      if config.applications.list(id).data_size > 0 then
         declare
            src         : byte_array (1 .. to_unsigned_32 (config.applications.list(id).data_size))
                              with address =>
                                 to_address (config.memlayout.apps_region.flash_memory_addr
                                             + config.applications.list(id).text_off
                                             + config.applications.list(id).text_size
                                             + config.applications.list(id).got_size );

            data_region : byte_array (1 .. to_unsigned_32 (config.applications.list(id).data_size))
                              with address =>
                                 to_address (config.memlayout.apps_region.ram_memory_addr
                                             + config.applications.list(id).data_off
                                             + to_unsigned_32 (config.applications.list(id).stack_size));
         begin
            debug.log(debug.INFO, "task " & id'image & ": copy data from " &
                      system_address'image (to_system_address(src'address)) & " to " &
                      system_address'image (to_system_address(data_region'address)) & ", size " &
                      config.applications.list(id).data_size'image);

            data_region := src;
         end;
      end if;

   end copy_data_to_ram;


end ewok.tasks.init;
