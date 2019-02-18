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

with soc.gpio;             use soc.gpio;
with soc.exti;             use soc.exti;
with soc.syscfg;
with soc.nvic;
with soc.interrupts;
with ewok.interrupts;
with ewok.exported.gpios;   use type ewok.exported.gpios.t_gpio_config_access;
                            use type ewok.exported.gpios.t_interface_gpio_exti_lock;
with ewok.gpio;
with ewok.tasks_shared;
with ewok.devices_shared;
with ewok.isr;
with debug;

package body ewok.exti.handler
   with spark_mode => off
is

   procedure init
   is
      ok : boolean;
   begin

      ewok.interrupts.set_interrupt_handler
        (soc.interrupts.INT_EXTI0,
         exti_handler'access,
         ewok.tasks_shared.ID_KERNEL,
         ewok.devices_shared.ID_DEV_UNUSED,
         ok);

      if not ok then raise program_error; end if;

      ewok.interrupts.set_interrupt_handler
        (soc.interrupts.INT_EXTI1,
         exti_handler'access,
         ewok.tasks_shared.ID_KERNEL,
         ewok.devices_shared.ID_DEV_UNUSED,
         ok);

      if not ok then raise program_error; end if;

      ewok.interrupts.set_interrupt_handler
        (soc.interrupts.INT_EXTI2,
         exti_handler'access,
         ewok.tasks_shared.ID_KERNEL,
         ewok.devices_shared.ID_DEV_UNUSED,
         ok);

      if not ok then raise program_error; end if;

      ewok.interrupts.set_interrupt_handler
        (soc.interrupts.INT_EXTI3,
         exti_handler'access,
         ewok.tasks_shared.ID_KERNEL,
         ewok.devices_shared.ID_DEV_UNUSED,
         ok);

      if not ok then raise program_error; end if;

      ewok.interrupts.set_interrupt_handler
        (soc.interrupts.INT_EXTI4,
         exti_handler'access,
         ewok.tasks_shared.ID_KERNEL,
         ewok.devices_shared.ID_DEV_UNUSED,
         ok);

      if not ok then raise program_error; end if;

      ewok.interrupts.set_interrupt_handler
        (soc.interrupts.INT_EXTI9_5,
         exti_handler'access,
         ewok.tasks_shared.ID_KERNEL,
         ewok.devices_shared.ID_DEV_UNUSED,
         ok);

      if not ok then raise program_error; end if;

      ewok.interrupts.set_interrupt_handler
        (soc.interrupts.INT_EXTI15_10,
         exti_handler'access,
         ewok.tasks_shared.ID_KERNEL,
         ewok.devices_shared.ID_DEV_UNUSED,
         ok);

      if not ok then raise program_error; end if;

   end init;


   procedure handle_line
     (line        : in  soc.exti.t_exti_line_index;
      interrupt   : in  soc.interrupts.t_interrupt)
   is
      ref         : ewok.exported.gpios.t_gpio_ref;
      conf        : ewok.exported.gpios.t_gpio_config_access;
      task_id     : ewok.tasks_shared.t_task_id;
   begin

      -- Clear the EXTI pending bit for this line
      soc.exti.clear_pending (line);

      -- Retrieve the configured GPIO point associated to this line
      ref.pin  := t_gpio_pin_index'val (t_exti_line_index'pos (line));
      ref.port := soc.syscfg.get_exti_port (ref.pin);

      -- Retrieving the GPIO configuration associated to that GPIO point.
      -- Permit to get the "real" user ISR.
      conf := ewok.gpio.get_config (ref);

      if conf = NULL then
         soc.nvic.clear_pending_irq (soc.nvic.to_irq_number (interrupt));
         debug.log (debug.ERROR, "unable to find GPIO informations for port" &
            t_gpio_port_index'image (ref.port) & ", pin" &
            t_gpio_pin_index'image (ref.pin));
      else
         task_id  := ewok.gpio.get_task_id (ref);

         ewok.isr.postpone_isr
           (interrupt,
            ewok.interrupts.to_handler_access (conf.all.exti_handler),
            task_id);

         -- if the EXTI line is configured as lockable by the kernel, the
         -- EXTI line is disabled here, and must be unabled later by the
         -- userspace using gpio_unlock_exti(). This permit to support
         -- external devices that generates regular EXTI events which are
         -- not correctly filtered
         if conf.all.exti_lock = ewok.exported.gpios.GPIO_EXTI_LOCKED then
            ewok.exti.disable(ref);
         end if;
      end if;

   end handle_line;


   procedure exti_handler
     (frame_a : in ewok.t_stack_frame_access)
   is
      pragma unreferenced (frame_a);
      intr        : soc.interrupts.t_interrupt;
   begin

      intr := soc.interrupts.get_interrupt;

      case intr is
         when soc.interrupts.INT_EXTI0 =>
            handle_line (0, intr);

         when soc.interrupts.INT_EXTI1 =>
            handle_line (1, intr);

         when soc.interrupts.INT_EXTI2 =>
            handle_line (2, intr);

         when soc.interrupts.INT_EXTI3 =>
            handle_line (3, intr);

         when soc.interrupts.INT_EXTI4 =>
            handle_line (4, intr);

         when soc.interrupts.INT_EXTI9_5     =>

            for line in t_exti_line_index range 5 .. 9 loop
               if soc.exti.is_line_pending (line) then
                  handle_line (line, intr);
               end if;
            end loop;

         when soc.interrupts.INT_EXTI15_10   =>

            for line in t_exti_line_index range 10 .. 15 loop
               if soc.exti.is_line_pending (line) then
                  handle_line (line, intr);
               end if;
            end loop;

         when others => raise program_error;
      end case;

   end exti_handler;

end ewok.exti.handler;
