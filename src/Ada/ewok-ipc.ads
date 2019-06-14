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


with ewok.tasks_shared;

package ewok.ipc
   with spark_mode => on
is

   --
   -- IPC EndPoints
   --

   MAX_IPC_MSG_SIZE     : constant := 128;

   type t_endpoint_state is (
      -- IPC endpoint is unused
      FREE,
      -- IPC endpoint is used and is ready for message passing
      READY,
      -- send() block until the receiver read the message
      WAIT_FOR_RECEIVER);

   type t_extended_task_id is
     (ID_UNUSED,
      ID_APP1,
      ID_APP2,
      ID_APP3,
      ID_APP4,
      ID_APP5,
      ID_APP6,
      ID_APP7,
      ANY_APP)
      with size => 8;

   for t_extended_task_id use
     (ID_UNUSED   => 0,
      ID_APP1     => 1,
      ID_APP2     => 2,
      ID_APP3     => 3,
      ID_APP4     => 4,
      ID_APP5     => 5,
      ID_APP6     => 6,
      ID_APP7     => 7,
      ANY_APP     => 255);

   function to_task_id
     (id : t_extended_task_id) return ewok.tasks_shared.t_task_id;

   function to_ext_task_id
     (id : ewok.tasks_shared.t_task_id) return t_extended_task_id;

   type t_endpoint is record
      from  :  t_extended_task_id;
      to    :  t_extended_task_id;
      state :  t_endpoint_state;
      data  :  byte_array (1 .. MAX_IPC_MSG_SIZE);
      size  :  unsigned_8;
   end record;

   --
   -- Global pool of IPC EndPoints
   --

   ENDPOINTS_POOL_SIZE  : constant := 10;
   ID_ENDPOINT_UNUSED   : constant := 0;

   type t_extended_endpoint_id is
      range ID_ENDPOINT_UNUSED .. ENDPOINTS_POOL_SIZE;

   subtype t_endpoint_id is
      t_extended_endpoint_id range 1 .. ENDPOINTS_POOL_SIZE;

   ipc_endpoints : array (t_endpoint_id) of aliased t_endpoint;

   --
   -- Functions
   --

   -- Init IPC endpoints
   procedure init_endpoints;

   -- Get a free IPC endpoint
   procedure get_endpoint
     (endpoint    : out t_extended_endpoint_id;
      success     : out boolean);

   -- Release a used IPC endpoint
   procedure release_endpoint
     (ep_id       : in  t_endpoint_id);

end ewok.ipc;
