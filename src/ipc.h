/* \file ipc.h
 *
 * Copyright 2018 The wookey project team <wookey@ssi.gouv.fr>
 *   - Ryad     Benadjila
 *   - Arnauld  Michelizza
 *   - Mathieu  Renard
 *   - Philippe Thierry
 *   - Philippe Trebuchet
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 *
 */

#ifndef IPC_H_
#define IPC_H_

#include "types.h"
#include "tasks-shared.h"

#define MAX_IPC_ENDPOINTS   10
#define ANY_APP             0xff
#define MAX_IPC_MSG         128


typedef enum {
    /* IPC endpoint is unused */
    FREE,
    /* IPC endpoint is used and is ready for message passing */
    READY,
    /* send() block until the receiver read the message */
    WAIT_FOR_RECEIVER
} ipc_endpoint_state_t;


typedef struct {
    e_task_id               from;               /* sender id */
    e_task_id               to;                 /* receiver id */
    ipc_endpoint_state_t    state;
    char                    data[MAX_IPC_MSG];
    logsize_t               size;               /* Must be < MAX_IPC_MSG */
} ipc_endpoint_t;

/* Global array of IPC EndPoints */
ipc_endpoint_t ipc_endpoints[MAX_IPC_ENDPOINTS];

/* Init IPC endpoints */
void ipc_init_endpoints (void);

/* Get a free IPC endpoint */
ipc_endpoint_t* ipc_get_endpoint (void);

/* Release a used IPC endpoint */
void ipc_release_endpoint (ipc_endpoint_t *ep);



#endif /*! IPC_H_ */
