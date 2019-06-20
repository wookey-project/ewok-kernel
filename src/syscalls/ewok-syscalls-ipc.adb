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


with ada.unchecked_conversion;

with ewok.ipc;          use ewok.ipc;
with ewok.tasks;        use ewok.tasks;
with ewok.tasks_shared; use ewok.tasks_shared;
with ewok.sanitize;
with ewok.perm;
with ewok.sleep;
with ewok.debug;
with ewok.mpu;
with types.c;           use types.c;


package body ewok.syscalls.ipc
   with spark_mode => off
is

   --pragma debug_policy (IGNORE);

   package TSK renames ewok.tasks;


   procedure svc_ipc_do_recv
     (caller_id   : in ewok.tasks_shared.t_task_id;
      params      : in t_parameters;
      blocking    : in boolean;
      mode        : in ewok.tasks_shared.t_task_mode)
   is

      ep_id       : ewok.ipc.t_extended_endpoint_id;

      ----------------
      -- Parameters --
      ----------------

      -- Who is the sender ?
      expected_sender : ewok.ipc.t_extended_task_id
         with address => to_address (params(1));

      -- Listening to any id ?
      listen_any  : boolean;

      -- Listening to a specific id ?
      id_sender   : ewok.tasks_shared.t_task_id;

      -- Buffer size
      size  : unsigned_8
         with address => to_address (params(2));

      -- Input buffer
      buf   : c_buffer (1 .. unsigned_32 (size))
         with address => to_address (params(3));

   begin

      --if expected_sender = ewok.ipc.ANY_APP then
      --   pragma DEBUG (debug.log (debug.DEBUG, "recv(): "
      --      & TSK.tasks_list(caller_id).name & " <- ANY");
      --else
      --   pragma DEBUG (debug.log (debug.DEBUG, "recv(): "
      --      & TSK.tasks_list(caller_id).name & " <- "
      --      & TSK.tasks_list(ewok.ipc.to_task_id(expected_sender)).name);
      --end if;

      --------------------------
      -- Verifying parameters --
      --------------------------

      if mode /= TASK_MODE_MAINTHREAD then
         pragma DEBUG (debug.log (debug.ERROR,
            TSK.tasks_list(caller_id).name
            & ": recv(): IPCs in ISR mode not allowed!"));
         goto ret_denied;
      end if;

      if not expected_sender'valid then
         pragma DEBUG (debug.log (debug.ERROR,
            TSK.tasks_list(caller_id).name
            & ": recv(): invalid id_sender"));
         goto ret_inval;
      end if;

      -- Task initialization is complete ?
      if not TSK.is_init_done (caller_id) then
         pragma DEBUG (debug.log (debug.ERROR,
            TSK.tasks_list(caller_id).name
            & ": recv(): initialization not completed"));
         goto ret_denied;
      end if;

      -- Does &size is in the caller address space ?
      if not ewok.sanitize.is_word_in_data_slot
               (to_system_address (size'address), caller_id, mode)
      then
         pragma DEBUG (debug.log (debug.ERROR,
            TSK.tasks_list(caller_id).name
            & ": recv(): 'size' parameter not in task's address space"));
         goto ret_inval;
      end if;

      -- Does &expected_sender is in the caller address space ?
      if not ewok.sanitize.is_word_in_data_slot
               (to_system_address (expected_sender'address), caller_id, mode)
      then
         pragma DEBUG (debug.log (debug.ERROR,
            TSK.tasks_list(caller_id).name
            & ": recv(): 'expected_sender' parameter not in task's address space"));
         goto ret_inval;
      end if;

      -- Does &buf is in the caller address space ?
      if not ewok.sanitize.is_range_in_data_slot
               (to_system_address (buf'address), unsigned_32 (size), caller_id, mode)
      then
         pragma DEBUG (debug.log (debug.ERROR,
            TSK.tasks_list(caller_id).name
            & ": recv(): 'buffer' parameter not in task's address space"));
         goto ret_inval;
      end if;

      -- The expected sender might be a particular task or any of them
      if expected_sender = ewok.ipc.ANY_APP then
         listen_any  := true;
      else
         id_sender   := ewok.ipc.to_task_id (expected_sender);
         listen_any  := false;
      end if;

      -- When the sender is a task, we have to do some additional checks
      if not listen_any then

         -- Is the sender is an existing user task?
         if not TSK.is_real_user (id_sender) then
            pragma DEBUG (debug.log (debug.ERROR,
               TSK.tasks_list(caller_id).name
               & ": recv(): invalid id_sender"));
            goto ret_inval;
         end if;

         -- Defensive programming test: should *never* be true
         if TSK.get_state (id_sender, TASK_MODE_MAINTHREAD)
               = TASK_STATE_EMPTY
         then
            raise program_error;
         end if;

         -- A task can't send a message to itself
         if caller_id = id_sender then
            pragma DEBUG (debug.log (debug.ERROR,
               TSK.tasks_list(caller_id).name
               & ": recv(): sender and receiver are the same"));
            goto ret_inval;
         end if;

         -- Is the sender in the same domain?
#if CONFIG_KERNEL_DOMAIN
         if not ewok.perm.is_same_domain (id_sender, caller_id) then
            pragma DEBUG (debug.log (debug.ERROR,
               TSK.tasks_list(caller_id).name
               & ": recv(): sender's domain not granted"));
            goto ret_denied;
         end if;
#end if;

         -- Are ipc granted?
         if not ewok.perm.ipc_is_granted (id_sender, caller_id) then
            pragma DEBUG (debug.log (debug.ERROR,
               TSK.tasks_list(caller_id).name
               & ": recv(): not granted to listen task "
               & TSK.tasks_list(id_sender).name));
            goto ret_denied;
         end if;

      end if;

      ------------------------------
      -- Defining an IPC EndPoint --
      ------------------------------

      ep_id := ID_ENDPOINT_UNUSED;

      -- Special case: listening to ANY_APP and already have a pending message
      if listen_any then

         for id of TSK.tasks_list(caller_id).ipc_endpoint_id loop
            if id /= ID_ENDPOINT_UNUSED
               and then
               ewok.ipc.ipc_endpoints(id).state = ewok.ipc.WAIT_FOR_RECEIVER
               and then
               ewok.ipc.to_task_id (ewok.ipc.ipc_endpoints(id).to) = caller_id
            then
               ep_id := id;
               exit;
            end if;
         end loop;

      -- Special case: listening to a given sender and already have a pending
      -- message
      else

         declare
            id : constant ewok.ipc.t_extended_endpoint_id
               := TSK.tasks_list(caller_id).ipc_endpoint_id(id_sender);
         begin
            if id /= ID_ENDPOINT_UNUSED
               and then
               ewok.ipc.ipc_endpoints(id).state = ewok.ipc.WAIT_FOR_RECEIVER
               and then
               ewok.ipc.to_task_id (ewok.ipc.ipc_endpoints(id).to) = caller_id
            then
               ep_id := id;
            end if;
         end;

      end if;

      -------------------------
      -- Reading the message --
      -------------------------

      -- No pending message to read: we terminate here
      if ep_id = ID_ENDPOINT_UNUSED then

         -- Wake up idle senders
         if not listen_any and then
            TSK.get_state (id_sender, TASK_MODE_MAINTHREAD) = TASK_STATE_IDLE
         then
            TSK.set_state
              (id_sender, TASK_MODE_MAINTHREAD, TASK_STATE_RUNNABLE);
         end if;

         -- Receiver is blocking until it receives a message or it returns
         -- E_SYS_BUSY
         if blocking then
            TSK.set_state
              (caller_id, TASK_MODE_MAINTHREAD, TASK_STATE_IPC_RECV_BLOCKED);
            return;
         else
            goto ret_busy;
         end if;

      end if;

      -- The syscall returns sender's ID
      expected_sender   := ewok.ipc.ipc_endpoints(ep_id).from;
      id_sender         := ewok.ipc.to_task_id (expected_sender);

      -- Defensive programming test: should *never* happen
      if not TSK.is_real_user (id_sender) then
         raise program_error;
      end if;

      -- Copying the message in the receiver's buffer
      if ewok.ipc.ipc_endpoints(ep_id).size > size then
         pragma DEBUG (debug.log (debug.ERROR,
            TSK.tasks_list(caller_id).name
            & ": recv(): IPC message overflows, buffer is too small"));
         goto ret_inval;
      end if;

      -- Returning the data size
      size := ewok.ipc.ipc_endpoints(ep_id).size;

      -- Copying data
      -- Note: we don't use 'first attribute. By convention, array indexes
      --       begin with '1' value
      buf(1 .. unsigned_32 (size)) := ewok.ipc.ipc_endpoints(ep_id).data(1 .. unsigned_32 (size));

      -- The EndPoint is ready for another use
      ewok.ipc.ipc_endpoints(ep_id).state := READY;
      ewok.ipc.ipc_endpoints(ep_id).size  := 0;

      -- Free sender from it's blocking state
      case TSK.get_state (id_sender, TASK_MODE_MAINTHREAD) is

         when TASK_STATE_IPC_WAIT_ACK      =>

            -- The kernel need to update sender syscall's return value, but
            -- as we are currently managing the receiver's syscall, sender's
            -- data region in memory can not be accessed (even by the kernel).
            -- The following temporary open the access to every task's data
            -- region, perform the writing, and then restore the MPU.
            ewok.mpu.enable_unrestricted_kernel_access;
            set_return_value (id_sender, TASK_MODE_MAINTHREAD, SYS_E_DONE);
            ewok.mpu.disable_unrestricted_kernel_access;

            TSK.set_state
              (id_sender, TASK_MODE_MAINTHREAD, TASK_STATE_RUNNABLE);

         when TASK_STATE_IPC_SEND_BLOCKED  =>
            -- The sender will reexecute the SVC instruction to fulfill its syscall
            TSK.set_state
              (id_sender, TASK_MODE_MAINTHREAD, TASK_STATE_FORCED);

            TSK.tasks_list(id_sender).ctx.frame_a.all.PC :=
               TSK.tasks_list(id_sender).ctx.frame_a.all.PC - 2;
         when others =>
            null;
      end case;

      set_return_value (caller_id, mode, SYS_E_DONE);
      TSK.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   <<ret_inval>>
      set_return_value (caller_id, mode, SYS_E_INVAL);
      TSK.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   <<ret_busy>>
      set_return_value (caller_id, mode, SYS_E_BUSY);
      TSK.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   <<ret_denied>>
      set_return_value (caller_id, mode, SYS_E_DENIED);
      TSK.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;
   end svc_ipc_do_recv;


   procedure svc_ipc_do_send
     (caller_id   : in     ewok.tasks_shared.t_task_id;
      params      : in out t_parameters;
      blocking    : in     boolean;
      mode        : in     ewok.tasks_shared.t_task_mode)
   is

      type t_task_access is access all TSK.t_task;
      receiver_a  : t_task_access;
      ep_id       : ewok.ipc.t_extended_endpoint_id;
      ok          : boolean;

      ----------------
      -- Parameters --
      ----------------

      -- Who is the receiver ?
      id_receiver : ewok.tasks_shared.t_task_id
         with address => params(1)'address;

      -- Buffer size
      size  : unsigned_8
         with address => params(2)'address;

      -- Output buffer
      buf   : c_buffer (1 .. unsigned_32 (size))
         with address => to_address (params(3));

   begin

      --pragma DEBUG (debug.log (debug.DEBUG, "send(): "
      --   & TSK.tasks_list(caller_id).name & " -> "
      --   & TSK.tasks_list(id_receiver).name);

      --------------------------
      -- Verifying parameters --
      --------------------------

      if mode /= TASK_MODE_MAINTHREAD then
         pragma DEBUG (debug.log (debug.ERROR,
            TSK.tasks_list(caller_id).name
            & ": send(): making IPCs while in ISR mode is not allowed!"));
         goto ret_denied;
      end if;

      if not id_receiver'valid then
         pragma DEBUG (debug.log (debug.ERROR,
            TSK.tasks_list(caller_id).name
            & ": send(): invalid id_receiver"));
         goto ret_inval;
      end if;

      -- Task initialization is complete ?
      if not is_init_done (caller_id) then
         pragma DEBUG (debug.log (debug.ERROR,
            TSK.tasks_list(caller_id).name
            & ": send(): initialization not completed"));
         goto ret_denied;
      end if;

      -- Does &buf is in the caller address space ?
      if not ewok.sanitize.is_range_in_data_slot
               (to_unsigned_32 (buf'address), unsigned_32 (size), caller_id, mode)
      then
         pragma DEBUG (debug.log (debug.ERROR,
            TSK.tasks_list(caller_id).name
            & ": send(): 'buffer' not in caller space"));
         goto ret_inval;
      end if;

      -- Verifying that the receiver id corresponds to a user application
      if not TSK.is_real_user (id_receiver) then
         pragma DEBUG (debug.log (debug.ERROR,
            TSK.tasks_list(caller_id).name
            & ": send(): id_receiver must be a user task"));
         goto ret_inval;
      end if;

      receiver_a := TSK.tasks_list(id_receiver)'access;

      -- Defensive programming test: should *never* be true
      if TSK.get_state (id_receiver, TASK_MODE_MAINTHREAD)
            = TASK_STATE_EMPTY
      then
         raise program_error;
      end if;

      -- A task can't send a message to itself
      if caller_id = id_receiver then
         pragma DEBUG (debug.log (debug.ERROR,
            TSK.tasks_list(caller_id).name
            & ": send(): receiver and sender are the same"));
         goto ret_inval;
      end if;

      -- Is size valid ?
      if size > ewok.ipc.MAX_IPC_MSG_SIZE then
         pragma DEBUG (debug.log (debug.ERROR,
            TSK.tasks_list(caller_id).name
            & ": send(): invalid size"));
         goto ret_inval;
      end if;

      --
      -- Verifying permissions
      --

#if CONFIG_KERNEL_DOMAIN
      if not ewok.perm.is_same_domain (id_receiver, caller_id) then
         pragma DEBUG (debug.log (debug.ERROR,
            TSK.tasks_list(caller_id).name
            & ": send() to "
            & TSK.tasks_list(id_receiver).name
            & ": domain not granted"));
         goto ret_denied;
      end if;
#end if;

      if not ewok.perm.ipc_is_granted (caller_id, id_receiver) then
         pragma DEBUG (debug.log (debug.ERROR,
            TSK.tasks_list(caller_id).name
            & ": send() to "
            & TSK.tasks_list(id_receiver).name
            & " not granted"));
         goto ret_denied;
      end if;

      ------------------------------
      -- Defining an IPC EndPoint --
      ------------------------------

      ep_id := ID_ENDPOINT_UNUSED;

      -- Creating a new EndPoint between the sender and the receiver
      if TSK.tasks_list(caller_id).ipc_endpoint_id(id_receiver) = ID_ENDPOINT_UNUSED
      then

         -- Defensive programming test: should *never* happen
         if receiver_a.all.ipc_endpoint_id(caller_id) /= ID_ENDPOINT_UNUSED then
            raise program_error;
         end if;

         ewok.ipc.get_endpoint (ep_id, ok);
         if not ok then
            -- FIXME
            debug.panic ("send(): EndPoint starvation !O_+");
         end if;

         TSK.tasks_list(caller_id).ipc_endpoint_id(id_receiver) := ep_id;
         TSK.tasks_list(id_receiver).ipc_endpoint_id(caller_id) := ep_id;

      else
         ep_id := TSK.tasks_list(caller_id).ipc_endpoint_id(id_receiver);
      end if;

      -----------------------
      -- Sending a message --
      -----------------------

      -- Wake up idle receivers
      if ewok.sleep.is_sleeping (id_receiver) then
         ewok.sleep.try_waking_up (id_receiver);
      elsif receiver_a.all.state = TASK_STATE_IDLE then
         TSK.set_state
           (id_receiver, TASK_MODE_MAINTHREAD, TASK_STATE_RUNNABLE);
      end if;

      -- The receiver has already a pending message and the endpoint is already
      -- in use.
      if ewok.ipc.ipc_endpoints(ep_id).state = ewok.ipc.WAIT_FOR_RECEIVER and
         ewok.ipc.to_task_id (ewok.ipc.ipc_endpoints(ep_id).to) = id_receiver
      then
         if blocking then
            TSK.set_state
              (caller_id, TASK_MODE_MAINTHREAD, TASK_STATE_IPC_SEND_BLOCKED);
#if CONFIG_IPC_SCHED_VIOL
            if TSK.get_state (id_receiver, TASK_MODE_MAINTHREAD)
                  = TASK_STATE_RUNNABLE
               or
               TSK.get_state (id_receiver, TASK_MODE_MAINTHREAD)
                  = TASK_STATE_IDLE
            then
               TSK.set_state
                 (id_receiver, TASK_MODE_MAINTHREAD, TASK_STATE_FORCED);
            end if;
#end if;
            return;
         else
            goto ret_busy;
         end if;
      end if;

      if ewok.ipc.ipc_endpoints(ep_id).state /= ewok.ipc.READY then
         pragma DEBUG (debug.log (debug.ERROR,
            TSK.tasks_list(caller_id).name
            & ": send(): invalid endpoint state - maybe a dead lock"));
         goto ret_denied;
      end if;

      ewok.ipc.ipc_endpoints(ep_id).from := ewok.ipc.to_ext_task_id (caller_id);
      ewok.ipc.ipc_endpoints(ep_id).to   := ewok.ipc.to_ext_task_id (id_receiver);

      -- We copy the message in the IPC buffer
      -- Note: we don't use 'first attribute. By convention, array indexes
      --       begin with '1' value
      ewok.ipc.ipc_endpoints(ep_id).size := size;
      ewok.ipc.ipc_endpoints(ep_id).data(1 .. unsigned_32 (size)) := buf(1 .. unsigned_32 (size));

      -- Adjusting the EndPoint state
      ewok.ipc.ipc_endpoints(ep_id).state := ewok.ipc.WAIT_FOR_RECEIVER;

      -- If the receiver was blocking, it can be 'freed' from its blocking
      -- state.
      if TSK.get_state (id_receiver, TASK_MODE_MAINTHREAD)
            = TASK_STATE_IPC_RECV_BLOCKED
      then
         -- The receiver will reexecute the SVC instruction to fulfill its syscall
         TSK.set_state
           (id_receiver, TASK_MODE_MAINTHREAD, TASK_STATE_FORCED);

         -- Unrestrict kernel access to memory to change a value located
         -- in the receiver's stack frame
         ewok.mpu.enable_unrestricted_kernel_access;
         receiver_a.all.ctx.frame_a.all.PC :=
            receiver_a.all.ctx.frame_a.all.PC - 2;
         ewok.mpu.disable_unrestricted_kernel_access;
      end if;

      if blocking then
         TSK.set_state
           (caller_id, TASK_MODE_MAINTHREAD, TASK_STATE_IPC_WAIT_ACK);
#if CONFIG_IPC_SCHED_VIOL
         if receiver_a.all.state = TASK_STATE_RUNNABLE or
            receiver_a.all.state = TASK_STATE_IDLE
         then
            TSK.set_state
              (id_receiver, TASK_MODE_MAINTHREAD, TASK_STATE_FORCED);
         end if;
#end if;
         return;
      else
         set_return_value (caller_id, mode, SYS_E_DONE);
         TSK.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
         return;
      end if;

   <<ret_inval>>
      set_return_value (caller_id, mode, SYS_E_INVAL);
      TSK.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   <<ret_busy>>
      set_return_value (caller_id, mode, SYS_E_BUSY);
      TSK.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   <<ret_denied>>
      set_return_value (caller_id, mode, SYS_E_DENIED);
      TSK.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   end svc_ipc_do_send;

end ewok.syscalls.ipc;
