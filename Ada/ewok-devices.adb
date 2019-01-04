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

with ewok.perm;                  use ewok.perm;
with ewok.exported.devices;      use ewok.exported.devices;
with ewok.exported.interrupts;   use ewok.exported.interrupts;
with ewok.exported.gpios;        use ewok.exported.gpios;
with ewok.interrupts;            use ewok.interrupts;
with ewok.sanitize;
with ewok.gpio;
with ewok.exti;
with ewok.mpu;
with soc.nvic;
with soc.gpio;
with soc.interrupts;             use soc.interrupts;
with c.socinfo; use type c.socinfo.t_device_soc_infos_access; use type c.socinfo.t_dev_interrupt_range;
with types.c;
with debug;

package body ewok.devices
   with spark_mode => off
is

   procedure init
   is begin
      for i in registered_device'range loop
         registered_device(i).status    := DEV_STATE_UNUSED;
         registered_device(i).task_id   := ID_UNUSED;
         registered_device(i).devinfo   := NULL;
         -- FIXME initialize registered_device(i).udev with 0 values
      end loop;
   end init;


   function get_task_from_id (dev_id : t_device_id)
      return t_task_id
   is
   begin
      return registered_device(dev_id).task_id;
   end get_task_from_id;


   function get_user_device (dev_id : t_device_id)
      return ewok.exported.devices.t_user_device_access
   is
   begin
      return registered_device(dev_id).udev'access;
   end get_user_device;


   function get_user_device_size (dev_id : t_device_id)
      return unsigned_32
   is
   begin
      return registered_device(dev_id).udev.size;
   end get_user_device_size;


   function get_user_device_addr (dev_id : t_device_id)
      return system_address
   is
   begin
      return registered_device(dev_id).udev.base_addr;
   end get_user_device_addr;


   function is_user_device_region_ro (dev_id : t_device_id)
      return boolean
   is
   begin
      return boolean (registered_device(dev_id).devinfo.all.ro);
   end is_user_device_region_ro;


   function get_user_device_subregions_mask (dev_id : t_device_id)
      return unsigned_8
   is
   begin
      return registered_device(dev_id).devinfo.all.subregions;
   end get_user_device_subregions_mask;


   function get_interrupt_config_from_interrupt
     (interrupt : soc.interrupts.t_interrupt)
      return ewok.exported.interrupts.t_interrupt_config_access
   is
      dev_id : t_device_id;
   begin

      -- Retrieving the dev_id from the interrupt
      dev_id := ewok.interrupts.get_device_from_interrupt (interrupt);
      if dev_id = ID_DEV_UNUSED then
         return NULL;
      end if;

      -- Looking at each interrupts configured for this device
      -- to retrieve the proper interrupt configuration informations
      for i in 1 .. registered_device(dev_id).udev.interrupt_num loop
         if registered_device(dev_id).udev.interrupts(i).interrupt = interrupt
         then
            return registered_device(dev_id).udev.interrupts(i)'access;
         end if;
      end loop;
      return NULL;
   end get_interrupt_config_from_interrupt;

   ------------------------
   -- Device registering --
   ------------------------

   procedure get_registered_device_entry
     (dev_id   : out t_device_id;
      success  : out boolean)
   is
   begin
      for id in registered_device'range loop
         if registered_device(id).status = DEV_STATE_UNUSED then
            registered_device(id).status := DEV_STATE_RESERVED;
            dev_id  := id;
            success := true;
            return;
         end if;
      end loop;
      dev_id  := ID_DEV_UNUSED;
      success := false;
   end get_registered_device_entry;


   procedure release_registered_device_entry (dev_id : t_device_id)
   is begin
      registered_device(dev_id).status    := DEV_STATE_UNUSED;
      registered_device(dev_id).task_id   := ID_UNUSED;
      registered_device(dev_id).devinfo   := NULL;
      -- FIXME initialize registered_device(dev_id).udev with 0 values
   end release_registered_device_entry;


   procedure register_device
     (task_id  : in  t_task_id;
      udev     : in  ewok.exported.devices.t_user_device_access;
      dev_id   : out t_device_id;
      success  : out boolean)
   is
      devinfo  : c.socinfo.t_device_soc_infos_access;
      len      : constant natural := types.c.len (udev.all.name);
      name     : string (1 .. len);
      found    : boolean;
   begin

      -- Convert C name to Ada string type for further log messages
      types.c.to_ada (name, udev.all.name);

      -- Is it an existing device ?
      -- Note: GPIOs (size = 0) are not considered as devices despite a task
      --       can register them. Thus, we don't look for them in c.socinfo
      --       table.
      if udev.all.size /= 0 then
         devinfo := c.socinfo.soc_devmap_find_device
           (udev.all.base_addr, udev.all.size);
         if devinfo = NULL then
            debug.log (debug.ERROR, "Can't find device " & name & "(addr:" &
               system_address'image (udev.all.base_addr) & ", size:" &
               unsigned_32'image (udev.all.size) & ")");
            success := false;
            return;
         end if;
      end if;

      -- Is it already used ?
      -- Note: GPIOs alone are not considered as devices. When the user
      --       declares lone GPIOs, devinfo is NULL
      for id in registered_device'range loop
         if registered_device(id).status  /= DEV_STATE_UNUSED and then
            registered_device(id).devinfo /= NULL and then
            registered_device(id).devinfo = devinfo
         then
            debug.log (debug.ERROR, "Device " & name & " is already used");
            success := false;
            return;
         end if;
      end loop;

      -- Are the GPIOs already used ?
      for i in 1 .. udev.gpio_num loop
         if ewok.gpio.is_used (udev.gpios(i).kref) then
            debug.log (debug.ERROR,
               "Device " & name & ": some GPIOs are already used");
            success := false;
            return;
         end if;
      end loop;

      -- Are the related EXTIs already used ?
      for i in 1 .. udev.gpio_num loop
         if boolean (udev.gpios(i).settings.set_exti) and then
            ewok.exti.is_used (udev.gpios(i).kref)
         then
            debug.log (debug.ERROR,
               "Device " & name & ": some EXTIs are already used");
            success := false;
            return;
         end if;
      end loop;

      -- We verify that the interrupts declared by this device really belong
      -- to it
      for declared_it in 1 .. udev.interrupt_num loop
         found := false;

         inner_loop:
         for i in devinfo.interrupt_list'range loop
            if devinfo.interrupt_list(i)
                  = udev.interrupts(declared_it).interrupt
            then
               found := true;
               exit inner_loop;
            end if;
         end loop inner_loop;

         if not found then
            debug.log (debug.ERROR,
               "Device " & name &
               ": interrupt(s) not owned by device. Check devmap");
            success := false;
            return;
         end if;
      end loop;

      -- Is it possible to register interrupt handlers ?
      for i in 1 .. udev.interrupt_num loop
         if ewok.interrupts.is_interrupt_already_used
              (udev.interrupts(i).interrupt)
         then
            debug.log (debug.ERROR,
               "Device " & name & ": some interrupts are already used");
            success := false;
            return;
         end if;
      end loop;

      -- Is it possible to register a device ?
      get_registered_device_entry (dev_id, success);

      if not success then
         debug.log (debug.ERROR,
            "register_device(): no slot left to register the device");
         return;
      end if;

      -- Registering the device
      debug.log (debug.INFO, "Registered device " & name & " (0x" &
         system_address'image (udev.all.base_addr) & ")");

      registered_device(dev_id).udev      := udev.all;
      registered_device(dev_id).task_id   := task_id;
      registered_device(dev_id).devinfo   := devinfo;
      registered_device(dev_id).status    := DEV_STATE_REGISTERED;

      -- Registering GPIOs
      for i in 1 .. udev.gpio_num loop
         ewok.gpio.register
           (task_id,
            dev_id,
            registered_device(dev_id).udev.gpios(i)'access,
            success);
         if not success then
            raise program_error;
         end if;

         debug.log (debug.INFO,
            "Registered GPIO port" &
            soc.gpio.t_gpio_port_index'image (udev.gpios(i).kref.port) &
            " pin " &
            soc.gpio.t_gpio_pin_index'image (udev.gpios(i).kref.pin));
      end loop;

      -- Registering EXTIs
      for i in 1 .. udev.gpio_num loop
         ewok.exti.register (udev.gpios(i)'access, success);
         if not success then
            raise program_error;
         end if;
      end loop;

      -- Registering handlers
      for i in 1 .. udev.interrupt_num loop
         ewok.interrupts.set_interrupt_handler
           (udev.interrupts(i).interrupt,
            udev.interrupts(i).handler,
            task_id,
            dev_id,
            success);
         if not success then
            raise program_error;
         end if;
      end loop;

      success := true;

   end register_device;


   procedure release_device
     (task_id  : in  t_task_id;
      dev_id   : in  t_device_id;
      success  : out boolean)
   is
   begin

      -- That device belongs to the task?
      if registered_device(dev_id).task_id /= task_id then
         success := false;
         return;
      end if;

      -- Releasing GPIOs and EXTIs
      for i in 1 .. registered_device(dev_id).udev.gpio_num loop

         ewok.gpio.release
           (task_id, dev_id, registered_device(dev_id).udev.gpios(i)'access);

         ewok.exti.release (registered_device(dev_id).udev.gpios(i)'access);

      end loop;

      -- Releasing interrupts
      for i in 1 .. registered_device(dev_id).udev.interrupt_num loop
         ewok.interrupts.reset_interrupt_handler
           (registered_device(dev_id).udev.interrupts(i).interrupt,
            task_id,
            dev_id);
      end loop;

      -- Releasing the device
      release_registered_device_entry (dev_id);

   end release_device;


   procedure enable_device
     (dev_id   : in  t_device_id;
      success  : out boolean)
   is
      irq         : soc.nvic.t_irq_index;
      interrupt   : t_interrupt;
   begin

      -- Check if the device was already configured
      -- the device can be registered (first mapping) or enabled (successive (un)mappings)
      if registered_device(dev_id).status /= DEV_STATE_REGISTERED and
         registered_device(dev_id).status /= DEV_STATE_ENABLED then
         raise program_error;
      end if;

      -- Configure and enable GPIOs
      for i in 1 .. registered_device(dev_id).udev.gpio_num loop
         ewok.gpio.config (registered_device(dev_id).udev.gpios(i)'access);
         if registered_device(dev_id).udev.gpios(i).exti_trigger /=
               GPIO_EXTI_TRIGGER_NONE
         then
            ewok.exti.enable (registered_device(dev_id).udev.gpios(i).kref);
         end if;
      end loop;

      -- For each interrupt, enable its associated IRQ in the NVIC
      for i in 1 .. registered_device(dev_id).udev.interrupt_num loop
         interrupt := registered_device(dev_id).udev.interrupts(i).interrupt;
         irq       := soc.nvic.to_irq_number (interrupt);
         soc.nvic.enable_irq (irq);
         debug.log (debug.INFO, "IRQ enabled" & soc.nvic.t_irq_index'image (irq) & " (int:"
            & t_interrupt'image (interrupt) & ")");
      end loop;

      -- Enable device's clock
      if registered_device(dev_id).devinfo /= NULL then
         -- some device may not depend on a RCC clock (this is the case of
         -- the SoC flash device, which is enabled at boot time and has no
         -- RCC bit on STM32 for example).
         if registered_device(dev_id).devinfo.all.rcc_enr /= 0 then
            c.socinfo.soc_devmap_enable_clock (registered_device(dev_id).devinfo.all);
         end if;
         declare
            udev : constant t_user_device := registered_device(dev_id).udev;
            name : string (1 .. types.c.len (udev.name));
         begin
            types.c.to_ada (name, udev.name);
            debug.log (debug.INFO, "Enabled device " & name);
         end;
      end if;

      registered_device(dev_id).status := DEV_STATE_ENABLED;
      success := true;
   end enable_device;


   function sanitize_user_defined_interrupt
     (udev     : in  ewok.exported.devices.t_user_device_access;
      config   : in  ewok.exported.interrupts.t_interrupt_config;
      task_id  : in  t_task_id)
      return boolean
   is
   begin

      if not ewok.sanitize.is_word_in_txt_slot
            (to_system_address (config.handler), task_id)
      then
         debug.log (debug.ERROR, "Device handler not in TXT slot");
         return false;
      end if;

      if config.interrupt not in INT_WWDG .. INT_HASH_RNG
      then
         debug.log (debug.ERROR, "Device interrupt not in range");
         return false;
      end if;

      if config.mode = ISR_FORCE_MAINTHREAD and then
         not ewok.perm.ressource_is_granted (PERM_RES_TSK_FISR, task_id)
      then
         debug.log (debug.ERROR, "Device ISR_FORCE_MAINTHREAD not allowed");
         return false;
      end if;

      --
      -- Verify posthooks
      --

      for i in 1 .. MAX_POSTHOOK_INSTR loop

         if not config.posthook.action(i).instr'valid then
            debug.log (debug.ERROR,
               "Device posthook: invalid action requested");
            return false;
         end if;

         case config.posthook.action(i).instr is
            when POSTHOOK_NIL       => null;

            when POSTHOOK_READ      =>
               if config.posthook.action(i).read.offset > udev.all.size - 4 or
                  (config.posthook.action(i).read.offset and 2#11#) > 0
               then
                  debug.log (debug.ERROR,
                     "Device posthook: wrong READ offset");
                  return false;
               end if;

            when POSTHOOK_WRITE     =>
               if config.posthook.action(i).write.offset > udev.all.size - 4 or
                  (config.posthook.action(i).write.offset and 2#11#) > 0
               then
                  debug.log (debug.ERROR,
                     "Device posthook: wrong WRITE offset");
                  return false;
               end if;

            when POSTHOOK_WRITE_REG =>
               if config.posthook.action(i).write_reg.offset_dest >
                     udev.all.size - 4
                  or (config.posthook.action(i).write_reg.offset_dest and 2#11#)
                        > 0
                  or config.posthook.action(i).write_reg.offset_src >
                        udev.all.size - 4
                  or (config.posthook.action(i).write_reg.offset_src and 2#11#)
                        > 0
               then
                  debug.log (debug.ERROR,
                     "Device posthook: wrong AND offset");
                  return false;
               end if;

            when POSTHOOK_WRITE_MASK =>

               if config.posthook.action(i).write_mask.offset_dest >
                     udev.all.size - 4
                  or (config.posthook.action(i).write_mask.offset_dest and 2#11#)
                        > 0
                  or config.posthook.action(i).write_mask.offset_src >
                        udev.all.size - 4
                  or (config.posthook.action(i).write_mask.offset_src and 2#11#)
                        > 0
                  or config.posthook.action(i).write_mask.offset_mask >
                        udev.all.size - 4
                  or (config.posthook.action(i).write_mask.offset_mask and 2#11#)
                        > 0
               then
                  debug.log (debug.ERROR,
                     "Device posthook: wrong MASK offset");
                  return false;
               end if;
         end case;

      end loop;

      return true;

   end sanitize_user_defined_interrupt;


   function sanitize_user_defined_gpio
     (udev     : in  ewok.exported.devices.t_user_device_access;
      config   : in  ewok.exported.gpios.t_gpio_config;
      task_id  : in  t_task_id)
      return boolean
   is
      pragma unreferenced (udev);
   begin

      if config.exti_trigger /= GPIO_EXTI_TRIGGER_NONE and then
         not ewok.perm.ressource_is_granted (PERM_RES_DEV_EXTI, task_id)
      then
         debug.log (debug.ERROR, "Device PERM_RES_DEV_EXTI not allowed");
         return false;
      end if;

      if config.exti_handler /= 0 and then
         not ewok.sanitize.is_word_in_txt_slot (config.exti_handler, task_id)
      then
         debug.log (debug.ERROR, "Device EXTI handler not in TXT slot");
         return false;
      end if;

      if not config.exti_lock'valid
      then
         debug.log (debug.ERROR, "Device EXTI lock mode not valid");
         return false;
      end if;

      return true;

   end sanitize_user_defined_gpio;


   function sanitize_user_defined_device
     (udev     : in  ewok.exported.devices.t_user_device_access;
      task_id  : in  t_task_id)
      return boolean
   is
      devinfo : c.socinfo.t_device_soc_infos_access;
      ok       : boolean;

      len   : constant natural := types.c.len (udev.all.name);
      name  : string (1 .. natural'min (t_device_name'length, len));
   begin

      if udev.all.name(t_device_name'last) /= ASCII.NUL then
         types.c.to_ada (name, udev.all.name(1 .. t_device_name'length));
         debug.log (debug.ERROR, "Out-of-bound device name: " & name);
         return false;
      else
         types.c.to_ada (name, udev.all.name);
      end if;

      if udev.all.size /= 0 then
         devinfo :=
            c.socinfo.soc_devmap_find_device (udev.all.base_addr, udev.all.size);

         if devinfo = NULL then
            debug.log (debug.ERROR, "Device at addr" & system_address'image
               (udev.all.base_addr) & " with size" & unsigned_32'image (udev.all.size) &
               ": not found");
            return false;
         end if;

         if not ewok.perm.ressource_is_granted (devinfo.minperm, task_id) then
            debug.log (debug.ERROR, "Task" & t_task_id'image (task_id) &
               " has not access to device " & name);
            return false;
         end if;
      end if;

      for i in 1 .. udev.all.interrupt_num loop
         ok := sanitize_user_defined_interrupt
                 (udev, udev.all.interrupts(i), task_id);
         if not ok then
            debug.log (debug.ERROR, "Device " & name & ": invalid udev.interrupts parameter");
            return false;
         end if;
      end loop;

      for i in 1 .. udev.all.gpio_num loop
         ok := sanitize_user_defined_gpio (udev, udev.all.gpios(i), task_id);
         if not ok then
            debug.log (debug.ERROR, "Device " & name & ": invalid udev.gpios parameter");
            return false;
         end if;
      end loop;

      if udev.all.map_mode = DEV_MAP_VOLUNTARY then
         if not ewok.perm.ressource_is_granted (PERM_RES_MEM_DYNAMIC_MAP, task_id) then
            debug.log (debug.ERROR, "Task" & t_task_id'image (task_id) &
               " voluntary mapped device " & name & " not permited");
            return false;
        end if;
      end if;

      return true;

   end sanitize_user_defined_device;


   procedure mpu_mapping_device
     (dev_id   : in  t_device_id;
      region   : in  m4.mpu.t_region_number;
      success  : out boolean)
   is
      dev_size          : unsigned_32;
      mpu_region_size   : m4.mpu.t_region_size;
      region_type       : ewok.mpu.t_region_type;
      ok                : boolean;
   begin

      if dev_id = ID_DEV_UNUSED then
         debug.log ("mpu_mapping_device(): unused device"); 
         success := false;
         return;
      end if;

      dev_size := get_user_device_size (dev_id);

      if dev_size = 0 then
         debug.log ("mpu_mapping_device(): device size = 0");
         success := false;
         return;
      end if;

      ewok.mpu.bytes_to_region_size
        (dev_size, mpu_region_size, ok);

      if not ok then
         debug.log ("mpu_mapping_device(): bytes_to_region_size() failed!");
         success := false;
         return;
      end if;

      if is_user_device_region_ro (dev_id) then
         region_type := ewok.mpu.REGION_TYPE_RO_USER_DEV;
      else
         region_type := ewok.mpu.REGION_TYPE_USER_DEV;
      end if;

      ewok.mpu.regions_schedule
        (region_number  => region,
         addr           => get_user_device_addr (dev_id),
         size           => mpu_region_size,
         region_type    => region_type,
         subregion_mask => get_user_device_subregions_mask (dev_id));

      success := true;
   end mpu_mapping_device;


end ewok.devices;
