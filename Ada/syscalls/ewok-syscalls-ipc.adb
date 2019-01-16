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
with ewok.softirq;
with ewok.sched;
with types.c;           use types.c;
--with m4.cpu;
with debug;


package body ewok.syscalls.ipc
   with spark_mode => off
is

   procedure ipc_do_recv
     (caller_id   : in ewok.tasks_shared.t_task_id;
      params      : in t_parameters;
      blocking    : in boolean;
      mode        : in ewok.tasks_shared.t_task_mode)
   is

      ep          : ewok.ipc.t_endpoint_access;
      sender_a    : ewok.tasks.t_task_access;

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

--      declare
--         u : unsigned_8
--            with address => to_address (params(1));
--      begin
--         debug.log (debug.ERROR, "debug: ipc_do_recv(): task"
--            & ewok.tasks.tasks_list(caller_id).name &
--            & " <- " & unsigned_8'image (u));
--      end;

      --------------------------
      -- Verifying parameters --
      --------------------------

      if mode /= TASK_MODE_MAINTHREAD then
#if CONFIG_DEBUG_ADA_IPC
         debug.log (debug.ERROR, "[task" & ewok.tasks_shared.t_task_id'image (caller_id)
            & "] ipc_do_recv(): making IPCs while in ISR mode is not allowed!");
#end if;
         goto ret_denied;
      end if;

      if not expected_sender'valid then
         debug.log (debug.ERROR, "[task"
            & ewok.tasks_shared.t_task_id'image (caller_id)
            & "] ipc_do_recv(): invalid id_sender ("
            & unsigned_32'image (params(1)) & ")");
      end if;

      -- Task initialization is complete ?
      if not is_init_done (caller_id) then
#if CONFIG_DEBUG_ADA_IPC
         debug.log (debug.ERROR, "[task" & ewok.tasks_shared.t_task_id'image (caller_id)
            & "] ipc_do_recv(): initialization not completed");
#end if;
         goto ret_denied;
      end if;

      -- Does &size is in the caller address space ?
      if not ewok.sanitize.is_word_in_data_slot
               (to_system_address (size'address), caller_id, mode)
      then
#if CONFIG_DEBUG_ADA_IPC
         debug.log (debug.ERROR, "[task" & ewok.tasks_shared.t_task_id'image (caller_id)
            & "] ipc_do_recv(): size (" & unsigned_8'image (size)
            & ") is not in caller space");
#end if;
         goto ret_inval;
      end if;

      -- Does &expected_sender is in the caller address space ?
      if not ewok.sanitize.is_word_in_data_slot
               (to_system_address (expected_sender'address), caller_id, mode)
      then
#if CONFIG_DEBUG_ADA_IPC
         debug.log (debug.ERROR, "[task"
            & ewok.tasks_shared.t_task_id'image (caller_id)
            & "] ipc_do_recv(): expected_sender ("
            & ewok.ipc.t_extended_task_id'image (expected_sender)
            & ") is not in caller space");
#end if;
         goto ret_inval;
      end if;

      -- Does &buf is in the caller address space ?
      if not ewok.sanitize.is_range_in_data_slot
               (to_system_address (buf'address), unsigned_32 (size), caller_id, mode)
      then
#if CONFIG_DEBUG_ADA_IPC
         debug.log (debug.ERROR, "[task"
            & ewok.tasks_shared.t_task_id'image (caller_id)
            & "] ipc_do_recv(): buffer ("
            & system_address'image (to_system_address (buf'address))
            & ") is not in caller space");
#end if;
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
         if not ewok.tasks.is_real_user (id_sender) then
#if CONFIG_DEBUG_ADA_IPC
            debug.log (debug.ERROR, "[task"
               & ewok.tasks_shared.t_task_id'image (caller_id)
               & "] ipc_do_recv(): invalid id_sender ("
               & ewok.tasks_shared.t_task_id'image (id_sender)
               & ")");
#end if;
            goto ret_inval;
         end if;

         -- Defensive programming test: should *never* be true
         if ewok.tasks.get_state (id_sender, TASK_MODE_MAINTHREAD)
               = TASK_STATE_EMPTY
         then
            raise program_error;
         end if;

         -- A task can't send a message to itself
         if caller_id = id_sender then
#if CONFIG_DEBUG_ADA_IPC
            debug.log (debug.ERROR, "[task"
               & ewok.tasks_shared.t_task_id'image (caller_id)
               & "] ipc_do_recv(): id_sender ("
               & ewok.tasks_shared.t_task_id'image (id_sender)
               & ") - same as caller->id");
#end if;
            goto ret_inval;
         end if;

         -- Is the sender in the same domain?
#if CONFIG_KERNEL_DOMAIN
	      if not ewok.perm.is_same_domain (id_sender, caller_id) then
	         debug.log (debug.ERROR, "[task"
               & ewok.tasks_shared.t_task_id'image (caller_id)
	            & "] ipc_do_recv(): sender's ("
	            & ewok.tasks_shared.t_task_id'image (id_sender)
	            & ") domain not granted");
	         goto ret_denied;
	      end if;
#end if;

         -- Are ipc granted?
         if not ewok.perm.ipc_is_granted (id_sender, caller_id) then
#if CONFIG_DEBUG_ADA_IPC
	         debug.log (debug.ERROR, "[task"
               & ewok.tasks_shared.t_task_id'image (caller_id)
	            & "] ipc_do_recv(): not granted to listen task "
	            & ewok.tasks_shared.t_task_id'image (id_sender));
#end if;
            goto ret_denied;
         end if;

         -- Checks are ok
         sender_a := ewok.tasks.get_task (id_sender);

      end if;

      ------------------------------
      -- Defining an IPC EndPoint --
      ------------------------------

      ep := NULL;

      -- Special case: listening to ANY_APP and already have a pending message
      if listen_any then

         for i in ewok.tasks.tasks_list(caller_id).ipc_endpoints'range loop
            if ewok.tasks.tasks_list(caller_id).ipc_endpoints(i) /= NULL
               and then
               ewok.tasks.tasks_list(caller_id).ipc_endpoints(i).state
                  = ewok.ipc.WAIT_FOR_RECEIVER
               and then
               ewok.ipc.to_task_id
                 (ewok.tasks.tasks_list(caller_id).ipc_endpoints(i).to)
                     = caller_id
            then
               ep := ewok.tasks.tasks_list(caller_id).ipc_endpoints(i);
               exit;
            end if;
         end loop;

      -- Special case: listening to a given sender and already have a pending
      -- message
      else

         if ewok.tasks.tasks_list(caller_id).ipc_endpoints(id_sender) /= NULL
            and then
            ewok.tasks.tasks_list(caller_id).ipc_endpoints(id_sender).state
               = ewok.ipc.WAIT_FOR_RECEIVER
            and then
            ewok.ipc.to_task_id (ewok.tasks.tasks_list(caller_id).ipc_endpoints(id_sender).to)
               = caller_id
         then
            ep := ewok.tasks.tasks_list(caller_id).ipc_endpoints(id_sender);
         end if;

      end if;

      -------------------------
      -- Reading the message --
      -------------------------

      --
      -- No pending message to read: we terminate here
      --

      if ep = NULL then

         -- Waking up idle senders
         if not listen_any and then
            ewok.tasks.get_state (sender_a.all.id, TASK_MODE_MAINTHREAD)
               = TASK_STATE_IDLE
         then
            ewok.tasks.set_state
              (sender_a.all.id, TASK_MODE_MAINTHREAD, TASK_STATE_RUNNABLE);
         end if;

         -- Receiver is blocking until it receives a message or it returns
         -- E_SYS_BUSY
         if blocking then
            ewok.tasks.set_state(caller_id,
                                 TASK_MODE_MAINTHREAD,
                                 TASK_STATE_IPC_RECV_BLOCKED);
            return;
         else
            goto ret_busy;
         end if;

      end if;

      -- The syscall returns the sender ID
      expected_sender   := ep.all.from;
      id_sender         := ewok.ipc.to_task_id (ep.all.from);

      -- Defensive programming test: should *never* happen
      if not ewok.tasks.is_real_user (id_sender) then
         raise program_error;
      end if;

      sender_a := ewok.tasks.get_task (id_sender);

      -- Copying the message in the receiver's buffer
      if ep.all.size > size then
#if CONFIG_DEBUG_ADA_IPC
         debug.log (debug.ERROR, "ipc_do_recv(): IPC message overflows: receiver's ("
            & ewok.tasks_shared.t_task_id'image (caller_id)
            & ") buffer is too small ("
            & unsigned_8'image (ep.all.size) & ">"
            & unsigned_8'image (size) & ")");
#end if;
         goto ret_inval;
      end if;

      -- Returning the data size
      size := ep.all.size;

      -- Copying data
      -- Note: we don't use 'first attribute. By convention, array indexes
      --       begin with '1' value
      buf(1 .. unsigned_32 (size)) := ep.all.data(1 .. unsigned_32 (size));

      -- The EndPoint is ready for another use
      ep.all.state := ewok.ipc.READY;
      ep.all.size  := 0;

      -- Free sender from it's blocking state
      case ewok.tasks.get_state (sender_a.all.id, TASK_MODE_MAINTHREAD) is

         when TASK_STATE_IPC_WAIT_ACK      =>
            set_return_value
              (sender_a.all.id, TASK_MODE_MAINTHREAD, SYS_E_DONE);
            ewok.tasks.set_state
              (sender_a.all.id, TASK_MODE_MAINTHREAD, TASK_STATE_RUNNABLE);

         when TASK_STATE_IPC_SEND_BLOCKED  =>
            sender_a.all.state := TASK_STATE_SVC_BLOCKED;
            ewok.softirq.push_syscall (sender_a.all.id);
            ewok.sched.request_schedule;
         when others =>
            null;
      end case;

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
   end ipc_do_recv;


   procedure ipc_do_send
     (caller_id   : in     ewok.tasks_shared.t_task_id;
      params      : in out t_parameters;
      blocking    : in     boolean;
      mode        : in     ewok.tasks_shared.t_task_mode)
   is

      ep             : ewok.ipc.t_endpoint_access;
      receiver_a     : ewok.tasks.t_task_access;
      ok             : boolean;

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

--      debug.log (debug.ERROR, "debug: ipc_do_send(): task"
--         & ewok.tasks_shared.t_task_id'image (caller_id)
--         & " -> task" & unsigned_32'image (params(1)));

      --------------------------
      -- Verifying parameters --
      --------------------------

      if mode /= TASK_MODE_MAINTHREAD then
#if CONFIG_DEBUG_ADA_IPC
         debug.log (debug.ERROR, "[task" & ewok.tasks_shared.t_task_id'image (caller_id)
            & "] ipc_do_send(): making IPCs while in ISR mode is not allowed!");
#end if;
         goto ret_denied;
      end if;

      if not id_receiver'valid then
         debug.panic ("[task"
            & ewok.tasks_shared.t_task_id'image (caller_id)
            & "] ipc_do_send(): invalid id_receiver ("
            & unsigned_32'image (params(1)) & ")");
      end if;

      -- Task initialization is complete ?
      if not is_init_done (caller_id) then
#if CONFIG_DEBUG_ADA_IPC
         debug.log (debug.ERROR, "[task"
            & ewok.tasks_shared.t_task_id'image (caller_id)
            & "] ipc_do_send(): initialization not completed");
#end if;
         goto ret_denied;
      end if;

      -- Does &buf is in the caller address space ?
      if not ewok.sanitize.is_range_in_data_slot
               (to_unsigned_32 (buf'address), unsigned_32 (size), caller_id, mode)
      then
#if CONFIG_DEBUG_ADA_IPC
         debug.log (debug.ERROR, "[task"
            & ewok.tasks_shared.t_task_id'image (caller_id)
            & "] ipc_do_send(): buffer ("
            & system_address'image (to_system_address (buf'address))
            & ") is not in caller space");
#end if;
         goto ret_inval;
      end if;

      -- Verifying that the receiver id corresponds to a user application
      if not ewok.tasks.is_real_user (id_receiver) then
#if CONFIG_DEBUG_ADA_IPC
         debug.log (debug.ERROR, "[task"
            & ewok.tasks_shared.t_task_id'image (caller_id)
            & "] ipc_do_send(): task "
            & unsigned_32'image (params(1))
            & " is not a user task");
#end if;
         goto ret_inval;
      end if;

      receiver_a := ewok.tasks.get_task (id_receiver);

      -- Defensive programming test: should *never* be true
      if ewok.tasks.get_state (id_receiver, TASK_MODE_MAINTHREAD)
            = TASK_STATE_EMPTY
      then
         raise program_error;
      end if;

      -- A task can't send a message to itself
      if caller_id = id_receiver then
#if CONFIG_DEBUG_ADA_IPC
         debug.log (debug.ERROR, "[task"
            & ewok.tasks_shared.t_task_id'image (caller_id)
            & "] ipc_do_send(): invalid id_receiver ("
            & ewok.tasks_shared.t_task_id'image (id_receiver)
            & ") - same as caller->id");
#end if;
         goto ret_inval;
      end if;

      -- Is size valid ?
      if size > ewok.ipc.MAX_IPC_MSG_SIZE then
#if CONFIG_DEBUG_ADA_IPC
         debug.log (debug.ERROR, "[task"
            & ewok.tasks_shared.t_task_id'image (caller_id)
            & "] invalid size (" & unsigned_8'image (size) & ")");
#end if;
         goto ret_inval;
      end if;

      --
      -- Verifying permissions
      --

#if CONFIG_KERNEL_DOMAIN
      if not ewok.perm.is_same_domain (id_receiver, caller_id) then
         debug.log (debug.ERROR, "[task"
            & ewok.tasks_shared.t_task_id'image (caller_id)
            & "] ipc_do_send(): receiver's ("
            & ewok.tasks_shared.t_task_id'image (id_receiver)
            & ") domain not granted");
         goto ret_denied;
      end if;
#end if;

      if not ewok.perm.ipc_is_granted (caller_id, id_receiver) then
#if CONFIG_DEBUG_ADA_IPC
         debug.log (debug.ERROR, "[task"
            & ewok.tasks_shared.t_task_id'image (caller_id)
	         & "] ipc_do_send() to "
            & ewok.tasks_shared.t_task_id'image (id_receiver)
            & " not granted");
#end if;
         goto ret_denied;
      end if;

      ------------------------------
      -- Defining an IPC EndPoint --
      ------------------------------

      ep := NULL;

      -- Creating a new EndPoint between the sender and the receiver
      if ewok.tasks.tasks_list(caller_id).ipc_endpoints(id_receiver) = NULL
      then

         -- Defensive programming test: should *never* happen
         if receiver_a.all.ipc_endpoints(caller_id) /= NULL then
            raise program_error;
         end if;

         ewok.ipc.get_endpoint (ep, ok);
         if not ok then
            debug.panic ("ipc_do_send(): EndPoint starvation !O_+");
         end if;

         ewok.tasks.tasks_list(caller_id).ipc_endpoints(id_receiver)         := ep;
         receiver_a.all.ipc_endpoints(caller_id)   := ep;

      else
         ep := ewok.tasks.tasks_list(caller_id).ipc_endpoints(id_receiver);
      end if;

      -----------------------
      -- Sending a message --
      -----------------------

      -- Wake up idle receivers
      if ewok.sleep.is_sleeping (receiver_a.id) then
         ewok.sleep.try_waking_up (receiver_a.id);
      elsif receiver_a.all.state = TASK_STATE_IDLE then
         receiver_a.all.state := TASK_STATE_RUNNABLE;
      end if;

      -- The receiver has already a pending message and the endpoint is already
      -- in use.
      if ep.all.state = ewok.ipc.WAIT_FOR_RECEIVER and
         ewok.ipc.to_task_id (ep.all.to) = receiver_a.all.id
      then
         if blocking then
            ewok.tasks.set_state
              (caller_id, TASK_MODE_MAINTHREAD, TASK_STATE_IPC_SEND_BLOCKED);
#if CONFIG_IPC_SCHED_VIOL
            if ewok.tasks.get_state (receiver_a.all.id, TASK_MODE_MAINTHREAD)
                  = TASK_STATE_RUNNABLE
               or
               ewok.tasks.get_tate (receiver_a.all.id, TASK_MODE_MAINTHREAD)
                  = TASK_STATE_IDLE
            then
               ewok.tasks.set_state
                 (receiver_a.all.id, TASK_MODE_MAINTHREAD, TASK_STATE_FORCED);
            end if;
#end if;
            return;
         else
            goto ret_busy;
         end if;
      end if;

      if ep.all.state /= ewok.ipc.READY then
         debug.log ("[task"
            & ewok.tasks_shared.t_task_id'image (caller_id)
	         & "] ipc_do_send(): invalid endpoint state - maybe a dead lock");
         goto ret_denied;
      end if;

      ep.all.from := ewok.ipc.to_ext_task_id (caller_id);
      ep.all.to   := ewok.ipc.to_ext_task_id (receiver_a.all.id);

      -- We copy the message in the IPC buffer
      -- Note: we don't use 'first attribute. By convention, array indexes
      --       begin with '1' value
      ep.all.size := size;
      ep.all.data(1 .. unsigned_32 (size)) := buf(1 .. unsigned_32 (size));

      -- Adjusting the EndPoint state
      ep.all.state := ewok.ipc.WAIT_FOR_RECEIVER;

      -- If the receiver was blocking, it can be 'freed' from its blocking
      -- state. We reinject it so that it can fulfill its syscall
      if ewok.tasks.get_state (receiver_a.all.id, TASK_MODE_MAINTHREAD)
            = TASK_STATE_IPC_RECV_BLOCKED
      then
         receiver_a.all.state := TASK_STATE_SVC_BLOCKED;
         ewok.softirq.push_syscall (receiver_a.all.id);
         ewok.sched.request_schedule;
      end if;

      if blocking then
         ewok.tasks.tasks_list(caller_id).state := TASK_STATE_IPC_WAIT_ACK;
#if CONFIG_IPC_SCHED_VIOL
         if receiver_a.all.state = TASK_STATE_RUNNABLE or
            receiver_a.all.state = TASK_STATE_IDLE
         then
            receiver_a.all.state := TASK_STATE_FORCED;
         end if;
#end if;
         return;
      else
         set_return_value (caller_id, mode, SYS_E_DONE);
         ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
         return;
      end if;

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

   end ipc_do_send;


   procedure ipc_do_log
     (caller_id   : in     ewok.tasks_shared.t_task_id;
      params      : in out t_parameters;
      mode        : in     ewok.tasks_shared.t_task_mode)
   is
      -- Message size
      size  : positive
         with address => params(2)'address;
      -- Message
      -- FIXME: size must be sanitized first
      msg   : string (1 .. size)
         with address => to_address (params(3));
   begin

      if not ewok.sanitize.is_word_in_data_slot
              (to_system_address (msg'address),
               caller_id,
               mode)
      then
         goto ret_inval;
      end if;

      if size >= 512 then
         goto ret_inval;
      end if;

      debug.log (ewok.tasks.tasks_list(caller_id).name & " " & msg, false);

      set_return_value (caller_id, mode, SYS_E_DONE);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
      return;

   <<ret_inval>>
      set_return_value (caller_id, mode, SYS_E_INVAL);
      ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
   end ipc_do_log;


   procedure sys_ipc
     (caller_id   : in     ewok.tasks_shared.t_task_id;
      params      : in out t_parameters;
      mode        : in     ewok.tasks_shared.t_task_mode)
   is
      syscall : t_syscalls_ipc
         with address => params(0)'address;
   begin

      if not syscall'valid then
         set_return_value (caller_id, mode, SYS_E_INVAL);
         ewok.tasks.set_state (caller_id, mode, TASK_STATE_RUNNABLE);
         return;
      end if;

      case syscall is
         when IPC_LOG         =>
            ipc_do_log (caller_id, params, mode);
         when IPC_RECV_SYNC   =>
            ipc_do_recv (caller_id, params, true, mode);
         when IPC_SEND_SYNC   =>
            ipc_do_send (caller_id, params, true, mode);
         when IPC_RECV_ASYNC  =>
            ipc_do_recv (caller_id, params, false, mode);
         when IPC_SEND_ASYNC  =>
            ipc_do_send (caller_id, params, false, mode);
      end case;

   end sys_ipc;


end ewok.syscalls.ipc;
