.. _sys_ipc:

sys_ipc
-------
EwoK Inter-Proccess Communication API
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Synopsis
""""""""

In EwoK there is no **process** structure as there is no MMU on
microcontrolers, but there is a task notion and an IPC principle.

Inter-Process Communication is done using the sys_ipc() syscall familly.
The sys_ipc() familly support the following prototypes::

   e_syscall_ret sys_ipc(IPC_SEND_SYNC, uint8_t target, logsize_t size, const char *msg);
   e_syscall_ret sys_ipc(IPC_RECV_SYNC, uint8_t *sender, logsize_t *size, char *msg);
   e_syscall_ret sys_ipc(IPC_SEND_ASYNC, uint8_t target, logsize_t size, const char *msg);
   e_syscall_ret sys_ipc(IPC_RECV_ASYNC, uint8_t *sender, logsize_t *size, char *msg);

Communicating with another task requests to know its identifier. Each task has
a unique numeric identifier generated at build time by Tataouine.

Each task pair is using a dedicated communication channel which is elected
during the first IPC request. This communication channel is then keeped for
this task pair for the system entire lifecycle.

Getting a task identifier is done by using sys_init(INIT_GETTASKID), as
explained above.

.. important::
   Synchronous and asynchronous IPC can be used together (sending synchronously
   and received asyncrhonously for e.g.). The synchronous versus asynchronous
   paradigm only impact the caller's behavior

.. danger::
   EwoK doesn't detect cyclic deadlocks between multiple tasks (more than 2).
   Be careful when designing your IPC automaton

.. note::
   EwoK detect IPC mutual lock (two task sending IPC to each other)., returning
   E_BUSY error

.. important::
   The EwoK IPC paradigm support mono-directionnal communications, allowing to
   send data withtout being able to receive data from the same target

sys_ipc(SEND_SYNC)
""""""""""""""""""

A task can synchronously send data to another task. When sending data
synchronously, the task is freezed until the other task read all the data sent
(using one of the receive IPCs).

The ipc syncrhonous send syscall has the following API::

   e_syscall_ret sys_ipc(IPC_SEND_SYNC, uint8_t target, logsize_t size, const char *msg);

When sending syncrhonously data to another task, the following can happend:

   * SYS_E_DENIED: The current task is not allowed to communicate with the
     other task
   * SYS_E_INVAL: One of the syscall argument is invalid (invalid task id,
     pointer value, etc.)
   * SYS_E_BUSY: (only in rare occasion) only when the target has already a
     message from the current task that has not been read yet. This happend
     when executing consecutively an asyncrhonous and a synchronous syscall
     targetting the same task. This also happend if the target task has sent an
     IPC to the current task which is not yet received (dead lock check)

To these usual behaviors, any attempt to send an IPC during the task init mode
fails with SYS_E_DENIED.

sys_ipc(SEND_ASYNC)
"""""""""""""""""""

There is times where a task may want to send a message to another without
waiting for the message to be consumed. In this very case, asynchronous send
IPC can be used. The message is then keeped in the kernel while the target task
read it, without locking the emitter. This permits to support high reactivity
software stack automaton without risk.

.. note::
   When using asynchronous IPC for reactivity constraints, it is recommanded to
   use only asynchronous ipc, getting the IPC syscalls out of the tasks
   blocking points

.. important::
   When sending asynchronous messages, there is no (clean) way to be informed
   of the message reception. The target task has to voluntary acknowledge it in
   return.

The ipc syncrhonous receive syscall has the following API::

   e_syscall_ret sys_ipc(IPC_SEND_ASYNC, uint8_t target, logsize_t size, char *msg);

When sending asyncrhonously data to another task, the following can happend:

   * SYS_E_DENIED: The current task is not allowed to communicate with the
     other task
   * SYS_E_INVAL: One of the syscall argument is invalid (invalid task id,
     pointer value, etc.)
   * SYS_E_BUSY: (only in rare occasion) only when the target has already a
     message from the current task that has not been read yet. This also
     happend if the target task has sent an IPC to the current task which is
     not yet received (communication channel already used)

To these usual behaviors, any attempt to send an IPC during the task init mode
fails with SYS_E_DENIED.

.. important::
   Asynchronous send never freeze the caller task

sys_ipc(RECV_SYNC)
""""""""""""""""""

A task can voluntary wait for a message from another (or any) task(s), by
executing a synchronous receive IPC.
This syscall freeze the task while there is no message to read from the target
task requested in the syscall arguments.

A task can :
   * wait for another specific task (basic IPC mode)
   * wait for any tasks that may communicate with it (listen mode)

The mode depend on the target parameter value, that can be a specific task id
(basic IPC mode) or ANY_APP (listen mode).

.. important::
   In listen mode, a task can receive IPC only from other tasks that are
   allowed to communicate with it

The ipc asyncrhonous send syscall has the following API::

   e_syscall_ret sys_ipc(IPC_RECV_ASYNC, uint8_t *target, logsize_t *size, const char *msg);

When receiving a message, the kernel modify:
   * The target value, when receiving in listen mode, to know which task has
     sent the message
   * the message size, with the effective message size

When receiving syncrhonously data, the following can happend:

   * SYS_E_DENIED: The current task is not allowed to communicate with the
     other task set as target
   * SYS_E_INVAL: One of the syscall argument is invalid (invalid task id,
     pointer value, etc.) or the buffer size is too small to get back the
     message.
   * SYS_E_BUSY: (only in rare occasion) only when the target is already in
     receiving mode, waiting for the current task to send a message.

To these usual behaviors, any attempt to send an IPC during the task init mode
fails with SYS_E_DENIED.

sys_ipc(RECV_ASYNC)
"""""""""""""""""""

Sometimes, a task may whish to check if there is a pending message without
being locked. In this case, it uses the asynchronous receive IPC in order to
get back a message if there is one waiting, or continue its normal execution if
there is not.

If there is no message to read, the syscall returns with SYS_E_BUSY.

.. important::
   Asynchronous receive never freeze the caller task

The asynchronous receive IPC arguments are handled in the same way synchronous
receive IPC arguments are.

The ipc asyncrhonous receive syscall has the following API::

   e_syscall_ret sys_ipc(IPC_RECV_ASYNC, uint8_t *sender, logsize_t *size, char *msg);


