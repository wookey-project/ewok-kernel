/* devices.c
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

#include "autoconf.h"
#include "perm.h"
#include "devices.h"
#include "soc-interrupts.h"
#include "soc-gpio.h"
#include "devmap.h"
#include "soc-nvic.h"
#include "debug.h"
#include "kernel.h"
#include "gpio.h"
#include "syscalls.h"
#include "exti.h"
#include "libc.h"
#include "sanitize.h"
#include "mpu.h"

/*
** This table hosts all registered devices for all user tasks.
** It contains data sent by user via sys_init(INIT_REGISTERDEV).
** The infos hosted in this opaque are checked by dev_check_content(). If the
** k_device_t struct is set as DEV_REGISTERED, the user content is considered
** validated.
** It is *not* possible to un-register a device.
*/
static k_device_t device_tab[ID_DEV_MAX];


/************************************************************************
 * Device package getters and setters
 ***********************************************************************/

retval_t dev_set_device_map (bool state, e_device_id dev_id)
{
    e_task_id tskid = dev_get_task_from_id(dev_id);
    task_t   *tsk = NULL;

    tsk = task_get_task(tskid);
    if (state == true && tsk->num_devs_mmapped == MPU_MAX_EMPTY_REGIONS) {
        return FAILURE;
    }
    device_tab[dev_id].is_mapped = state;
    if (state == true) {
        tsk->num_devs_mmapped++;
    } else {
        tsk->num_devs_mmapped--;
    }
    return SUCCESS;
}

e_task_id  dev_get_task_from_id (e_device_id dev_id)
{
    return device_tab[dev_id].task_id;
}


inline device_t* dev_get_device_from_id (e_device_id dev_id)
{
    return &device_tab[dev_id].udev;
}

inline uint32_t dev_get_device_size (e_device_id dev_id)
{
    return device_tab[dev_id].udev.size;
}

inline physaddr_t dev_get_device_addr (e_device_id dev_id)
{
    return device_tab[dev_id].udev.address;
}

bool dev_is_mapped(e_device_id dev_id)
{
    return device_tab[dev_id].is_mapped;
}

inline bool dev_is_mapped_voluntary (e_device_id dev_id)
{
    return device_tab[dev_id].udev.map_mode;
}

inline bool dev_is_device_region_ro (e_device_id dev_id)
{
    return device_tab[dev_id].devinfo->ro;
}

inline uint8_t dev_get_device_region_mask (e_device_id dev_id)
{
    return device_tab[dev_id].devinfo->mask;
}


/**
 * \brief return the irq info structure from an IRQ and associated task
 *
 * \param[in] task the task to which the device belongs
 * \param[in] irq  the irq number
 *
 * \return the corresponding irq info structure, or 0 if not found.
 */
dev_irq_info_t *dev_get_irqinfo_from_irq(uint8_t irq)
{
    e_device_id dev_id = get_device_from_interrupt(irq);

    for (int j = 0; j < device_tab[dev_id].udev.irq_num; ++j) {
        if (device_tab[dev_id].udev.irqs[j].irq == irq) {
            return &device_tab[dev_id].udev.irqs[j];
        }
    }

    /* No irq has been matched */
    return NULL;
}

/*
 * \brief return GPIO info from gpio kref identifier
 */
dev_gpio_info_t *dev_get_gpio_from_gpio_kref(gpioref_t kref)
{
    /*
     * We loop on all devices to find the given GPIO kref
     * FIXME: need for some optimizations to avoid "brute force"
     *        searching
     */
    for (uint8_t i = ID_DEV1; i < ID_DEV_MAX; ++i) {
        /* No more devices, just leave loop */
        if (device_tab[i].status == DEV_STATE_NONE) {
            break;
        }
        device_t *udev = (device_t*)&device_tab[i];
        /* We loop on all gpios to find the given GPIO kref */
        for (uint8_t gpio = 0; gpio < udev->gpio_num; ++gpio) {
            if (udev->gpios[gpio].kref.val == kref.val) {
                return &udev->gpios[gpio];
            }
        }
    }
    return 0;
}



/************************************************************************
 * Device registration functions
 * These functions are called when a device is registered, at initialization
 * time
 ***********************************************************************/

/*!
 * \brief Register all the task's device ISR in the IRQ manager
 *
 * ISR will be executed in thread mode, in the task global context, but
 * with a dedicated stack and local autonomous context for save/restore,
 * to support preemption by IRQ.
 */
uint8_t dev_register_handlers(e_device_id dev_id, e_task_id task_id)
{
    if (device_tab[dev_id].status == DEV_STATE_REGISTERED) {
        KERNLOG(DBG_ERR, "dev_register_handlers(): status already set as DEV_STATE_REGISTERED\n");
        return 1;
    }

    for (int i = 0; i < device_tab[dev_id].udev.irq_num; ++i) {

        /* Checking if there is not already a user IRQ handler */
        if (is_interrupt_already_used(device_tab[dev_id].udev.irqs[i].irq)) {
            KERNLOG(DBG_ERR,
                "registering irq handler 0x%x for irq %d fails. This irq is already set\n",
                device_tab[dev_id].udev.irqs[i].handler,
                device_tab[dev_id].udev.irqs[i].irq);
            return 1;
        } else {
            set_interrupt_handler(device_tab[dev_id].udev.irqs[i].irq,
                device_tab[dev_id].udev.irqs[i].handler, task_id, dev_id);
        }
    }

    return 0;
}

/*
 * This function simply register the GPIO and return a reference handle.
 */
uint8_t dev_register_gpios(e_device_id dev_id, e_task_id task_id)
{
    uint8_t     ret;

    if (device_tab[dev_id].status == DEV_STATE_REGISTERED) {
        KERNLOG(DBG_ERR, "dev_register_gpios(): status already set as DEV_STATE_REGISTERED\n");
        return 1;
    }

    for (int i = 0; i < device_tab[dev_id].udev.gpio_num; ++i) {
        /* Then we register the GPIO itself */
        ret = gpio_register_gpio
                (task_id, dev_id, &device_tab[dev_id].udev.gpios[i]);
        if (ret) {
            KERNLOG(DBG_ERR, "device GPIO registering failed!\n");
            return ret;
        }

        /* To finish we register possible associated EXTI line */
        ret = exti_register_exti(&device_tab[dev_id].udev.gpios[i]);
        if (ret) {
            KERNLOG(DBG_ERR, "device GPIO-EXTI registering failed!\n");
            return ret;
        }

        KERNLOG(DBG_INFO,
            "registered GPIO port %x, pin %x for device %s\n",
            device_tab[dev_id].udev.gpios[i].kref.port,
            device_tab[dev_id].udev.gpios[i].kref.pin,
            device_tab[dev_id].udev.name);
    }

    return 0;
}

/*
 * Registering a new device.
 * NOTE: If the task configures only some GPIOs without any "real" device
 * behind 'devinfo' field will be set as NULL.
 */
uint8_t dev_register_device(e_device_id dev_id, device_t *udev)
{
    struct device_soc_infos  *devinfo = NULL;

    if (udev->size != 0) {
        devinfo = soc_devmap_find_device(udev->address, udev->size);
        if (devinfo == NULL) {
            KERNLOG(DBG_WARN, "can't find device %s (addr: %x, size: %x)\n",
                udev->name, udev->address, udev->size);
            return 1;
        }

        memcpy(&device_tab[dev_id].udev, udev, sizeof(device_t));
        device_tab[dev_id].devinfo = devinfo;
        device_tab[dev_id].is_mapped = false;
    }

    device_tab[dev_id].status = DEV_STATE_REGISTERED;

    KERNLOG(DBG_INFO, "registered device %s (%x)\n", udev->name, udev->address);
    return 0;
}


/************************************************************************
 * Device Enabling functions
 * These functions are called when the sys_init(INIT_DONE) function is
 * called by the userspace.
 ***********************************************************************/

uint8_t dev_disable_device(e_task_id task_id,
                           e_device_id dev_id)
{
    if (device_tab[dev_id].task_id != task_id) {
        return 1;
    }
    /* Release GPIOs & Exti */
    for (uint8_t i = 0; i < device_tab[dev_id].udev.gpio_num; ++i) {
        gpio_release_gpio(&device_tab[dev_id].udev.gpios[i]);
        if (device_tab[dev_id].udev.gpios[i].exti_trigger != GPIO_EXTI_TRIGGER_NONE) {
            exti_disable(device_tab[dev_id].udev.gpios[i].kref);
        }
    }
    /* Release interrupts */
    for (uint8_t i = 0; i < MIN(device_tab[dev_id].udev.irq_num, MAX_IRQS); ++i)
    {
        NVIC_DisableIRQ((uint32_t) device_tab[dev_id].udev.irqs[i].irq - 0x10);
        clear_interrupt_handler(device_tab[dev_id].udev.irqs[i].irq);
        
        KERNLOG(DBG_INFO, "Disabled IRQ %x, for device %s\n",
            device_tab[dev_id].udev.irqs[i].irq,
            device_tab[dev_id].udev.name);
    }

    /* Release the device */
    device_tab[dev_id].status = DEV_STATE_NONE;
    device_tab[dev_id].task_id = ID_UNUSED;
    device_tab[dev_id].devinfo = NULL;
    return 0;
}

/*
** This function should be called by syscall sys_init(INIT_LOCK).
** This behavior:
** 1) forces user tasks to use this syscall, locking any future sys_init usage
** 2) enable all devices of the task at one single moment, at the end of init
*/
uint8_t dev_enable_device(e_device_id  dev_id)
{
    if (device_tab[dev_id].status != DEV_STATE_REGISTERED) {
        KERNLOG(DBG_ERR, "dev_enable_device(): device status is not DEV_REGISTERED\n");
        return 1;
    }

    /* Enable GPIOs if needed */
    dev_enable_gpio(dev_id);

    /* Enable associated IRQs */
    for (uint8_t i = 0; i < MIN(device_tab[dev_id].udev.irq_num, MAX_IRQS); ++i)
    {
        NVIC_EnableIRQ((uint32_t) device_tab[dev_id].udev.irqs[i].irq - 0x10);
        KERNLOG(DBG_INFO, "Enabled IRQ %x, for device %s\n",
            device_tab[dev_id].udev.irqs[i].irq,
            device_tab[dev_id].udev.name);
    }

    /* Enable device itself (RCC, etc.) */
    if (device_tab[dev_id].devinfo != NULL) {
        /* some device may not need an RCC line, like the SoC embedded flash. For
         * these devices, there is no need for clock line activation. In this
         * very case, rcc_enbr and rcc_enb are set to 0 in the json device tree */
        if (device_tab[dev_id].devinfo->rcc_enr != 0) {
            soc_devmap_enable_clock (device_tab[dev_id].devinfo);
        }
        KERNLOG(DBG_INFO, "Enabled device %s\n", device_tab[dev_id].udev.name);
    }

    /* Device is not tagged as enabled */
    device_tab[dev_id].status = DEV_STATE_ENABLED;
    if (device_tab[dev_id].udev.map_mode == DEV_MAP_AUTO) {
        device_tab[dev_id].is_mapped = true;
    }
    return 0;
}

/*
** Enable all GPIOs of a given device
*/
uint8_t dev_enable_gpio(e_device_id  dev_id)
{
    for (int i = 0; i < MIN(device_tab[dev_id].udev.gpio_num, MAX_GPIOS); ++i) {
        gpio_enable_gpio(&device_tab[dev_id].udev.gpios[i]);
        if (device_tab[dev_id].udev.gpios[i].exti_trigger != GPIO_EXTI_TRIGGER_NONE) {
            exti_enable(device_tab[dev_id].udev.gpios[i].kref);
        }
    }
    return 0;
}

/************************************************************************
 * Device slotting functions
 * These functions manage the devices kernel vector
 ***********************************************************************/

e_device_id dev_get_free_device_slot(e_task_id task_id, device_t *udev)
{
    for (uint8_t i = ID_DEV1; i < ID_DEV_MAX; ++i) {
        if (device_tab[i].status == DEV_STATE_NONE) {
            device_tab[i].task_id = task_id;
            device_tab[i].status  = DEV_STATE_RESERVED;
            device_tab[i].udev    = *udev;
            return i;
        }
    }
    return ID_DEV_UNUSED;
}

void dev_release_device_slot (e_device_id dev_id)
{
    device_tab[dev_id].task_id = ID_UNUSED;
    device_tab[dev_id].devinfo = NULL;
    device_tab[dev_id].status  = DEV_STATE_NONE;
}

/************************************************************************
 * Device package initialization function and subfunctions
 ***********************************************************************/

e_task_id dev_get_task_from_gpio_kref(gpioref_t kref)
{
    /*
     * We loop on all devices to find the given GPIO kref
     */
    for (uint8_t i = ID_DEV1; i < ID_DEV_MAX; ++i) {
        /* No more devices, just leave loop */
        if (device_tab[i].status == DEV_STATE_NONE) {
            break;
        }
        for (uint8_t gpio = 0; gpio < device_tab[i].udev.gpio_num; ++gpio) {
            if (device_tab[i].udev.gpios[gpio].kref.val == kref.val) {
                return device_tab[i].task_id;
            }
        }
    }
    return ID_UNUSED;
}

/**
 * device package initialization function
 */
void dev_init(void)
{
    for (int i = 0; i < ID_DEV_MAX; ++i) {
        device_tab[i].task_id = ID_UNUSED;
        device_tab[i].status  = DEV_STATE_NONE;
    }
}


/************************************************************************
 * Checking if the user defined device is sound.
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

retval_t dev_sanitize_user_defined_irq
    (device_t *udev, dev_irq_info_t irqinfo, e_task_id task_id)
{
    if ((irqinfo.handler == NULL) ||
        (!sanitize_is_pointer_in_txt_slot(irqinfo.handler, task_id)))
    {
        return FAILURE;
    }

    if (irqinfo.irq < USER_IRQ_MIN || irqinfo.irq > USER_IRQ_MAX) {
        return FAILURE;
    }

    if ((irqinfo.mode == IRQ_ISR_FORCE_MAINTHREAD) &&
        (!perm_ressource_is_granted(PERM_RES_TSK_FISR, task_id))) {
        return FAILURE;
    }

    for (int i=0; i<DEV_MAX_PH_INSTR; i++) {
        switch (irqinfo.posthook.action[i].instr) {
            case IRQ_PH_NIL:
                break;
            case IRQ_PH_READ:
                KERNLOG(DBG_INFO, "detecting PH_READ posthook for irq %x\n", irqinfo.irq);
                if ((irqinfo.posthook.action[i].read.offset > udev->size - 4) ||
                    (irqinfo.posthook.action[i].read.offset % 4)) {
                    return FAILURE;
                }
                break;
            case IRQ_PH_WRITE:
                KERNLOG(DBG_INFO, "detecting PH_WRITE posthook for irq %x\n", irqinfo.irq);
                if ((irqinfo.posthook.action[i].write.offset > udev->size - 4) ||
                    (irqinfo.posthook.action[i].write.offset % 4)) {
                    return FAILURE;
                }
                break;
            case IRQ_PH_AND:
                KERNLOG(DBG_INFO, "detecting PH_AND posthook for irq %x\n", irqinfo.irq);
                if ((irqinfo.posthook.action[i].and.offset_dest > udev->size - 4)
                    || (irqinfo.posthook.action[i].and.offset_dest % 4)) {
                    return FAILURE;
                }
                if ((irqinfo.posthook.action[i].and.offset_src > udev->size - 4)
                    || (irqinfo.posthook.action[i].and.offset_src % 4)) {
                    return FAILURE;
                }
                break;
            case IRQ_PH_MASK:
                KERNLOG(DBG_INFO, "detecting PH_MASK posthook for irq %x\n", irqinfo.irq);
                if ((irqinfo.posthook.action[i].mask.offset_dest > udev->size - 4)
                    || (irqinfo.posthook.action[i].mask.offset_dest % 4)) {
                    return FAILURE;
                }
                if ((irqinfo.posthook.action[i].mask.offset_src > udev->size - 4)
                    || (irqinfo.posthook.action[i].mask.offset_src % 4)) {
                    return FAILURE;
                }
                if ((irqinfo.posthook.action[i].mask.offset_mask > udev->size - 4)
                    || (irqinfo.posthook.action[i].mask.offset_mask % 4)) {
                    return FAILURE;
                }
                break;
            default:
                return FAILURE;
        }
    }

    return SUCCESS;
}


retval_t dev_sanitize_user_defined_gpio
    (device_t *udev __attribute__((unused)), dev_gpio_info_t gpioinfo,
     e_task_id task_id)
{
    if ((gpioinfo.exti_trigger != GPIO_EXTI_TRIGGER_NONE) &&
        (!perm_ressource_is_granted(PERM_RES_DEV_EXTI, task_id)))
    {
        return FAILURE;
    }

    if ((gpioinfo.exti_handler != NULL) &&
        (!sanitize_is_pointer_in_txt_slot(gpioinfo.exti_handler, task_id)))
    {
        return FAILURE;
    }

    return SUCCESS;
}


retval_t dev_sanitize_user_device (device_t *udev, e_task_id task_id)
{
    struct device_soc_infos  *devinfo = NULL;
    retval_t ret;

    if (udev->address == 0 && udev->size == 0) {
        KERNLOG(DBG_INFO,
            "Registering a device with no memory mapping %s\n", udev->name);
    } else {
        devinfo = soc_devmap_find_device(udev->address, udev->size);
        if (devinfo == NULL) {
            KERNLOG(DBG_ERR, "Device %s not found\n", udev->name);
            return FAILURE;
        }
        if (!perm_ressource_is_granted(devinfo->minperm, task_id)) {
            KERNLOG(DBG_ERR, "Task %d requiring device %s without associated permissions\n", task_id, udev->name);
            return FAILURE;
        }
    }

    udev->name[15] = '\0';

    if (udev->irq_num > MAX_IRQS) {
        KERNLOG(DBG_ERR, "device %s : invalid udev.irq_num value (%d)\n",
            udev->name, udev->irq_num);
        return FAILURE;
    }

    if (udev->gpio_num > MAX_GPIOS) {
        KERNLOG(DBG_ERR, "device %s : invalid udev.gpio_num value (%d)\n",
            udev->name, udev->gpio_num);
        return FAILURE;
    }

    for (int i = 0; i < udev->irq_num; ++i) {
        ret = dev_sanitize_user_defined_irq(udev, udev->irqs[i], task_id);
        if (ret != SUCCESS) {
            KERNLOG(DBG_ERR, "device %s : invalid udev.irqs parameters\n",
                udev->name);
            return FAILURE;
        }
    }

    for (int i = 0; i < udev->gpio_num; ++i) {
        ret = dev_sanitize_user_defined_gpio(udev, udev->gpios[i], task_id);
        if (ret != SUCCESS) {
            KERNLOG(DBG_ERR, "device %s : invalid udev.gpios parameters\n",
                udev->name);
            return FAILURE;
        }
    }
    if (udev->map_mode == DEV_MAP_VOLUNTARY) {
        if (!perm_ressource_is_granted(PERM_RES_MEM_DYNAMIC_MAP, task_id)) {
            KERNLOG(DBG_ERR, "device %s : voluntary device map not permited\n",
                udev->name);
            return FAILURE;
        }
    }

    return SUCCESS;
}

