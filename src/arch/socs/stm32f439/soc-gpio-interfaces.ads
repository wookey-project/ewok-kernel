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

with types.c;

package soc.gpio.interfaces
   with spark_mode => off
is

   function configure
     (port     : in  unsigned_8;
      pin      : in  unsigned_8;
      mode     : in  t_pin_mode;
      otype    : in  t_pin_output_type;
      ospeed   : in  t_pin_output_speed;
      pupd     : in  t_pin_pupd;
      af       : in  t_pin_alt_func)
      return types.c.t_retval
   with
      convention     => c,
      export         => true,
      external_name  => "soc_gpio_configure";

end soc.gpio.interfaces;

