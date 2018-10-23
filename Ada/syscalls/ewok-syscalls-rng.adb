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


with ewok.tasks;        use ewok.tasks;
with types.c;
with c.kernel;
with ewok.sanitize;
with debug;
with ewok.perm;

package body ewok.syscalls.rng
   with spark_mode => off
is

   pragma warnings (off);

   function to_integer is new ada.unchecked_conversion
     (unsigned_16, Integer);

   pragma warnings (on);

   procedure sys_get_random
     (caller_id   : in  ewok.tasks_shared.t_task_id;
      params      : in out t_parameters;
      mode        : in  ewok.tasks_shared.t_task_mode)
   is
      length      : unsigned_16
         with address => params(1)'address;

      buffer      : types.c.c_string (1 .. to_integer(length))
         with address => to_address (params(0));

      ret         : Integer;

   begin

      -- Forbidden after end of task initialization
      if not is_init_done (caller_id) then
         goto ret_denied;
      end if;


      --
      -- Verifying parameters
      --

      if not ewok.sanitize.is_range_in_data_slot
               (to_system_address (buffer'address), types.to_unsigned_32(length), caller_id, mode)
      then
         debug.log (debug.WARNING, "[task" & ewok.tasks_shared.t_task_id'image (caller_id)
            & "] sys_get_random: value ("
            & system_address'image (to_system_address (buffer'address))
            & ") is not in caller space");
         goto ret_inval;
      end if;

      if length > 16
      then
         goto ret_inval;
      end if;

      --
      -- Verifying permissions
      --
      if not ewok.perm.ressource_is_granted
               (ewok.perm.PERM_RES_DEV_CRYPTO_USR, caller_id) and then
         not ewok.perm.ressource_is_granted
               (ewok.perm.PERM_RES_DEV_CRYPTO_CFG, caller_id) and then
         not ewok.perm.ressource_is_granted
               (ewok.perm.PERM_RES_DEV_CRYPTO_FULL, caller_id)
      then
         debug.log (debug.WARNING, "sys_get_random(): permission not granted");
         goto ret_denied;
      end if;


      -- Here we call the kernel random source which handle the potential
      -- random source errors (case of harware random sources such as TRNG IP)
      ret := c.kernel.get_random(buffer, length);

      if ret /= 0
      then
         -- INFO: there is some time when the generated random
         -- content may be weak for various reason due to arch-specific
         -- constraint. In this case, the return value is set to
         -- busy. Please check this return value when using this
         -- syscall to avoid using weak random content
         debug.log (debug.WARNING, "sys_get_random(): weak seed");
         goto ret_busy;
      end if;

      set_return_value (caller_id, mode, SYS_E_DONE);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   <<ret_inval>>
      set_return_value (caller_id, mode, SYS_E_INVAL);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   <<ret_busy>>
      set_return_value (caller_id, mode, SYS_E_BUSY);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   <<ret_denied>>
      set_return_value (caller_id, mode, SYS_E_DENIED);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   end sys_get_random;

end ewok.syscalls.rng;
