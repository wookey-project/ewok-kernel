
package ewok.tasks.debug
   with spark_mode => off
is
   procedure crashdump
     (frame_a  : in  ewok.t_stack_frame_access);
end ewok.tasks.debug;
