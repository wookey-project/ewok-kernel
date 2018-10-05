/* devices.h
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

#ifndef DEVICES_H_
#define DEVICES_H_

#include "exported/devices.h"
#include "types.h"
#include "tasks.h"

typedef enum {
        DEV_TYPE_USER,
        DEV_TYPE_KERNEL,
} e_dev_type;

typedef enum {
        DEV_STATE_NONE,
        DEV_STATE_RESERVED,
        DEV_STATE_REGISTERED,
        DEV_STATE_ENABLED,
        DEV_STATE_REG_FAIL,
} e_dev_state;

typedef struct {
        device_t                        udev;
        e_task_id                       task_id;
        bool                            is_mapped; /* for voluntary devices state */
        const struct device_soc_infos  *devinfo;
        e_dev_state                     status;
} k_device_t;

/************************************************************************
 * Device package getters and setters
 ***********************************************************************/

retval_t dev_set_device_map (bool state, e_device_id dev_id);

e_task_id  dev_get_task_from_id (e_device_id dev_id);

bool      dev_is_mapped(e_device_id dev_id);

device_t* dev_get_device_from_id (e_device_id dev_id);

uint16_t dev_get_device_size (e_device_id dev_id);

physaddr_t dev_get_device_addr (e_device_id dev_id);

bool dev_is_mapped_voluntary (e_device_id dev_id);

bool dev_is_device_region_ro (e_device_id dev_id);

uint8_t dev_get_device_region_mask (e_device_id dev_id);

/*
** Registering a new device. This function is call by the sys_init(REGISTER_DEVICE) syscall
*/
uint8_t dev_register_device(e_device_id, device_t*);

/**
 * \brief return the irq info structure from an IRQ and associated task
 *
 * \param[in] task the task to which the device belongs
 * \param[in] irq  the irq number
 *
 * \return the corresponding irq info structure, or 0 if not found.
 */
dev_irq_info_t *dev_get_irqinfo_from_irq(uint8_t irq);

e_task_id dev_get_task_from_gpio_kref(gpioref_t kref);

dev_gpio_info_t *dev_get_gpio_from_gpio_kref(gpioref_t kref);


/************************************************************************
 * Device registration functions
 ***********************************************************************/

/*
 * This function simply register the GPIO. It update the user device_t gpio
 * struct with the kref corresponding to the concatenation of the GPIO port
 * (4bits) and the pin number (4 bits).
 * This will permit to the user application to interract with the GPIO using
 * a syscall with this kref as an argument.
 */
uint8_t dev_register_gpios(e_device_id dev_id, e_task_id task_id);


/*!
 * \brief Register all the task's device ISR in the IRQ manager
 *
 * ISR will be executed in thread mode, in the task global context, but
 * with a dedicated stack and local autonomous context for save/restore,
 * to support preemption by IRQ.
 */
uint8_t dev_register_handlers(e_device_id dev_id, e_task_id task_id);

/************************************************************************
 * Device slotting functions
 ***********************************************************************/

void dev_release_device_slot(e_device_id);

e_device_id dev_get_free_device_slot(e_task_id, device_t*);


/************************************************************************
 * Device Enabling functions
 ***********************************************************************/
/*
** Enable all GPIOs of a given device
*/
uint8_t dev_enable_gpio(e_device_id);

/*
** This function should be called by syscall sys_init(INIT_LOCK).
** This behavior:
** 1) forces user tasks to use this syscall, locking any future sys_init usage
** 2) enable all devices of the task at one single moment, at the end of init
*/
uint8_t dev_enable_device(e_device_id);



/************************************************************************
 * Device sanitation
 ***********************************************************************/
/*
 * This file check that the device_t structure declare an existing device in
 * the current SoC. The address and size should be valid.
 *
 * All IRQ and GPIO contents should be properly defined and valid.
 *
 * Furthermore, this function check that the irq list and gpio list is
 * homogeneous (no table overflow), to avoid any memory fault in the kernel.
*/
retval_t dev_sanitize_user_device (device_t *udev, e_task_id task_id);

/************************************************************************
 * Device package initialization function and subfunctions
 ***********************************************************************/
void dev_init(void);

#endif                          /*!DEVICES_H_ */
