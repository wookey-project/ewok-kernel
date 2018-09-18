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


package body soc.nvic
   with spark_mode => off
is

   function to_irq_number
     (intr : soc.interrupts.t_interrupt)
      return t_irq_index
   is
   begin
      return t_irq_index'val (soc.interrupts.t_interrupt'pos (intr) - 16);
   end to_irq_number;


   procedure enable_irq
     (irq : in t_irq_index)
   is
   begin
      case irq is
         when 0 .. 31  => NVIC.ISER0.irq(irq) := IRQ_ENABLED;
         when 32 .. 63 => NVIC.ISER1.irq(irq) := IRQ_ENABLED;
         when 64 .. 80 => NVIC.ISER2.irq(irq) := IRQ_ENABLED;
      end case;
   end enable_irq;


   procedure clear_pending_irq
     (irq : in t_irq_index)
   is
   begin
      case irq is
         when 0 .. 31  => NVIC.ICPR0.irq(irq) := CLEAR_PENDING;
         when 32 .. 63 => NVIC.ICPR1.irq(irq) := CLEAR_PENDING;
         when 64 .. 80 => NVIC.ICPR2.irq(irq) := CLEAR_PENDING;
      end case;
   end clear_pending_irq;

end soc.nvic;
