/* \file devices.h
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
#ifndef KERNEL_DEVICES_H
#define KERNEL_DEVICES_H

/*
 * Remember to include libstd types.h header for stdint support
 */
#include "gpio.h"
#include "irq.h"

/*
** Per device max values
*/

#define MAX_IRQS 4 /**< The maximum number of IRQ lines per device*/

typedef enum {
    /**
     * automatically map device at sys_init(INIT_DONE) time. The device can't
     * be unmap by the task and is mapped once for all.
     */
   DEV_MAP_AUTO,
    /**
     * map the device voluntary using sys_cfg(CFG_DEV_MAP, devid).
     * The device can be unmap using sys_cfg(CFG_DEV_UNMAP, devid).
     * The device is *not* mapped at sys_init(INIT_DONE) and its mapping time
     * slots is under the control of the task.
     * Mapping the device voluntary requires a specific permission.
     */
   DEV_MAP_VOLUNTARY
} dev_map_mode_t;


/**
** \brief this is the main device declaration structure for userspace drivers
**
** These information MUST be declared before sys_init(INIT_DONE) and no
** device/handler registration will be authorized after. Devices will be
** activated by sys_init(INIT_DONE).
**
** PS: Local applications are not considered as a source of a potential attack
** before the call of sys_init(INIT_DONE). Only remote attackers are considered
** in this scheme (through USB communication, etc.)
*/
typedef struct {
    /**< Device name.
     *   For pretty printing
     */
    char name[16];

    /**< Device base address.
     *   Device memory mapped address, as defined in the SoC or board
     *   datasheet. The kernel checks it against the SoC/board devmap.
     */
    physaddr_t address;

    /**< Device memory mapping size
     *   Memory mapped size (in bytes). Mandatory to map the device in the task
     *   address space (during context switching). Its size is checked against
     *   the SoC/board devmap.
     */
    uint16_t size;

    /**< Number of IRQ lines associated to the device.
     *   How many entries in irqs[] array are used.
     */
    uint8_t irq_num;

    /**< Number of GPIO lines associated to the device.
     *   How many entries in gpios[] array are used.
     */
    uint8_t gpio_num;

    /**< Type of device mapping (automatic or voluntary).
     */
    dev_map_mode_t map_mode;

    /**< List or configured IRQs
     *   For each entry, a structure dev_irq_info_t is set \sa dev_irq_info_t
     */
    dev_irq_info_t irqs[MAX_IRQS];

    /**< List of configured GPIOs
     *   For each slot, a structure dev_gpio_info_t is set \sa dev_gpio_info_t
     */
    dev_gpio_info_t gpios[MAX_GPIOS];

} device_t;

#endif
