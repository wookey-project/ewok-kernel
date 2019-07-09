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


package ewok.devices_shared
   with spark_mode => on
is

   type t_device_id is
     (ID_DEV_UNUSED,
      ID_DEV1,  ID_DEV2,  ID_DEV3,  ID_DEV4,  ID_DEV5,  ID_DEV6,
      ID_DEV7,  ID_DEV8,  ID_DEV9,  ID_DEV10, ID_DEV11, ID_DEV12,
      ID_DEV13, ID_DEV14, ID_DEV15, ID_DEV16, ID_DEV17, ID_DEV18);

   subtype t_registered_device_id is t_device_id range ID_DEV1 .. ID_DEV18;

end ewok.devices_shared;
