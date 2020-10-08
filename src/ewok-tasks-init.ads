
with config.applications; use config.applications;

package ewok.tasks.init
   with spark_mode => off
is

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

end ewok.tasks.init;
