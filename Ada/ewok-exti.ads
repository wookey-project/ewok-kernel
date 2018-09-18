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

with soc.exti;
with ewok.exported.gpios;

package ewok.exti
   with spark_mode => off
is

   exti_line_registered : array (soc.exti.t_exti_line_index) of boolean
      := (others => false);

   ---------------
   -- Functions --
   ---------------

   -- \brief initialize the EXTI module
   procedure init;


   -- \brief Disable a given line
   -- \returns 0 of EXTI line has been properly disabled, or non-null value
   procedure disable
     (ref : in  ewok.exported.gpios.t_gpio_ref);

   -- Enable (i.e. activate at EXTI and NVIC level) the EXTI line.
   -- This is done by calling soc_exti_enable() only. No generic call here.
   procedure enable
     (ref : in  ewok.exported.gpios.t_gpio_ref);

   -- Return true if EXTI line is already registered.
   function is_used
     (ref : ewok.exported.gpios.t_gpio_ref)
      return boolean;

   -- \brief Register a new EXTI line.
   -- Check that the EXTI line is not already registered.
   procedure register
     (conf     : in  ewok.exported.gpios.t_gpio_config_access;
      success  : out boolean);

end ewok.exti;

