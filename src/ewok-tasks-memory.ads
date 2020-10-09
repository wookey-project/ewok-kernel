
with config.applications; use config.applications;
with m4.mpu;

package ewok.tasks.memory
   with spark_mode => off
is

   -- For each task, the list of its occupied subregions
   flash_mask  : array (t_real_task_id'range) of m4.mpu.t_subregion_mask
      := (others => (others => m4.mpu.SUB_REGION_DISABLED));
   ram_mask    : array (t_real_task_id'range) of m4.mpu.t_subregion_mask
      := (others => (others => m4.mpu.SUB_REGION_DISABLED));

   -- For each task, compute its subregion mask
   procedure compute_subregions_per_app
      with
         global => (input  => (config.applications.list));

   -- Zerofiy BSS section of given task in RAM.
   procedure zeroify_bss
     (id    : in  t_real_task_id)
      with
         global => (input  => (config.applications.list));

   -- Map application data section from storage to RAM
   procedure copy_data_to_ram
     (id    : in  t_real_task_id)
      with
         global => (input  => (config.applications.list));

end ewok.tasks.memory;
