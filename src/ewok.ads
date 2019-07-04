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


with ada.unchecked_conversion;
with interfaces; use interfaces;
with types; use types;
with m4.cpu;

package ewok
   with spark_mode => on
is

   type t_stack_frame is record
      R4, R5, R6, R7    : unsigned_32;
      R8, R9, R10, R11  : unsigned_32;
      exc_return        : unsigned_32;
      R0, R1, R2, R3    : unsigned_32;
      R12               : unsigned_32;
      LR                : system_address;
      PC                : system_address;
      PSR               : m4.cpu.t_PSR_register;
   end record
      with size => 17 * 32;

   type t_stack_frame_access is access t_stack_frame;

   function to_stack_frame_access is new ada.unchecked_conversion
        (system_address, t_stack_frame_access);

   function to_system_address is new ada.unchecked_conversion
        (t_stack_frame_access, system_address);

   type t_parameters is array (1 .. 4) of unsigned_32 with pack;

   type t_parameters_access is access t_parameters;

   function to_parameters_access is new ada.unchecked_conversion
        (system_address, t_parameters_access);

   procedure main
      with  convention     => c,
            export         => true,
            external_name  => "ewok_main";

end ewok;
