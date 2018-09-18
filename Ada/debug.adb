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
         when DEBUG .. INFO      =>
            log (COLOR_KERNEL & s & COLOR_NORMAL);
         when WARNING .. ALERT   =>
            log (COLOR_ALERT & s & COLOR_NORMAL);
      end case;
   end log;


   procedure panic (s : string)
   is
   begin
      log (COLOR_ALERT & "panic: " & s & COLOR_NORMAL);
      loop null; end loop;
   end panic;

end debug;
