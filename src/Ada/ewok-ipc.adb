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

package body ewok.ipc
   with spark_mode => off
is

   function to_task_id
     (id : t_extended_task_id) return ewok.tasks_shared.t_task_id
   is
      pragma warnings (off); -- size may differ
      function convert is new ada.unchecked_conversion
        (t_extended_task_id, ewok.tasks_shared.t_task_id);
      pragma warnings (on);
      ret : constant ewok.tasks_shared.t_task_id := convert (id);
   begin
      if ret'valid then
         return ret;
      else
         raise constraint_error;
      end if;
   end to_task_id;


   function to_ext_task_id
     (id : ewok.tasks_shared.t_task_id) return t_extended_task_id
   is
      pragma warnings (off); -- size may differ
      function convert is new ada.unchecked_conversion
        (ewok.tasks_shared.t_task_id, t_extended_task_id);
      pragma warnings (on);
      ret : constant t_extended_task_id := convert (id);
   begin
      if ret'valid then
         return ret;
      else
         raise constraint_error;
      end if;
   end to_ext_task_id;


   procedure init_endpoint
     (ep : in out t_endpoint)
   is
   begin
      ep.from  := ewok.ipc.ID_UNUSED;
      ep.to    := ewok.ipc.ID_UNUSED;
      ep.state := FREE;
      ep.size  := 0;
      for i in ep.data'range loop
         ep.data(i)  := 0;
      end loop;
   end init_endpoint;


   procedure init_endpoints
   is
   begin
      for i in ipc_endpoints'range loop
         init_endpoint (ipc_endpoints(i));
      end loop;
   end init_endpoints;


   procedure get_endpoint
     (endpoint    : out t_extended_endpoint_id;
      success     : out boolean)
   is
   begin

      for i in ipc_endpoints'range loop
         if ipc_endpoints(i).state = FREE then
            ipc_endpoints(i).state  := READY;
            endpoint := i;
            success  := true;
            return;
         end if;
      end loop;

      endpoint := ID_ENDPOINT_UNUSED;
      success  := false;
   end get_endpoint;


   procedure release_endpoint
     (ep_id    : in  t_endpoint_id)
   is
   begin
      init_endpoint (ipc_endpoints(ep_id));
   end release_endpoint;


end ewok.ipc;
