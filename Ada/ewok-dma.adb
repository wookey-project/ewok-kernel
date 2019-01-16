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

with ewok.exported.dma; use ewok.exported.dma;
with ewok.sanitize;
with ewok.tasks;
with ewok.interrupts;
with ewok.devices_shared;

#if CONFIG_KERNEL_DOMAIN
with ewok.perm;
#end if;

with soc.dma;              use soc.dma;
with soc.dma.interfaces;   use soc.dma.interfaces;
with soc.nvic;
with c.socinfo;   use type c.socinfo.t_device_soc_infos_access;
with debug;

package body ewok.dma
   with spark_mode => off
is


   procedure get_registered_dma_entry
     (index    : out ewok.dma_shared.t_registered_dma_index;
      success  : out boolean)
   is
   begin
      for id in registered_dma'range loop
         if registered_dma(id).status = DMA_UNUSED then
            registered_dma(id).status := DMA_USED;
            index    := id;
            success  := true;
            return;
         end if;
      end loop;
      success := false;
   end get_registered_dma_entry;


   function has_same_dma_channel
     (index       : ewok.dma_shared.t_registered_dma_index;
      user_config : ewok.exported.dma.t_dma_user_config)
      return boolean
   is
   begin
      if registered_dma(index).config.dma_id    =
            soc.dma.t_dma_periph_index (user_config.controller)
         and
         registered_dma(index).config.stream    =
            soc.dma.t_stream_index (user_config.stream)
         and
         registered_dma(index).config.channel   =
            soc.dma.t_channel_index (user_config.channel)
      then
         return true;
      else
         return false;
      end if;
   end has_same_dma_channel;


   function stream_is_already_used
     (user_config : ewok.exported.dma.t_dma_user_config)
      return boolean
   is
   begin
      for index in registered_dma'range loop
         if registered_dma(index).status /= DMA_UNUSED then
            if registered_dma(index).config.dma_id =
                  soc.dma.t_dma_periph_index (user_config.controller)
               and
               registered_dma(index).config.stream =
                  soc.dma.t_stream_index (user_config.stream)
            then
               return true;
            end if;
         end if;
      end loop;
      return false;
   end stream_is_already_used;


   function task_owns_dma_stream
     (caller_id   : ewok.tasks_shared.t_task_id;
      dma_id      : ewok.exported.dma.t_controller;
      stream_id   : ewok.exported.dma.t_stream)
      return boolean
   is
   begin
      for index in registered_dma'range loop
         if registered_dma(index).task_id = caller_id
            and then
            registered_dma(index).config.dma_id =
               soc.dma.t_dma_periph_index (dma_id)
            and then
            registered_dma(index).config.stream =
               soc.dma.t_stream_index (stream_id)
         then
            return true;
         end if;
      end loop;
      return false;
   end task_owns_dma_stream;


   procedure enable_dma_stream
     (index : in ewok.dma_shared.t_registered_dma_index)
   is
   begin
      if registered_dma(index).status = DMA_CONFIGURED then
         soc.dma.interfaces.enable_stream
           (registered_dma(index).config.dma_id,
            registered_dma(index).config.stream);
      end if;
   end enable_dma_stream;


   procedure disable_dma_stream
     (index : in ewok.dma_shared.t_registered_dma_index)
   is
   begin
      if registered_dma(index).status = DMA_CONFIGURED then
         soc.dma.interfaces.disable_stream
           (registered_dma(index).config.dma_id,
            registered_dma(index).config.stream);
      end if;
   end disable_dma_stream;


   procedure enable_dma_irq
     (index : in ewok.dma_shared.t_registered_dma_index)
   is
      -- DMAs have only one IRQ line per stream
      intr  : constant soc.interrupts.t_interrupt :=
         registered_dma(index).devinfo.all.interrupt_list
           (c.socinfo.t_dev_interrupt_range'first);
   begin
      soc.nvic.enable_irq (soc.nvic.to_irq_number (intr));
   end enable_dma_irq;


   function is_config_complete
     (config : soc.dma.interfaces.t_dma_config)
      return boolean
   is
   begin
      if config.in_addr  = 0 or
         config.out_addr = 0 or
         config.bytes    = 0 or
         config.transfer_dir  = MEMORY_TO_MEMORY or
         (config.transfer_dir = MEMORY_TO_PERIPHERAL and config.in_handler = 0)
         or
         (config.transfer_dir = PERIPHERAL_TO_MEMORY and config.out_handler = 0)
      then
         return false;
      else
         return true;
      end if;
   end is_config_complete;


   function sanitize_dma
     (user_config    : ewok.exported.dma.t_dma_user_config;
      caller_id      : ewok.tasks_shared.t_task_id;
      to_configure   : ewok.exported.dma.t_config_mask;
      mode           : ewok.tasks_shared.t_task_mode)
      return boolean
   is
   begin

      case user_config.transfer_dir is
         when PERIPHERAL_TO_MEMORY  =>

            if to_configure.buffer_in then
               if not ewok.sanitize.is_word_in_allocated_device
                          (user_config.in_addr, caller_id)
               then
                  return false;
               end if;
            end if;

            if to_configure.buffer_out then
               if not ewok.sanitize.is_range_in_any_slot
                       (user_config.out_addr, unsigned_32 (user_config.size),
                        caller_id, mode)
                  and
                  not ewok.sanitize.is_range_in_dma_shm
                       (user_config.out_addr, unsigned_32 (user_config.size),
                        SHM_ACCESS_WRITE, caller_id)
               then
                  return false;
               end if;
            end if;

            if to_configure.handlers then
               if not ewok.sanitize.is_word_in_txt_slot
                          (user_config.out_handler, caller_id)
               then
                  return false;
               end if;
            end if;

         when MEMORY_TO_PERIPHERAL  =>

            if to_configure.buffer_in then
               if not ewok.sanitize.is_range_in_any_slot
                       (user_config.in_addr, unsigned_32 (user_config.size),
                        caller_id, mode)
                  and
                  not ewok.sanitize.is_range_in_dma_shm
                       (user_config.in_addr, unsigned_32 (user_config.size),
                        SHM_ACCESS_READ, caller_id)
               then
                  return false;
               end if;
            end if;

            if to_configure.buffer_out then
               if not ewok.sanitize.is_word_in_allocated_device
                          (user_config.out_addr, caller_id)
               then
                  return false;
               end if;
            end if;

            if to_configure.handlers then
               if not ewok.sanitize.is_word_in_txt_slot
                          (user_config.in_handler, caller_id)
               then
                  return false;
               end if;
            end if;

         when MEMORY_TO_MEMORY      =>
            return false;
      end case;

      return true;

   end sanitize_dma;


   function sanitize_dma_shm
     (shm            : ewok.exported.dma.t_dma_shm_info;
      caller_id      : ewok.tasks_shared.t_task_id;
      mode           : ewok.tasks_shared.t_task_mode)
      return boolean
   is
   begin

      if not ewok.tasks.is_real_user (shm.granted_id) then
         debug.log (debug.ERROR, "ewok.dma.sanitize_dma_shm(): wrong target");
         return false;
      end if;

      if shm.accessed_id /= caller_id then
         debug.log (debug.ERROR, "ewok.dma.sanitize_dma_shm(): wrong caller");
         return false;
      end if;

#if CONFIG_KERNEL_DOMAIN
      if not ewok.perm.is_same_domain (shm.granted_id, shm.accessed_id) then
         debug.log (debug.ERROR, "ewok.dma.sanitize_dma_shm(): not same domain");
         return false;
      end if;
#end if;

      if not ewok.sanitize.is_range_in_data_slot
              (shm.base, shm.size, caller_id, mode) and
         not ewok.sanitize.is_range_in_devices_slot
              (shm.base, shm.size, caller_id)
      then
         debug.log (debug.ERROR, "ewok.dma.sanitize_dma_shm(): shm not in range");
         return false;
      end if;

      return true;

   end sanitize_dma_shm;


   procedure reconfigure_stream
     (user_config    : in out ewok.exported.dma.t_dma_user_config;
      index          : in     ewok.dma_shared.t_registered_dma_index;
      to_configure   : in     ewok.exported.dma.t_config_mask;
      caller_id      : in     ewok.tasks_shared.t_task_id;
      success        : out    boolean)
   is
      ok             : boolean;
   begin

      if not to_configure.buffer_size then
         user_config.size := registered_dma(index).config.bytes;
      else
         registered_dma(index).config.bytes := user_config.size;
      end if;

      if to_configure.buffer_in then
         registered_dma(index).config.in_addr := user_config.in_addr;
      end if;

      if to_configure.buffer_out then
         registered_dma(index).config.out_addr := user_config.out_addr;
      end if;

      if to_configure.mode then
         registered_dma(index).config.mode := user_config.mode;
      end if;

      if to_configure.priority then
         case user_config.transfer_dir is
            when PERIPHERAL_TO_MEMORY  =>
               registered_dma(index).config.out_priority :=
                  user_config.out_priority;

            when MEMORY_TO_PERIPHERAL  =>
               registered_dma(index).config.in_priority :=
                  user_config.in_priority;

            when MEMORY_TO_MEMORY      =>
               debug.log
                 (debug.ERROR,
                  "ewok.dma.reconfigure_stream(): MEMORY_TO_MEMORY not implemented");
               success := false;
               return;
         end case;
      end if;

      if to_configure.direction then
         registered_dma(index).config.transfer_dir := user_config.transfer_dir;
      end if;

      if to_configure.handlers then
         case user_config.transfer_dir is
            when PERIPHERAL_TO_MEMORY  =>
               registered_dma(index).config.out_handler :=
                  user_config.out_handler;

               ewok.interrupts.set_interrupt_handler
                 (registered_dma(index).devinfo.all.interrupt_list(c.socinfo.t_dev_interrupt_range'first),
                  ewok.interrupts.to_handler_access (user_config.out_handler),
                  caller_id,
                  ewok.devices_shared.ID_DEV_UNUSED,
                  ok);

               if not ok then
                  raise program_error;
               end if;

            when MEMORY_TO_PERIPHERAL  =>
               registered_dma(index).config.in_handler :=
                  user_config.in_handler;

               ewok.interrupts.set_interrupt_handler
                 (registered_dma(index).devinfo.all.interrupt_list(c.socinfo.t_dev_interrupt_range'first),
                  ewok.interrupts.to_handler_access (user_config.in_handler),
                  caller_id,
                  ewok.devices_shared.ID_DEV_UNUSED,
                  ok);

               if not ok then
                  raise program_error;
               end if;

            when MEMORY_TO_MEMORY      =>
               debug.log (debug.ERROR, "ewok.dma.reconfigure_stream(): MEMORY_TO_MEMORY not implemented");
               success := false;
               return;
         end case;
      end if;

      --
      -- Configuring the DMA
      --

      soc.dma.interfaces.reconfigure_stream
        (registered_dma(index).config.dma_id,
         registered_dma(index).config.stream,
         registered_dma(index).config,
         soc.dma.interfaces.t_config_mask (to_configure));

      if is_config_complete (registered_dma(index).config) then
         registered_dma(index).status := DMA_CONFIGURED;
         soc.dma.interfaces.enable_stream
           (registered_dma(index).config.dma_id,
            registered_dma(index).config.stream);
      else
         registered_dma(index).status := DMA_USED;
      end if;

      success := true;

   end reconfigure_stream;


   procedure init_stream
     (user_config    : in     ewok.exported.dma.t_dma_user_config;
      caller_id      : in     ewok.tasks_shared.t_task_id;
      index          : out    ewok.dma_shared.t_registered_dma_index;
      success        : out    boolean)
   is
      ok : boolean;
   begin

      -- Find a free entry in the registered_dma array
      get_registered_dma_entry (index, ok);
      if not ok then
         debug.log ("ewok.dma.init(): no DMA entry available");
         success := false;
         return;
      end if;

      -- Copy the user configuration
      registered_dma(index).config     :=
        (dma_id            => soc.dma.t_dma_periph_index (user_config.controller),
         stream            => soc.dma.t_stream_index (user_config.stream),
         channel           => soc.dma.t_channel_index (user_config.channel),
         bytes             => user_config.size,
         in_addr           => user_config.in_addr,
         in_priority       => user_config.in_priority,
         in_handler        => user_config.in_handler,
         out_addr          => user_config.out_addr,
         out_priority      => user_config.out_priority,
         out_handler       => user_config.out_handler,
         flow_controller   => user_config.flow_controller,
         transfer_dir      => user_config.transfer_dir,
         mode              => user_config.mode,
         data_size         => user_config.data_size,
         memory_inc        => boolean (user_config.memory_inc),
         periph_inc        => boolean (user_config.periph_inc),
         mem_burst_size    => user_config.mem_burst_size,
         periph_burst_size => user_config.periph_burst_size);

      registered_dma(index).task_id    := caller_id;
      registered_dma(index).devinfo    :=
         c.socinfo.soc_devmap_find_dma_device
           (user_config.controller, user_config.stream);

      if registered_dma(index).devinfo = NULL then
         debug.log ("ewok.dma.init(): unknown DMA device");
         success := false;
         return;
      end if;

      -- Set up the interrupt handler
      case user_config.transfer_dir is
         when PERIPHERAL_TO_MEMORY  =>
            if user_config.out_handler /= 0 then
               ewok.interrupts.set_interrupt_handler
                 (registered_dma(index).devinfo.all.interrupt_list(c.socinfo.t_dev_interrupt_range'first),
                  ewok.interrupts.to_handler_access (user_config.out_handler),
                  caller_id,
                  ewok.devices_shared.ID_DEV_UNUSED,
                  ok);

                  if not ok then
                     raise program_error;
                  end if;
            end if;

         when MEMORY_TO_PERIPHERAL  =>
            if user_config.in_handler /= 0 then
               ewok.interrupts.set_interrupt_handler
                 (registered_dma(index).devinfo.all.interrupt_list(c.socinfo.t_dev_interrupt_range'first),
                  ewok.interrupts.to_handler_access (user_config.in_handler),
                  caller_id,
                  ewok.devices_shared.ID_DEV_UNUSED,
                  ok);

                  if not ok then
                     raise program_error;
                  end if;
            end if;

         when MEMORY_TO_MEMORY      =>
            debug.log ("ewok.dma.init(): MEMORY_TO_MEMORY not implemented");
            success := false;
            return;
      end case;

      if is_config_complete (registered_dma(index).config) then
         registered_dma(index).status := DMA_CONFIGURED;
      else
         registered_dma(index).status := DMA_USED;
      end if;

      -- Reset the DMA stream
      soc.dma.interfaces.reset_stream
        (registered_dma(index).config.dma_id,
         registered_dma(index).config.stream);

      -- Configure the DMA stream
      soc.dma.interfaces.configure_stream
        (registered_dma(index).config.dma_id,
         registered_dma(index).config.stream,
         registered_dma(index).config);

      success := true;

   end init_stream;


   procedure init
   is
   begin
      soc.dma.enable_clocks;
   end init;


   procedure clear_dma_interrupts
     (caller_id : in  ewok.tasks_shared.t_task_id;
      interrupt : in  soc.interrupts.t_interrupt)
   is
      soc_dma_id     : soc.dma.t_dma_periph_index;
      soc_stream_id  : soc.dma.t_stream_index;
      ok : boolean;
   begin

      soc.dma.get_dma_stream_from_interrupt
        (interrupt, soc_dma_id, soc_stream_id, ok);

      if not ok then
         raise program_error;
      end if;

      if not task_owns_dma_stream (caller_id, t_controller (soc_dma_id),
                                   t_stream (soc_stream_id))
      then
         raise program_error;
      end if;

      soc.dma.interfaces.clear_all_interrupts
        (soc_dma_id, soc_stream_id);

   end clear_dma_interrupts;


   procedure get_status_register
     (caller_id : in  ewok.tasks_shared.t_task_id;
      interrupt : in  soc.interrupts.t_interrupt;
      status    : out soc.dma.t_dma_stream_int_status;
      success   : out boolean)
   is
      soc_dma_id     : soc.dma.t_dma_periph_index;
      soc_stream_id  : soc.dma.t_stream_index;
      ok       : boolean;
   begin

      soc.dma.get_dma_stream_from_interrupt
        (interrupt, soc_dma_id, soc_stream_id, ok);

      if not ok then
         success := false;
         return;
      end if;

      if not task_owns_dma_stream (caller_id,
                                  t_controller (soc_dma_id),
                                  t_stream (soc_stream_id))
      then
         success := false;
         return;
      end if;

      status := soc.dma.interfaces.get_interrupt_status
        (soc_dma_id, soc_stream_id);

      soc.dma.interfaces.clear_all_interrupts (soc_dma_id, soc_stream_id);

      success := true;

   end get_status_register;


end ewok.dma;
