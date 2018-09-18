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

with soc.interrupts; use soc.interrupts;
with ewok.tasks;     use ewok.tasks;
with ewok.posthook;
with ewok.softirq;
with ewok.dma;
with ewok.dma.interfaces;
with soc.dma;
with soc.nvic;

package body ewok.isr
   with spark_mode => off
is

   procedure postpone_isr
     (intr     : in soc.interrupts.t_interrupt;
      handler  : in ewok.interrupts.t_interrupt_handler_access;
      task_id  : in ewok.tasks_shared.t_task_id;
      frame_a  : in t_stack_frame_access)
   is
      status      : unsigned_32 := 0;
      data        : unsigned_32 := 0;
      isr_params  : ewok.softirq.t_isr_parameters;
   begin

      -- If the current ISR is handled by the kernel, we just execute it we
      -- return without requesting schedule

      if ewok.tasks.tasks_list(task_id).ttype = TASK_TYPE_KERNEL then
         handler (frame_a);
         return;
      end if;

      -- Acknowledge interrupt:
      -- - DMAs are managed by the kernel
      -- - Devices managed by user tasks should use the posthook mechanism
      --   to acknowledge interrupt (in order to avoid bursts). Note that
      --   posthook execution is mandatory for hardware devices that wait for
      --   a quick answer from the driver. It permit to execute some
      --   instructions (reading and writing registers) and to return some
      --   results in the 'args' parameter.

#if CONFIG_KERNEL_DMA_ENABLE
      if soc.dma.soc_is_dma_irq (intr) then
         status := ewok.dma.interfaces.dma_get_status (task_id, intr);
         ewok.dma.clear_dma_interrupts (task_id, intr);
      else
         ewok.posthook.exec (intr, status, data);
      end if;
#else
      ewok.posthook.exec (intr, status, data);
#end if;

      -- All user ISR have their Pending IRQ bit clean here
      soc.nvic.clear_pending_irq (soc.nvic.to_irq_number (intr));

      -- FIXME - softirq.query parameters interface must use some
      --         explanatory names
      isr_params.handler          := ewok.interrupts.to_system_address (handler);
      isr_params.interrupt        := intr;
      isr_params.posthook_status  := status;
      isr_params.posthook_data    := data;

      ewok.softirq.push_isr (task_id, isr_params);
      return;

   end postpone_isr;

end ewok.isr;
