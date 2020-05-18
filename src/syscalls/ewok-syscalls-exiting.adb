--
-- Copyright 2018 The wookey project team <wookey@ssi.gouv.fr>
--   - Ryad     Benadjila
--   - Arnauld  Michelizza
--   - Mathieu  Renard
--   - Philippe Thierry
--   - Philippe Trebuchet
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
--     Unless required by applicable law or agreed to in writing, software
--     distributed under the License is distributed on an "AS IS" BASIS,
--     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--     See the License for the specific language governing permissions and
--     limitations under the License.
--
--


with ewok.tasks;           use ewok.tasks;
with ewok.devices_shared;  use ewok.devices_shared;
with ewok.dma_shared;      use ewok.dma_shared;
with ewok.devices;
with ewok.dma;
with ewok.debug;

package body ewok.syscalls.exiting
   with spark_mode => off
is

   package TSK renames ewok.tasks;

   procedure svc_exit
     (caller_id   : in  ewok.tasks_shared.t_task_id;
      mode        : in  ewok.tasks_shared.t_task_mode)
   is
   begin

      if mode = TASK_MODE_ISRTHREAD then
#if CONFIG_SCHED_SUPPORT_FISR
         declare
            current_state : constant t_task_state :=
               ewok.tasks.get_state (caller_id, TASK_MODE_MAINTHREAD);
         begin
            if current_state = TASK_STATE_RUNNABLE or
               current_state = TASK_STATE_IDLE
            then
               ewok.tasks.set_state
                  (caller_id, TASK_MODE_MAINTHREAD, TASK_STATE_FORCED);
            end if;
         end;
#end if;
         ewok.tasks.set_state
            (caller_id, TASK_MODE_ISRTHREAD, TASK_STATE_ISR_DONE);

         -- Main thread mode
      else
         -- FIXME: we should also clean resources (devices, DMA, IPCs, ISRs...)
         -- This means:
         --    * unlock task waiting for this task to respond to IPC, returning BUSY
         --    * disabling all registered interrupts (NVIC)
         --    * disabling all EXTIs
         --    * cleaning DMA registered streams & reseting them
         --    * deregistering devices
         --    * deregistering GPIOs
         --    * zeroing data regions
         --  Most of those actions should be handled by each component unregister()
         --  call (or equivalent)
         --  All waiting events of the softirq input queue for this task should also be
         --  cleaned (they also can be cleaned as they are treated by softirqd)
         ewok.tasks.set_state
            (caller_id, TASK_MODE_MAINTHREAD, TASK_STATE_FINISHED);
      end if;

   end svc_exit;


   -- Deallocate registered devices and DMA streams in order
   -- to avoid user ISRs (potentially faulty) triggered by
   -- interrupts.
   -- TODO: the appropriate action should be chosen at compile time
   --       (ie. DO_NOTHING, RESET, FREEZE...)
   procedure svc_panic
     (caller_id   : in  ewok.tasks_shared.t_task_id)
   is
      dev_id   : ewok.devices_shared.t_device_id;
      ok       : boolean;
   begin

      -- Release registered devices
      for dev_descriptor in TSK.tasks_list(caller_id).devices'range loop
         dev_id := TSK.tasks_list(caller_id).devices(dev_descriptor).device_id;
         if dev_id /= ID_DEV_UNUSED then

            -- Unmounting the device
            if TSK.is_mounted (caller_id, dev_descriptor) then
               TSK.unmount_device (caller_id, dev_descriptor, ok);
               if not ok then
                  raise program_error; -- Should never happen
               end if;
            end if;

            -- Removing it from the task's list of used devices
            TSK.remove_device (caller_id, dev_descriptor);

            -- Release GPIOs, EXTIs and interrupts
            ewok.devices.release_device (caller_id, dev_id, ok);
            if not ok then
               raise program_error; -- Should never happen
            end if;
         end if;
      end loop;

      -- Release DMA streams
      for dma_descriptor in TSK.tasks_list(caller_id).dma_id'range loop
         if TSK.tasks_list(caller_id).dma_id(dma_descriptor) /= ID_DMA_UNUSED
         then
            ewok.dma.release_stream
              (caller_id,
               TSK.tasks_list(caller_id).dma_id(dma_descriptor),
               ok);
            if not ok then
               raise program_error; -- Should never happen
            end if;
         end if;
      end loop;

      -- FIXME: maybe we should also clean IPCs ?
      ewok.tasks.set_state
         (caller_id, TASK_MODE_ISRTHREAD, TASK_STATE_ISR_DONE);
      ewok.tasks.set_state
         (caller_id, TASK_MODE_MAINTHREAD, TASK_STATE_FINISHED);

      debug.log (debug.ALERT, ewok.tasks.tasks_list(caller_id).name & " voluntary panic!");
   end svc_panic;


end ewok.syscalls.exiting;
