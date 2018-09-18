/* \file sleep.h
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
#ifndef SLEEP_H
# define SLEEP_H

/*
 * \file sleep module for EwoK
 *
 * This module implement the sys_sleep() syscall internals. This module
 * permit to ask the kernel for sleeping for a certain amount of time, what
 * sys_yield() doesn't, as it wait indefinitely for an external event.
 *
 * FIXME: is it interesting for the sys_sleep() syscall to specify if
 * the task which to be awoken by external events *before* the end of its
 * sleep period or to refuse any prematurate wakeup ?
 *
 * INFO: the sleep module is nearly implemented but the syscall is *not*
 * by now. The call to the sleep module API in the SysTick Handler is not done
 * too.
 */

#include "exported/sleep.h"
#include "types.h"


/*
 * \brief declare a time to sleep.
 *
 * This function is called in a syscall context and make the task
 * unschedulable for at least the given sleeptime. Only external events
 * (ISR, IPC) can awake the task during this period. If no external events
 * happend, the task is marked as schedulable at the end of the sleep period,
 * which means that the task is schedule *after* the sleep time, not exactly
 * at the sleep time end.
 * The variation of the time to wait between the end of the sleep time and
 * the effective time execution depends on the scheduling policy, the task
 * priority and the number of tasks on the system.
 *
 * \param id        the task id requesting to sleep
 * \param sleeptime the sleep duration in unit given by unit argument
 * \param mode      sleep mode (preemptible by ISR or IPC, or unpreemptible)
 */
uint8_t sleeping(e_task_id      id,
                 uint32_t       ms,
                 sleep_mode_t   mode);

/*
 * This function is called at each sched time of the systick handler, to
 * decrement the sleeptime of each task of 1.
 * If the speeptime reaches 0, the task mainthread is awoken.
 *
 * WARNING: there is case where the task is awoken *before* the end of
 * its sleep period:
 * - when an ISR arise
 * - when an IPC targeting the task is pushed
 *
 * In theses two cases, the sleep_cancel() function must be called in order
 * to cancel the current sleep round. The task is awoken by the corresponding
 * kernel module instead.
 */
void sleep_check_is_awoke(void);

/*!
 * As explain in sleep_round function explanations, some external events may
 * awake the main thread. In that case, the sleep process must be canceled
 * as the awoking process is made by another module.
 * tasks that have requested locked sleep will continue to sleep
 */
void sleep_try_waking_up(e_task_id id);

/**
 * \brief check if a task is currently sleeping
 *
 * \param id the task id to check
 *
 * return true if a task is sleeping, or false
 */
bool sleep_is_sleeping_task(e_task_id id);

#endif/*!SLEEP_H*/
