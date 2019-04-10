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


package ewok.interrupts.handler
   with spark_mode => off
is

   function usagefault_handler
     (frame_a : ewok.t_stack_frame_access) return ewok.t_stack_frame_access;

   function hardfault_handler
     (frame_a : ewok.t_stack_frame_access) return ewok.t_stack_frame_access;

   function systick_default_handler
     (frame_a : ewok.t_stack_frame_access) return ewok.t_stack_frame_access;

   function default_sub_handler
     (frame_a : t_stack_frame_access) return t_stack_frame_access
      with
         convention     => c,
         export         => true,
         external_name  => "Default_SubHandler";

end ewok.interrupts.handler;
