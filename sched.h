/* sched.h
 *
 * Copyright (C) 2018 ANSSI
 * All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the BSD license.  See the LICENSE file for details.
 */

#ifndef SCHED_H
#define SCHED_H

#include "kernel.h"

void request_schedule(void);

void schedule(void);

void sched_init(void);

task_t *sched_get_current(void);

void sched_switch_thread(task_t * to);

#endif
