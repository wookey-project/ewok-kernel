
with config.memlayout;
with ewok.debug;

package body ewok.tasks.memory
   with spark_mode => off
is

   package CFGAPP renames config.applications;
   package CFGMEM renames config.memlayout;


   procedure compute_subregions_per_app
   is
      mask : m4.mpu.t_subregion_mask;
   begin

      for id in CFGAPP.list'range loop

         -- Subregion mask in FLASH
         declare
            first_slot : constant m4.mpu.t_subregion
               := config.memlayout.list(id).flash_slot_start;

            last_slot  : constant m4.mpu.t_subregion
               := config.memlayout.list(id).flash_slot_start
                  + config.memlayout.list(id).flash_slot_number
                  - 1;
         begin
            mask := (others => m4.mpu.SUB_REGION_DISABLED);
            mask (first_slot .. last_slot) :=
               (others => m4.mpu.SUB_REGION_ENABLED);
            flash_mask(id) := mask;
         end;

         -- Subregion mask in RAM
         declare
            first_slot : constant m4.mpu.t_subregion
               := config.memlayout.list(id).ram_slot_start;

            last_slot  : constant m4.mpu.t_subregion
               := config.memlayout.list(id).ram_slot_start
                  + config.memlayout.list(id).ram_slot_number
                  - 1;
         begin
            mask := (others => m4.mpu.SUB_REGION_DISABLED);
            mask (first_slot .. last_slot) :=
               (others => m4.mpu.SUB_REGION_ENABLED);
            ram_mask(id) := mask;
         end;

      end loop;

   end compute_subregions_per_app;


   procedure zeroify_bss
     (id    : in  t_real_task_id)
   is
   begin
      if CFGAPP.list(id).bss_size > 0 then
         declare
            bss_region : byte_array (1 .. to_unsigned_32 (CFGAPP.list(id).bss_size))
               with address =>
                  to_address (CFGMEM.apps_region.ram_memory_addr
                              + CFGAPP.list(id).data_off
                              + to_unsigned_32 (CFGAPP.list(id).data_size)
                              + to_unsigned_32 (CFGAPP.list(id).stack_size));
         begin
            debug.log (debug.INFO,
               "task " & id'image &
               ": zeroify bss: from " &
                  system_address'image (to_system_address (bss_region'address)) &
               " with size: " &
                  system_address'image (to_unsigned_32 (CFGAPP.list(id).bss_size)));

            bss_region := (others => 0 );
         end;
      end if;

   end zeroify_bss;


   procedure copy_data_to_ram
     (id    : in  t_real_task_id)
   is
   begin
      if CFGAPP.list(id).data_size > 0 then
         declare
            src : byte_array (1 .. to_unsigned_32 (CFGAPP.list(id).data_size))
               with address =>
                  to_address (CFGMEM.apps_region.flash_memory_addr
                              + CFGAPP.list(id).text_off
                              + CFGAPP.list(id).text_size
                              + CFGAPP.list(id).got_size );

            data_region : byte_array (1 .. to_unsigned_32 (CFGAPP.list(id).data_size))
               with address =>
                  to_address (CFGMEM.apps_region.ram_memory_addr
                              + CFGAPP.list(id).data_off
                              + to_unsigned_32 (CFGAPP.list(id).stack_size));
         begin
            debug.log (debug.INFO,
               "task " & id'image &
               ": copy data from " &
                  system_address'image (to_system_address (src'address)) &
               " to " &
                  system_address'image (to_system_address (data_region'address)) &
               ", size " &
                  CFGAPP.list(id).data_size'image);

            data_region := src;
         end;
      end if;

   end copy_data_to_ram;


end ewok.tasks.memory;
