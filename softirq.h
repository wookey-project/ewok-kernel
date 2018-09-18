/* softirq.h
 *
 * Copyright (C) 2018 ANSSI
 * All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the BSD license.  See the LICENSE file for details.
 */

#ifndef SOFTIRQ_H_
#define SOFTIRQ_H_

#include "tasks.h"

typedef enum {
        SFQ_USR_ISR = 0,
        SFQ_SYSCALL = 1,
        NUM_SOFTIRQ = 2,
} e_softirq_type;

/* the softirq task itslef */
void task_softirq(void);

 /**/
void softirq_query(e_softirq_type sfq, e_task_id task_id, uint8_t irq,
                   physaddr_t irq_handler, physaddr_t *args);

/* init the softirq subsystem */
void softirq_init(void);

#endif
