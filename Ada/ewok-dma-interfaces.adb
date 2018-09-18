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

package body ewok.dma.interfaces
   with spark_mode => off
is

   procedure dma_init
   is begin
      ewok.dma.init;
   end dma_init;

   function dma_get_status
     (caller_id   : ewok.tasks_shared.t_task_id;
      intr        : soc.interrupts.t_interrupt)
      return unsigned_32
   is

      pragma warnings (off); -- size may differ
      function to_unsigned_32 is new ada.unchecked_conversion
        (soc.dma.t_dma_stream_int_status, unsigned_32);
      pragma warnings (on);

      status : soc.dma.t_dma_stream_int_status;
      ok     : boolean;
   begin
      ewok.dma.get_status_register (caller_id, intr, status, ok);
      if ok then
         return to_unsigned_32 (status) and 16#0000_003F#;
      else
         return 0;
      end if;
   end dma_get_status;


end ewok.dma.interfaces;
