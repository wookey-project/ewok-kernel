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
         when DEBUG =>
            log (BG_COLOR_ORANGE & s & BG_COLOR_BLACK);
         when INFO   =>
            log (BG_COLOR_BLUE & s & BG_COLOR_BLACK);
         when WARNING         =>
            log (BG_COLOR_ORANGE & s & BG_COLOR_BLACK);
         when ERROR .. ALERT  =>
#if CONFIG_KERNEL_PANIC_ON_ERROR
            panic (s);
#else
            log (BG_COLOR_RED & s & BG_COLOR_BLACK);
#end if;
      end case;
   end log;


   procedure panic (s : string)
   is
   begin
      log (BG_COLOR_RED & "panic: " & s & BG_COLOR_BLACK);

#if CONFIG_KERNEL_PANIC_FREEZE
      loop null; end loop;
#end if;

#if CONFIG_KERNEL_PANIC_REBOOT
      m4.scb.reset;
#end if;

#if CONFIG_KERNEL_PANIC_WIPE
      declare
         sram : array (0 .. soc.layout.USER_RAM_SIZE) of types.byte
            with address => to_address(USER_RAM_BASE);
      begin
         -- Wiping the user applications in RAM before reseting. Kernel data
         -- and bss are not cleared because the are in use and there should
         -- be no sensible content in kernel data (secrets are hold by user tasks).
         -- TODO: Clearing IPC content
         sram := (others => 0);
         m4.scb.reset;
      end;
#end if;

   end panic;

end debug;
