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


with types.c;
with c.kernel;
#if CONFIG_KERNEL_PANIC_WIPE
with soc;
with soc.layout; use soc.layout;
#end if;
#if not CONFIG_KERNEL_PANIC_FREEZE
with m4;
with m4.scb;
#end if;
with types;

package body debug
   with spark_mode => off
is

   procedure log (s : string; nl : boolean := true)
   is
      c_string : types.c.c_string (1 .. s'length + 3);
   begin

      for i in s'range loop
         c_string(1 + i - s'first) := s(i);
      end loop;

      if nl then
         c_string(c_string'last - 2) := ASCII.CR;
         c_string(c_string'last - 1) := ASCII.LF;
         c_string(c_string'last)     := ASCII.NUL;
      else
         c_string(c_string'last - 2) := ASCII.NUL;
      end if;

      c.kernel.log (c_string);
      c.kernel.flush;

   end log;


   procedure log (level : t_level; s : string)
   is
   begin
      case level is
         when DEBUG .. INFO   =>
            log (COLOR_KERNEL & s & COLOR_NORMAL);
         when WARNING         =>
            log (COLOR_WARNING & s & COLOR_NORMAL);
         when ERROR .. ALERT  =>
            log (COLOR_ALERT & s & COLOR_NORMAL);
      end case;
   end log;


   procedure panic (s : string)
   is
#if CONFIG_KERNEL_PANIC_WIPE
      sram : array (0 .. soc.layout.USER_RAM_SIZE) of types.byte
         with address => to_address(USER_RAM_BASE);
#end if;
   begin
      log (COLOR_ALERT & "panic: " & s & COLOR_NORMAL);
#if CONFIG_KERNEL_PANIC_FREEZE
      loop null; end loop;
#end if;
#if CONFIG_KERNEL_PANIC_REBOOT
      -- reseting right now...
      m4.scb.reset;
#end if;
#if CONFIG_KERNEL_PANIC_WIPE
      -- wiping the user applications RAM before reseting
      -- kernel data and bss are not cleared as:
      -- 1) it is currently used
      -- 2) there is, normally, no interresting content in the kernel data
      --    as secrets (Pin, etc. are contents hold in the user
      -- TODO: Although: the IPC content should be cleared as they may hold some
      -- secrets.
      sram := (others => 0);
      m4.scb.reset;
#end if;
   end panic;

end debug;
