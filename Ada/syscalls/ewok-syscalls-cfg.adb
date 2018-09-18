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

with ewok.tasks; use ewok.tasks;
with ewok.syscalls.cfg.gpio;
with ewok.syscalls.cfg.mem;
with ewok.syscalls.dma;

package body ewok.syscalls.cfg
   with spark_mode => off
is

   procedure sys_cfg
     (caller_id   : in     ewok.tasks_shared.t_task_id;
      params      : in out ewok.t_parameters;
      mode        : in     ewok.tasks_shared.t_task_mode)
   is
      syscall : t_syscalls_cfg
         with address => params(0)'address;
   begin

      if not syscall'valid then
         set_return_value (caller_id, mode, SYS_E_INVAL);
         ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
         return;
      end if;

      case syscall is
         when CFG_GPIO_SET    =>
            ewok.syscalls.cfg.gpio.gpio_set (caller_id, params, mode);
         when CFG_GPIO_GET    =>
            ewok.syscalls.cfg.gpio.gpio_get (caller_id, params, mode);
#if CONFIG_KERNEL_DMA_ENABLE
         when CFG_DMA_RECONF  =>
            ewok.syscalls.dma.sys_cfg_dma_reconf (caller_id, params, mode);
         when CFG_DMA_RELOAD  =>
            ewok.syscalls.dma.sys_cfg_dma_reload (caller_id, params, mode);
         when CFG_DMA_DISABLE   =>
            ewok.syscalls.dma.sys_cfg_dma_disable (caller_id, params, mode);
#else
         when CFG_DMA_RECONF  => null;
         when CFG_DMA_RELOAD  => null;
         when CFG_DMA_DISABLE => null;
#end if;
         when CFG_DEV_MAP     =>
            ewok.syscalls.cfg.mem.dev_map (caller_id, params, mode);
         when CFG_DEV_UNMAP   =>
            ewok.syscalls.cfg.mem.dev_unmap (caller_id, params, mode);
      end case;

   end sys_cfg;


end ewok.syscalls.cfg;
