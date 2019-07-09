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


with applications; use applications;
with ewok.perm_auto;
with ewok.tasks_shared; use ewoK.tasks_shared;

package ewok.perm
  with spark_mode => on
is

   ---------------
   -- Types     --
   ---------------

   type t_perm_name is
      (PERM_RES_DEV_DMA,
       PERM_RES_DEV_CRYPTO_USR,
       PERM_RES_DEV_CRYPTO_CFG,
       PERM_RES_DEV_CRYPTO_FULL,
       PERM_RES_DEV_BUSES,
       PERM_RES_DEV_EXTI,
       PERM_RES_DEV_TIM,
       PERM_RES_TIM_GETMILLI,
       PERM_RES_TIM_GETMICRO,
       PERM_RES_TIM_GETCYCLE,
       PERM_RES_TSK_FISR,
       PERM_RES_TSK_FIPC,
       PERM_RES_TSK_RESET,
       PERM_RES_TSK_UPGRADE,
       PERM_RES_TSK_RNG,
       PERM_RES_MEM_DYNAMIC_MAP);

   ---------------
   -- Functions --
   ---------------

   pragma assertion_policy (pre => IGNORE, post => IGNORE, assert => IGNORE);

   -- Test if a task is allowed to share a DMA SHM with another task
   function dmashm_is_granted
     (from    : in t_real_task_id;
      to      : in t_real_task_id)
      return boolean
      with
         Global => null, -- com_dmashm_perm is a constant, not a variable
         Post   => (if (from = to) then dmashm_is_granted'Result = false),
         Contract_Cases => (ewok.perm_auto.com_dmashm_perm(from,to) => dmashm_is_granted'Result,
                            others                                  => not dmashm_is_granted'Result);

   -- Test if a task is allowed to send an IPC to another task
   function ipc_is_granted
     (from    : in t_real_task_id;
      to      : in t_real_task_id)
      return boolean
      with
         Global => null, -- com_ipc_perm is a constant, not a variable
         Post   => (if (from = to) then ipc_is_granted'Result = false),
         Contract_Cases => (ewok.perm_auto.com_ipc_perm(from,to) => ipc_is_granted'Result,
                            others                               => not ipc_is_granted'Result);

#if CONFIG_KERNEL_DOMAIN
   function is_same_domain
     (from    : in t_real_task_id;
      to      : in t_real_task_id)
      return boolean
      with
         Global    => null,
         Post      => (if (from = to) then is_same_domain'Result = false);
#end if;

   -- Test if a task is allowed to use a resource
   function ressource_is_granted
     (perm_name : in t_perm_name;
      task_id   : in applications.t_real_task_id)
      return boolean
      with Global => null;


end ewok.perm;
