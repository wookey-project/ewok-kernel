/* \file mpu-handler.c
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

#include "m4-mpu.h"
#include "autoconf.h"
#include "soc-layout.h"
#include "soc-scb.h"
#include "debug.h"
#include "tasks.h"
#include "kernel.h"
#include "mpu.h"
#include "sched.h"
#include "default_handlers.h"

#define HANDLERLOG(fmt, ...) \
    dbg_log(ANSI_COLOR_RED fmt ANSI_COLOR_RESET, ##__VA_ARGS__)

/*
** This is the classical Memory Fault handler. Can be used in both loader and kernel cases, but
** has to be registered manually if needed (for e.g. by mpu_init() part).
*/
stack_frame_t* MemManage_Handler(stack_frame_t * frame)
{
    task_t *current;
    current = sched_get_current();

    uint32_t mmsr = *((uint32_t *) r_CORTEX_M_SCB_MMSR);

    /* basic default when no 'current' task */
    if (!current) {
        HANDLERLOG("MPU error: No current task\n");
        dbg_flush();
        while (1) ;
    }

    /* stack errors */
    if (mmsr & SCB_CFSR_MMFSR_MLSPERR_Msk) {
        HANDLERLOG("MPU error: Corrupted Stack\n");
    }

    if (mmsr & SCB_CFSR_MMFSR_DACCVIOL_Msk) {
        HANDLERLOG("MPU error: Instruction access violation\n");
    }
    if (mmsr & SCB_CFSR_MMFSR_DACCVIOL_Msk) {
        HANDLERLOG("MPU error: Data access violation\n");
    }

    HANDLERLOG("mmsr:%x, current:%d (%s), sp:%x, pc:%x\n",
            mmsr, current->id, current->name, frame, frame->pc);

    /* On memory fault, the task is no more scheduled */
    dbg_flush();

    if (current->mode == TASK_MODE_MAINTHREAD) {
        current->state[TASK_MODE_MAINTHREAD] = TASK_STATE_FAULT;
    } else {
        current->state[TASK_MODE_ISRTHREAD] = TASK_STATE_FAULT;
    }

    request_schedule();

    return frame;
}
