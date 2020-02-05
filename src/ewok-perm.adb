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


#if CONFIG_KERNEL_DOMAIN
with ewok.tasks;
#end if;

package body ewok.perm
  with spark_mode => on
is

   function dmashm_is_granted
     (from    : in t_real_task_id;
      to      : in t_real_task_id)
      return boolean
   is
   begin
      return ewok.perm_auto.com_dmashm_perm (from, to);
   end dmashm_is_granted;


   function ipc_is_granted
     (from    : in t_real_task_id;
      to      : in t_real_task_id)
      return boolean
   is
   begin
      return ewok.perm_auto.com_ipc_perm (from, to);
   end ipc_is_granted;


#if CONFIG_KERNEL_DOMAIN
   function is_same_domain
     (from    : in t_real_task_id;
      to      : in t_real_task_id)
      return boolean
   is
   begin
      return
         ewok.tasks.get_domain (from) = ewok.tasks.get_domain (to);
   end is_same_domain;
#end if;


   function ressource_is_granted
     (perm_name : in t_perm_name;
      task_id   : in config.applications.t_real_task_id)
      return boolean
   is
   begin
      -- is there some assertion checking that some ressources tuples are
      -- forbidden

      case perm_name is
         when PERM_RES_DEV_DMA =>
            return
               ewok.perm_auto.ressource_perm_register_tab(task_id).DEV_DMA = 1;

         when PERM_RES_DEV_CRYPTO_USR =>
            return
               ewok.perm_auto.ressource_perm_register_tab(task_id).DEV_CRYPTO = 1 or
               ewok.perm_auto.ressource_perm_register_tab(task_id).DEV_CRYPTO = 3;

         when PERM_RES_DEV_CRYPTO_CFG =>
            return
               ewok.perm_auto.ressource_perm_register_tab(task_id).DEV_CRYPTO = 2 or
               ewok.perm_auto.ressource_perm_register_tab(task_id).DEV_CRYPTO = 3;

         when PERM_RES_DEV_CRYPTO_FULL =>
            return
               ewok.perm_auto.ressource_perm_register_tab(task_id).DEV_CRYPTO = 3;

         when PERM_RES_DEV_BUSES =>
            return
               ewok.perm_auto.ressource_perm_register_tab(task_id).DEV_BUS = 1;

         when PERM_RES_DEV_EXTI =>
            return
               ewok.perm_auto.ressource_perm_register_tab(task_id).DEV_EXTI = 1;

         when PERM_RES_DEV_TIM =>
            return
               ewok.perm_auto.ressource_perm_register_tab(task_id).DEV_TIM = 1;

         when PERM_RES_TIM_GETMILLI =>
            return
               ewok.perm_auto.ressource_perm_register_tab(task_id).TIM_TIME > 0;

         when PERM_RES_TIM_GETMICRO =>
            return
               ewok.perm_auto.ressource_perm_register_tab(task_id).TIM_TIME > 1;

         when PERM_RES_TIM_GETCYCLE =>
            return
               ewok.perm_auto.ressource_perm_register_tab(task_id).TIM_TIME > 2;

         when PERM_RES_TSK_FISR =>
            return
               ewok.perm_auto.ressource_perm_register_tab(task_id).TSK_FISR = 1;

         when PERM_RES_TSK_FIPC =>
            return
               ewok.perm_auto.ressource_perm_register_tab(task_id).TSK_FIPC = 1;

         when PERM_RES_TSK_RESET =>
            return
               ewok.perm_auto.ressource_perm_register_tab(task_id).TSK_RESET = 1;

         when PERM_RES_TSK_UPGRADE =>
            return
               ewok.perm_auto.ressource_perm_register_tab(task_id).TSK_UPGRADE = 1;

         when PERM_RES_TSK_RNG =>
            return
               ewok.perm_auto.ressource_perm_register_tab(task_id).TSK_RNG = 1;

         when PERM_RES_MEM_DYNAMIC_MAP =>
            return
               ewok.perm_auto.ressource_perm_register_tab(task_id).MEM_DYNAMIC_MAP = 1;

      end case;

   end ressource_is_granted;

end ewok.perm;
