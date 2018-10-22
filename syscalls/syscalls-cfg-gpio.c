/* syscalls-cfg-gpio.c
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

#include "debug.h"
#include "devices.h"
#include "devices-shared.h"
#include "gpio.h"
#include "exti.h"
#include "syscalls.h"
#include "syscalls-utils.h"
#include "syscalls-cfg-gpio.h"
#include "sanitize.h"

void sys_cfg_gpio_set(task_t *caller, __user regval_t *regs, e_task_mode mode)
{
    uint8_t user_gpio = (uint8_t) regs[1];
    uint8_t gpio_value = (uint8_t) regs[2];
    device_t *udev;

    /* Generic sanitation of inputs */
    if (caller->init_done == false) {
        syscall_r0_update(caller, mode, SYS_E_DENIED);
        syscall_set_target_task_runnable(caller);
        return;
    }

    /* Validate that the GPIO is owned by the task */
    for (int i = 0; i < caller->num_devs; ++i) {
        udev = dev_get_device_from_id (caller->dev_id[i]);

        for (int j = 0; j < udev->gpio_num; ++j) {
            if (udev->gpios[j].kref.val == user_gpio) {
                gpio_set_value(udev->gpios[j].kref, gpio_value);
                syscall_r0_update(caller, mode, SYS_E_DONE);
                syscall_set_target_task_runnable(caller);
                return;
            }
        }
    }

    /* GPIO not found */
    syscall_r0_update(caller, mode, SYS_E_INVAL);
    syscall_set_target_task_runnable(caller);
    return;
}

void sys_cfg_gpio_get(task_t *caller, __user regval_t *regs, e_task_mode mode)
{
    uint8_t     user_gpio = (uint8_t) regs[1];
    uint32_t   *gpio_value = (uint32_t *) regs[2];
    device_t   *udev;

    /* Generic sanitation of inputs */
    if (!sanitize_is_pointer_in_slot((void *)gpio_value, caller->id, mode)) {
        goto ret_inval;
    }

    /* End of generic sanitation */
    if (caller->init_done == false) {
        syscall_r0_update(caller, mode, SYS_E_DENIED);
        syscall_set_target_task_runnable(caller);
        return;
    }

    /* validate that the GPIO is owned by the task  */
    for (int i = 0; i < caller->num_devs; ++i) {
        udev = dev_get_device_from_id (caller->dev_id[i]);
        for (int j = 0; j < udev->gpio_num; ++j) {
            if (udev->gpios[j].kref.val == user_gpio) {
                *gpio_value = gpio_get_value(udev->gpios[j].kref);
                syscall_r0_update(caller, mode, SYS_E_DONE);
                syscall_set_target_task_runnable(caller);
                return;
            }
        }
    }

 ret_inval:
    /* GPIO not found or invalid value*/
    syscall_r0_update(caller, mode, SYS_E_INVAL);
    syscall_set_target_task_runnable(caller);
    return;
}


void sys_cfg_gpio_unlock_exti(task_t *caller, __user regval_t *regs, e_task_mode mode)
{
    uint8_t     user_gpio = (uint8_t) regs[1];
    device_t   *udev;
    bool       found = false;
    dev_gpio_info_t* gpio = 0;

    /* End of generic sanitation */
    if (caller->init_done == false) {
        syscall_r0_update(caller, mode, SYS_E_DENIED);
        syscall_set_target_task_runnable(caller);
        return;
    }

    /* validate that the GPIO is owned by the task  */
    for (int i = 0; i < caller->num_devs; ++i) {
        udev = dev_get_device_from_id (caller->dev_id[i]);
        for (int j = 0; j < udev->gpio_num; ++j) {
            if (udev->gpios[j].kref.val == user_gpio) {
                gpio = &(udev->gpios[j]);
                found = true;
            }
        }
    }
    if (!found) {
        goto ret_inval;
    }

    /* only GPIOs with exti trigger which are locked by the kernel can be unlocked */
    if (   gpio->exti_trigger == GPIO_EXTI_TRIGGER_NONE
        || gpio->exti_lock    == GPIO_EXTI_UNLOCKED) {
        goto ret_inval;
    }

    /* enable the exti line */
    exti_enable(gpio->kref);

    syscall_r0_update(caller, mode, SYS_E_DONE);
    syscall_set_target_task_runnable(caller);
    return;

 ret_inval:
    /* GPIO not found or invalid value*/
    syscall_r0_update(caller, mode, SYS_E_INVAL);
    syscall_set_target_task_runnable(caller);
    return;

}
