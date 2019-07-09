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

with ewok.exported.interrupts;   use ewok.exported.interrupts;
with ewok.devices_shared;        use ewok.devices_shared;
with ewok.interrupts;
with ewok.devices;

package body ewok.posthook
   with spark_mode => off
is


   function read_register (addr : system_address)
      return unsigned_32
   is
      reg : unsigned_32
         with import, volatile_full_access, address => to_address (addr);
   begin
      return reg;
   end read_register;

   pragma inline (read_register);


   procedure set_bits_in_register
     (addr  : in  system_address;
      bits  : in  unsigned_32;
      val   : in  unsigned_32)
   is
      reg : unsigned_32
         with import, volatile_full_access, address => to_address (addr);
   begin
      if bits = 16#FFFF_FFFF# then
         reg := val;
      else
         reg := (reg and (not bits)) or (val and bits);
      end if;
   end set_bits_in_register;


   procedure exec
     (intr     : in  soc.interrupts.t_interrupt;
      status   : out unsigned_32;
      data     : out unsigned_32)
   is
      dev_id   : ewok.devices_shared.t_device_id;
      dev_addr : system_address;
      config   : ewok.exported.interrupts.t_interrupt_config_access;
      found    : boolean;
      val      : unsigned_32;
      mask     : unsigned_32;
   begin

      config := ewok.devices.get_interrupt_config_from_interrupt (intr);
      if config = NULL then
         status := 0;
         data   := 0;
         return;
      end if;

      dev_id := ewok.interrupts.get_device_from_interrupt (intr);
      if dev_id = ID_DEV_UNUSED then
         status := 0;
         data   := 0;
         return;
      end if;

      dev_addr := ewok.devices.get_device_addr (dev_id);

      for i in config.all.posthook.action'range loop
         case config.all.posthook.action(i).instr is

            when POSTHOOK_NIL    =>
               -- No subsequent action. Returning.
               return;

            when POSTHOOK_READ   =>
               val := read_register (dev_addr +
                  system_address (config.all.posthook.action(i).read.offset));

               config.all.posthook.action(i).read.value := val;

               -- This value need to be saved ?
               if config.all.posthook.status =
                     config.all.posthook.action(i).read.offset
               then
                  status := val;
               end if;

               -- This value need to be saved ?
               if
                  config.all.posthook.data =
                     config.all.posthook.action(i).read.offset
               then
                  data := val;
               end if;

            when POSTHOOK_WRITE  =>
               set_bits_in_register
                 (dev_addr + system_address
                    (config.all.posthook.action(i).write.offset),
                  config.all.posthook.action(i).write.mask,
                  config.all.posthook.action(i).write.value);

            when POSTHOOK_WRITE_REG    =>
               -- Retrieving the already read register value
               found := false;
               for j in config.all.posthook.action'first .. i loop
                  if config.all.posthook.action(j).instr = POSTHOOK_READ and then
                     config.all.posthook.action(j).read.offset =
                        config.all.posthook.action(i).write_reg.offset_src
                  then
                     val   := config.all.posthook.action(j).read.value;
                     found := true;
                     exit;
                  end if;
               end loop;

               if not found then
                  val := read_register (dev_addr + system_address
                     (config.all.posthook.action(i).write_reg.offset_src));
               end if;

               -- Calculating the mask to apply in order to write only active
               -- bits
               mask := config.all.posthook.action(i).write_reg.mask and val;

               -- Inverted write might be needed
               if config.all.posthook.action(i).write_reg.mode = MODE_NOT then
                  val := not val;
               end if;

               -- Writing into the destination register
               set_bits_in_register
                 (dev_addr + system_address
                    (config.all.posthook.action(i).write_reg.offset_dest),
                  mask,
                  val);

            when POSTHOOK_WRITE_MASK   =>
               -- Retrieving the value
               found := false;
               for j in config.all.posthook.action'first .. i loop
                  if config.all.posthook.action(j).instr = POSTHOOK_READ and then
                     config.all.posthook.action(j).read.offset =
                        config.all.posthook.action(i).write_mask.offset_src
                  then
                     val   := config.all.posthook.action(j).read.value;
                     found := true;
                     exit;
                  end if;
               end loop;

               if not found then
                  val := read_register (dev_addr + system_address
                     (config.all.posthook.action(i).write_mask.offset_src));
               end if;

               -- Retrieving the mask
               found := false;
               for j in config.all.posthook.action'first .. i loop
                  if config.all.posthook.action(j).instr = POSTHOOK_READ and then
                     config.all.posthook.action(j).read.offset =
                        config.all.posthook.action(i).write_mask.offset_mask
                  then
                     mask  := config.all.posthook.action(j).read.value;
                     found := true;
                     exit;
                  end if;
               end loop;

               if not found then
                  mask := read_register (dev_addr + system_address
                     (config.all.posthook.action(i).write_mask.offset_mask));
               end if;

               -- Calculating the mask
               mask := mask and val;

               -- Inverted write might be needed
               if config.all.posthook.action(i).write_mask.mode = MODE_NOT then
                  val := not val;
               end if;

               -- Writing into the destination register
               set_bits_in_register
                 (dev_addr + system_address
                    (config.all.posthook.action(i).write_mask.offset_dest),
                  mask,
                  val);

         end case;
      end loop;

   end exec;

end ewok.posthook;
