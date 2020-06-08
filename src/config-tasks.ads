
with config.applications;


package config.tasks
  with spark_mode => off
is

   procedure zeroify_bss
     (id : in  config.applications.t_real_task_id)
      with
         global => (input  => (config.applications.list));

   procedure copy_data_to_ram
     (id : in  config.applications.t_real_task_id)
      with
         global => (input  => (config.applications.list));

end config.tasks;
