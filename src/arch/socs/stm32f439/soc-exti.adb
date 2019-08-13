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

with system;      use system;
with soc.rcc;


package body soc.exti
   with spark_mode => off
is

   procedure init
   is
   begin
      for line in t_exti_line_index'range loop
         clear_pending(line);
         disable(line);
      end loop;
      soc.rcc.RCC.APB2ENR.SYSCFGEN := true;
   end init;


   function is_line_pending
     (line : t_exti_line_index)
      return boolean
   is
      request : t_request;
   begin
      request := EXTI.PR.line(line);
      return (request = PENDING_REQUEST);
   end is_line_pending;


   procedure clear_pending
     (line : in t_exti_line_index)
   is
   begin
      EXTI.PR.line(line) := CLEAR_REQUEST;
   end clear_pending;


   procedure enable
     (line : in t_exti_line_index)
   is
   begin
      EXTI.IMR.line(line) := NOT_MASKED; -- interrupt is unmasked
   end enable;

   procedure disable
     (line : in t_exti_line_index)
   is
   begin
      EXTI.IMR.line(line) := MASKED; -- interrupt is masked
   end disable;


   function is_enabled (line : in t_exti_line_index)
      return boolean
   is
      mask : t_mask;
   begin
      mask := EXTI.IMR.line(line);
      return mask = NOT_MASKED;
   end;

end soc.exti;
