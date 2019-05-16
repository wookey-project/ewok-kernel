.. _sys_ipc:

*sys_ipc*, Inter-Proccess Communication
---------------------------------------

.. contents::

Synopsis
^^^^^^^^

*Inter-Process Communication* is done using the ``sys_ipc()`` syscall familly.
IPC can be either *synchronous* or *asynchronous*:

   * *synchronous* IPC requests are blocking until the message has been sent and
     received
   * *asynchronous* IPC are non blocking. They may return an error if the other
     side of the channel is not ready.

EwoK detects IPC mutual lock (two task sending IPC to each other), returning
``SYS_E_BUSY`` error but it does not detect cyclic deadlocks between multiple tasks
(more than 2). Be careful when designing your IPC automaton!

Note that IPC are half-duplex. For example, if task *A* can send messages to
task *B*, the reciprocity is not always true and task *B* may have no permission to
send any message to *A*.


Prerequisites
^^^^^^^^^^^^^

If a task *A* want to communicate with another task *B*, task *A* need
to retrieve *B*'s *task id*.
Getting a task identifier is done with ``sys_init(INIT_GETTASKID)`` syscall: ::

    uint8_t        id;
    e_syscall_ret  ret;

    ret = sys_init(INIT_GETTASKID, "task_b", &id);
    if (ret != SYS_E_DONE) {
        ...
    }

For more details, see :ref:`sys_init`.

.. important::
   Notice that any attempt to receive or to send a message with an IPC during
   the task *init mode* fails with ``SYS_E_DENIED``.


sys_ipc(SEND_SYNC)
^^^^^^^^^^^^^^^^^^

A task can synchronously send data to another task.
The task is blocked until the other task emit either a
``sys_ipc(RECV_SYNC)`` or a ``sys_ipc(RECV_ASYNC)`` syscall: ::

    uint8_t        id;
    logsize_t      size;
    char          *msg = "hello";
    e_syscall_ret  ret;
    ...
    ret = sys_ipc(IPC_SEND_SYNC, id, sizeof(msg), msg);
    if (ret != SYS_E_DONE) {
       ... /* Error handling */
    }

The ``sys_ipc(IPC_SEND_SYNC,....)`` can return:

   * ``SYS_E_DONE``: The message has been succesfully emitted
   * ``SYS_E_DENIED``: The current task is not allowed to communicate with the
     other task
   * ``SYS_E_INVAL``: One of the syscall argument is invalid (invalid task id,
     pointer value, etc.)
   * ``SYS_E_BUSY``: This happens only in the very rare condition of a
     synchronous send is emited after an asynchronous send and while the receiver
     has not emited any receive syscall.


sys_ipc(SEND_ASYNC)
^^^^^^^^^^^^^^^^^^^

Asynchronous send is used to send a message without waiting for it to be
received. The message is kept in a kernel's buffer until the receiver read
it: ::

   uint8_t        id;
   logsize_t      size;
   char          *msg = "hello";
   e_syscall_ret  ret;
    ...
   ret = sys_ipc(IPC_SEND_ASYNC, id, sizeof(msg), msg);
   if (ret != SYS_E_DONE) {
       ... /* Error handling */
   }

The ``sys_ipc(IPC_SEND_ASYNC,....)`` can return:

   * ``SYS_E_DONE``: The message has been succesfully emitted
   * ``SYS_E_DENIED``: the current task is not allowed to communicate with the
     other task
   * ``SYS_E_INVAL``: one of the syscall argument is invalid (invalid task id,
     pointer value, etc.)
   * ``SYS_E_BUSY``: (only in rare occasion) only when the target has already a
     message from the current task that has not been read yet. This also
     happens if the target task has sent an IPC to the current task which is
     not yet received (communication channel already used)

Mixing synchronous and asynchronous IPC is possible but, of course, need
some very careful thinking.

sys_ipc(RECV_SYNC)
^^^^^^^^^^^^^^^^^^

A task can synchronously wait for a message:
   * from another specific task, by setting accordingly the task *id*
   * from any task, by setting the task *id* to ``ANY_APP``

The task is blocked until a readable message is feed: ::

   uint8_t        id;
   logsize_t      size;
   char           buf[128];
   e_syscall_ret  ret;

   id   = ANY_APP;      /* Waiting a msg from *any* task */
   size = sizeof(buf);  /* Receiving buffer max size */

   ret = sys_ipc(IPC_RECV_SYNC, &id, &size, buf);
   if (ret != SYS_E_DONE) {
       ... /* Error handling */
   }

When a message is received, the kernel modify the following parameters (based
on the example above):

   * ``id``: to know which task has sent the message
   * ``size``: to set message's size
   * ``buf``: the message is copied into the receiving buffer

The ``sys_ipc(IPC_RECV_SYNC,....)`` can return:

   * ``SYS_E_DONE``: The message has been succesfully received
   * ``SYS_E_DENIED``: the current task is not allowed to communicate with the
     other task set as target
   * ``SYS_E_INVAL``: one of the syscall argument is invalid (invalid task id,
     pointer value, etc.) or the buffer size is too small to get back the
     message.
   * ``SYS_E_BUSY``: (only in rare occasion) only when the target is already in
     receiving mode, waiting for the current task to send a message.

sys_ipc(RECV_ASYNC)
^^^^^^^^^^^^^^^^^^^

Asynchronous receive is used to read any pending message. The task
is not blocked and directly returns: ::

   ret = sys_ipc(IPC_RECV_ASYNC, &id, &size, buf);


This syscall returns the same values that is synchonous counterpart plus
``SYS_E_BUSY`` if there is no message to read.


