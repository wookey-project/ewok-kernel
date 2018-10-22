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
   with spark_mode
is

   -- FIXME - using an enumeration with size 32
   subtype t_syscall_ret is unsigned_32;

   SYS_E_DONE     : constant t_syscall_ret := 0;
      -- Syscall has succesfully being executed
   SYS_E_INVAL    : constant t_syscall_ret := 1;
      -- Invalid input data
   SYS_E_DENIED   : constant t_syscall_ret := 2;
      -- Permission is denied
   SYS_E_BUSY     : constant t_syscall_ret := 3;
      -- Target is busy OR not enough ressources OR ressource is already used

   type t_svc_type is
     (SVC_SYSCALL,
      SVC_TASK_DONE,
      SVC_ISR_DONE)
      with size => 8;

   function to_svc_type is new ada.unchecked_conversion
     (unsigned_8, t_svc_type);

   type t_syscall_type is
     (SYS_YIELD,
      SYS_INIT,
      SYS_IPC,
      SYS_CFG,
      SYS_GETTICK,
      SYS_RESET,
      SYS_SLEEP,
      SYS_LOCK)
      with size => 32;

   type t_syscalls_init is
     (INIT_DEVACCESS,
      INIT_DMA,
      INIT_DMA_SHM,
      INIT_GETTASKID,
      INIT_DONE);

   type t_syscalls_ipc is
     (IPC_LOG,
      IPC_RECV_SYNC,
      IPC_SEND_SYNC,
      IPC_RECV_ASYNC,
      IPC_SEND_ASYNC);

   type t_syscalls_cfg is
     (CFG_GPIO_SET,
      CFG_GPIO_GET,
      CFG_GPIO_UNLOCK_EXTI,
      CFG_DMA_RECONF,
      CFG_DMA_RELOAD,
      CFG_DMA_DISABLE,
      CFG_DEV_MAP,
      CFG_DEV_UNMAP);

   type t_syscalls_lock is
     (LOCK_ENTER,
      LOCK_EXIT);

   type t_syscall_parameters is record
      syscall_type   : t_syscall_type;
      args           : aliased t_parameters;
   end record
      with pack;

end ewok.syscalls;
