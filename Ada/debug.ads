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



package debug
   with spark_mode => off
is

   type t_level is (DEBUG, INFO, WARNING, ERROR, ALERT);

   COLOR_NORMAL  : constant string := ASCII.ESC & "[37;40m";
   COLOR_WARNING : constant string := ASCII.ESC & "[37;43m";
   COLOR_ALERT   : constant string := ASCII.ESC & "[37;41m";
   COLOR_KERNEL  : constant string := ASCII.ESC & "[37;44m";

   procedure log (s : string; nl : boolean := true);
   procedure log (level : t_level; s : string);
   procedure panic (s : string);

end debug;
