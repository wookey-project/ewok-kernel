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

with m4.layout;
with soc.interrupts; use type soc.interrupts.t_interrupt;

-- Nested vectored interrupt controller (NVIC)
-- (see STM32F4xxx Cortex-M4 Programming Manual, p. 194-205)

package soc.nvic
   with spark_mode => on
is

   -- Up to 81 interrupts (see Cortex-M4 prog. manual, p. 194)
   type t_irq_index is new natural range 0 .. 80;

   ----------
   -- IRQs --
   ----------
   -- (see RM0090, p. 374)

   EXTI_Line_0    : constant t_irq_index := 6;
   EXTI_Line_1    : constant t_irq_index := 7;
   EXTI_Line_2    : constant t_irq_index := 8;
   EXTI_Line_3    : constant t_irq_index := 9;
   EXTI_Line_4    : constant t_irq_index := 10;
   EXTI_Line_5_9  : constant t_irq_index := 23;
   EXTI_Line_10_15: constant t_irq_index := 40;

   DMA1_Stream_0  : constant t_irq_index := 11;
   DMA1_Stream_1  : constant t_irq_index := 12;
   DMA1_Stream_2  : constant t_irq_index := 13;
   DMA1_Stream_3  : constant t_irq_index := 14;
   DMA1_Stream_4  : constant t_irq_index := 15;
   DMA1_Stream_5  : constant t_irq_index := 16;
   DMA1_Stream_6  : constant t_irq_index := 17;
   DMA1_Stream_7  : constant t_irq_index := 47;

   SDIO           : constant t_irq_index := 49;

   DMA2_Stream_0  : constant t_irq_index := 56;
   DMA2_Stream_1  : constant t_irq_index := 57;
   DMA2_Stream_2  : constant t_irq_index := 58;
   DMA2_Stream_3  : constant t_irq_index := 59;
   DMA2_Stream_4  : constant t_irq_index := 60;
   DMA2_Stream_5  : constant t_irq_index := 68;
   DMA2_Stream_6  : constant t_irq_index := 69;
   DMA2_Stream_7  : constant t_irq_index := 70;

   -------------------------------------------------
   -- Interrupt set-enable registers (NVIC_ISERx) --
   -------------------------------------------------

   type t_irq_state is (IRQ_DISABLED, IRQ_ENABLED)
      with size => 1;
   for t_irq_state use (IRQ_DISABLED => 0, IRQ_ENABLED  => 1);

   DISABLE_IRQ : constant t_irq_state := IRQ_ENABLED; -- NVIC_ICER

   type t_irq_states is array (t_irq_index range <>) of t_irq_state
      with pack;

   -- ISER0
   type t_NVIC_ISER0 is record
      irq : t_irq_states (0 .. 31);
   end record
      with pack, size => 32, volatile_full_access;

   -- ISER1
   type t_NVIC_ISER1 is record
      irq : t_irq_states (32 .. 63);
   end record
      with pack, size => 32, volatile_full_access;

   -- ISER2
   type t_NVIC_ISER2 is record
      irq : t_irq_states (64 .. 80);
   end record
      with size => 32, volatile_full_access;

   for t_NVIC_ISER2 use record
      irq at 0 range 0 .. 16;
   end record;

   ---------------------------------------------------
   -- Interrupt clear-enable registers (NVIC_ICERx) --
   ---------------------------------------------------

   -- ICER0
   type t_NVIC_ICER0 is record
      irq : t_irq_states (0 .. 31);
   end record
      with pack, size => 32, volatile_full_access;

   -- ICER1
   type t_NVIC_ICER1 is record
      irq : t_irq_states (32 .. 63);
   end record
      with pack, size => 32, volatile_full_access;

   -- ICER2
   type t_NVIC_ICER2 is record
      irq : t_irq_states (64 .. 80);
   end record
      with size => 32, volatile_full_access;

   for t_NVIC_ICER2 use record
      irq at 0 range 0 .. 16;
   end record;

   ----------------------------------------------------
   -- Interrupt clear-pending registers (NVIC_ICPRx) --
   ----------------------------------------------------

   type t_irq_pending is (IRQ_NOT_PENDING, IRQ_PENDING)
      with size => 1;
   for t_irq_pending use (IRQ_NOT_PENDING => 0, IRQ_PENDING => 1);

   CLEAR_PENDING : constant t_irq_pending := IRQ_PENDING;

   type t_irq_pendings is array (t_irq_index range <>) of t_irq_pending
      with pack;

   -- ICPR0
   type t_NVIC_ICPR0 is record
      irq : t_irq_pendings (0 .. 31);
   end record
      with pack, size => 32, volatile_full_access;

   -- ICPR1
   type t_NVIC_ICPR1 is record
      irq : t_irq_pendings (32 .. 63);
   end record
      with pack, size => 32, volatile_full_access;

   -- ICPR2
   type t_NVIC_ICPR2 is record
      irq : t_irq_pendings (64 .. 80);
   end record
      with size => 32, volatile_full_access;

   for t_NVIC_ICPR2 use record
      irq at 0 range 0 .. 16;
   end record;

   ----------------------------------------------
   -- Interrupt priority registers (NVIC_IPRx) --
   ----------------------------------------------

   -- NVIC_IPR0-IPR80 registers provide an 8-bit priority field for each
   -- interrupt.

   type t_IPR is record
      reserved : bits_4;
      priority : bits_4;
   end record
      with pack, size => 8, volatile_full_access;

   type t_IPRs is array (t_irq_index) of t_IPR
      with pack, size => 8 * 81;

   ---------------------
   -- NVIC peripheral --
   ---------------------

   type t_NVIC_periph is record
      ISER0 : t_NVIC_ISER0;
      ISER1 : t_NVIC_ISER1;
      ISER2 : t_NVIC_ISER2;
      ICER0 : t_NVIC_ICER0;
      ICER1 : t_NVIC_ICER1;
      ICER2 : t_NVIC_ICER2;
      ICPR0 : t_NVIC_ICPR0;
      ICPR1 : t_NVIC_ICPR1;
      ICPR2 : t_NVIC_ICPR2;
      IPR   : t_IPRs;
   end record
      with volatile;

   for t_NVIC_periph use record
      ISER0 at 16#0# range 0 .. 31;
      ISER1 at 16#4# range 0 .. 31;
      ISER2 at 16#8# range 0 .. 31;
      ICER0 at 16#80# range 0 .. 31;
      ICER1 at 16#84# range 0 .. 31;
      ICER2 at 16#88# range 0 .. 31;
      ICPR0 at 16#180# range 0 .. 31;
      ICPR1 at 16#184# range 0 .. 31;
      ICPR2 at 16#188# range 0 .. 31;
      IPR   at 16#300# range 0 .. (8*81)-1;
   end record;

   NVIC : t_NVIC_periph
      with
         import, volatile, address => m4.layout.NVIC_BASE;

   -------------
   -- Methods --
   -------------

   function to_irq_number
     (intr : soc.interrupts.t_interrupt)
      return t_irq_index
   with
      inline,
      pre => intr >= soc.interrupts.INT_WWDG;

   procedure enable_irq
     (irq : in t_irq_index)
   with inline;

   procedure clear_pending_irq
     (irq : in t_irq_index)
   with inline;

end soc.nvic;
