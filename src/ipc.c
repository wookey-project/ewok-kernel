/* \file ipc.c
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

#include "ipc.h"
#include "tasks.h"

/* Global array of IPC EndPoints, should be initialized */
static ipc_endpoint_t ipc_endpoints[MAX_IPC_ENDPOINTS];

void ipc_init_endpoint (ipc_endpoint_t *ep)
{
    ep->from  = ID_UNUSED;
    ep->to    = ID_UNUSED;
    ep->state = FREE;
    ep->size  = 0;
    for (int i=0; i<MAX_IPC_MSG; i++) {
        ep->data[i] = 0;
    }
}

void ipc_init_endpoints (void)
{
    for (int i=0; i<MAX_IPC_ENDPOINTS; i++) {
        ipc_init_endpoint (&ipc_endpoints[i]);
    }
}

ipc_endpoint_t* ipc_get_endpoint (void)
{
    for (int ep=0; ep<MAX_IPC_ENDPOINTS; ep++) {
        if (ipc_endpoints[ep].state == FREE) {
            ipc_endpoints[ep].state = READY;
            return &ipc_endpoints[ep];
        }
    }
    return NULL;
}

void ipc_release_endpoint (ipc_endpoint_t *ep)
{
    ipc_init_endpoint (ep);
}

