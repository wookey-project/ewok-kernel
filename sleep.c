#include "exported/sleep.h"
#include "types.h"
#include "autoconf.h"
#include "generated/apps_layout.h"
#include "tasks.h"
#include "sleep.h"
#include "debug.h"

static struct st {
    unsigned long long  sleep_until;
    bool                interruptible;
} sleep_tab[ID_APPMAX + 1] = { 0 };

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
 * \param unit      the unit of the sleep time, which is one of sleep_unit_t
 */
uint8_t sleeping(e_task_id      id,
                 uint32_t       ms,
                 sleep_mode_t   mode)
{
    if (id <= ID_APPMAX) {
        sleep_tab[id].sleep_until =
            core_systick_get_ticks() + core_ms_to_ticks (ms);
        if (mode == SLEEP_MODE_INTERRUPTIBLE) {
            sleep_tab[id].interruptible = true;
            task_set_task_state(id, TASK_MODE_MAINTHREAD, TASK_STATE_SLEEPING);
        } else {
            sleep_tab[id].interruptible = false;
            task_set_task_state(id, TASK_MODE_MAINTHREAD, TASK_STATE_SLEEPING_DEEP);
            KERNLOG(DBG_INFO, "task %d: entering deep sleep\n", id);
        }
    } else {
        goto err_id;
    }
err_id:
    return 2;
}

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
void sleep_check_is_awoke(void)
{
    uint64_t t = core_systick_get_ticks();

    for (uint8_t id = 0; id <= ID_APPMAX; ++id) {
        if ((task_get_task_state(id, TASK_MODE_MAINTHREAD) == TASK_STATE_SLEEPING ||
             task_get_task_state(id, TASK_MODE_MAINTHREAD) == TASK_STATE_SLEEPING_DEEP)
            && t > sleep_tab[id].sleep_until)
        {
            task_set_task_state(id, TASK_MODE_MAINTHREAD, TASK_STATE_RUNNABLE);
        } 
    }
}

/**
 * \brief check if a task is currently sleeping
 *
 * \param id the task id to check
 *
 * return true if a task is sleeping, or false
 */
bool sleep_is_sleeping_task(e_task_id id)
{
    if (task_get_task_state(id, TASK_MODE_MAINTHREAD) == TASK_STATE_SLEEPING ||
        task_get_task_state(id, TASK_MODE_MAINTHREAD) == TASK_STATE_SLEEPING_DEEP)
    {
        if (sleep_tab[id].sleep_until > core_systick_get_ticks()) {
            return true;
        } else {
            task_set_task_state(id, TASK_MODE_MAINTHREAD, TASK_STATE_RUNNABLE);
            return false;
        }
    } else {
        return false;
    }
}

/*
 * As explain in sleep_round function explanations, some external events may
 * awake the main thread. In that case, the sleep process must be canceled
 * as the awoking process is made by another module.
 * tasks that have requested locked sleep will continue to sleep
 */
void sleep_try_waking_up (e_task_id id)
{
    if (sleep_tab[id].sleep_until < core_systick_get_ticks() ||
        sleep_tab[id].interruptible == true)
    {
        task_set_task_state(id, TASK_MODE_MAINTHREAD, TASK_STATE_RUNNABLE);
    }
}

