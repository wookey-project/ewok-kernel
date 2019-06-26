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
with ewok.posthook;
with ewok.softirq;
with ewok.dma;
with soc.dma;
with soc.nvic;

package body ewok.isr
   with spark_mode => off
is

   procedure postpone_isr
     (intr     : in soc.interrupts.t_interrupt;
      handler  : in ewok.interrupts.t_interrupt_handler_access;
      task_id  : in ewok.tasks_shared.t_task_id)
   is

      pragma warnings (off); -- Size differ
      function to_unsigned_32 is new ada.unchecked_conversion
        (soc.dma.t_dma_stream_int_status, unsigned_32);
      pragma warnings (on);

      dma_status  : soc.dma.t_dma_stream_int_status;
      status      : unsigned_32 := 0;
      data        : unsigned_32 := 0;
      isr_params  : ewok.softirq.t_isr_parameters;
      ok          : boolean;
   begin

      -- Acknowledge interrupt:
      -- - DMAs are managed by the kernel
      -- - Devices managed by user tasks should use the posthook mechanism
      --   to acknowledge interrupt (in order to avoid bursts).
      -- Note:
      --   Posthook execution is mandatory for hardware devices that wait for
      --   a quick answer from the driver. It permit to execute some
      --   instructions (reading and writing registers) and to return some
      --   value (former 'status' and 'data' parameters)

      if soc.dma.soc_is_dma_irq (intr) then
         ewok.dma.get_status_register (task_id, intr, dma_status, ok);
         if ok then
            status := to_unsigned_32 (dma_status) and 2#0011_1101#;
         else
            raise program_error;
         end if;
         ewok.dma.clear_dma_interrupts (task_id, intr);
      else
         ewok.posthook.exec (intr, status, data);
      end if;

      -- All user ISR have their Pending IRQ bit clean here
      soc.nvic.clear_pending_irq (soc.nvic.to_irq_number (intr));

      -- Pushing the request for further treatment by softirq
      isr_params.handler          := ewok.interrupts.to_system_address (handler);
      isr_params.interrupt        := intr;
      isr_params.posthook_status  := status;
      isr_params.posthook_data    := data;

      ewok.softirq.push_isr (task_id, isr_params);
      return;

   end postpone_isr;

end ewok.isr;
