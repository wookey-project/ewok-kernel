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

package ewok.syscalls
   with spark_mode => on
is

   subtype t_syscall_ret is unsigned_32;

   SYS_E_DONE     : constant t_syscall_ret := 0; -- Syscall succesful
   SYS_E_INVAL    : constant t_syscall_ret := 1; -- Invalid input data
   SYS_E_DENIED   : constant t_syscall_ret := 2; -- Permission is denied
   SYS_E_BUSY     : constant t_syscall_ret := 3;
      -- Target is busy OR not enough ressources OR ressource is already used

   type t_svc is
     (SVC_EXIT,
      SVC_YIELD,
      SVC_GET_TIME,
      SVC_RESET,
      SVC_SLEEP,
      SVC_GET_RANDOM,
      SVC_LOG,
      SVC_REGISTER_DEVICE,
      SVC_REGISTER_DMA,
      SVC_REGISTER_DMA_SHM,
      SVC_GET_TASKID,
      SVC_INIT_DONE,
      SVC_IPC_RECV_SYNC,
      SVC_IPC_SEND_SYNC,
      SVC_IPC_RECV_ASYNC,
      SVC_IPC_SEND_ASYNC,
      SVC_GPIO_SET,
      SVC_GPIO_GET,
      SVC_GPIO_UNLOCK_EXTI,
      SVC_DMA_RECONF,
      SVC_DMA_RELOAD,
      SVC_DMA_DISABLE,
      SVC_DEV_MAP,
      SVC_DEV_UNMAP,
      SVC_DEV_RELEASE,
      SVC_LOCK_ENTER,
      SVC_LOCK_EXIT,
      SVC_PANIC,
      SVC_ALARM)
   with size => 8;

end ewok.syscalls;
