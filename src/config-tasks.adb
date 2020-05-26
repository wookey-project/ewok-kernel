
with interfaces;        use interfaces;
with types;             use types;
with config.memlayout;
with ewok.debug;

package body config.tasks
  with spark_mode => off
is

   package CFGAPP renames config.applications;
   package CFGMEM renames config.memlayout;

   procedure zeroify_bss
     (id : in  config.applications.t_real_task_id)
   is
   begin

      if CFGAPP.list(id).bss_size > 0 then

         declare
            bss_address : constant system_address :=
               CFGMEM.apps_region.ram_memory_addr
               + CFGAPP.list(id).data_offset
               + to_unsigned_32 (CFGAPP.list(id).data_size)
               + to_unsigned_32 (CFGAPP.list(id).stack_size);

            bss_area : byte_array (1 .. to_unsigned_32 (CFGAPP.list(id).bss_size))
                           with address => to_address (bss_address);

         begin
            ewok.debug.log
              (ewok.debug.INFO, "zeroify bss: task " & id'image &
               ", at " & system_address'image (bss_address) &
               ", " & unsigned_16'image (CFGAPP.list(id).bss_size) & " bytes");

            bss_area := (others => 0);
         end;

      end if;

   end zeroify_bss;


   procedure copy_data_to_ram
     (id : in  config.applications.t_real_task_id)
   is
   begin
      if CFGAPP.list(id).data_size > 0 then
         declare
            data_in_flash_address : constant system_address :=
               CFGMEM.apps_region.flash_memory_addr
               + CFGAPP.list(id).text_offset
               + CFGAPP.list(id).text_size
               + CFGAPP.list(id).got_size;

            data_in_flash  : byte_array (1 .. to_unsigned_32 (CFGAPP.list(id).data_size))
                                with address => to_address (data_in_flash_address);

            data_in_ram_address : constant system_address :=
               CFGMEM.apps_region.ram_memory_addr
               + CFGAPP.list(id).data_offset
               + to_unsigned_32 (CFGAPP.list(id).stack_size);

            data_in_ram    : byte_array (1 .. to_unsigned_32 (CFGAPP.list(id).data_size))
                                with address => to_address (data_in_ram_address);
         begin
            ewok.debug.log
              (ewok.debug.INFO, "task " & id'image & ": copy data from " &
               system_address'image (data_in_flash_address) & " to " &
               system_address'image (data_in_ram_address) & ", size " &
               CFGAPP.list(id).data_size'image);

            data_in_ram := data_in_flash;
         end;
      end if;
   end copy_data_to_ram;

end config.tasks;
