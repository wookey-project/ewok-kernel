/* \file posthook.c
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

#include "soc-usart.h"
#include "posthook.h"
#include "regutils.h"
#include "debug.h"
#include "m4-cpu.h"

uint32_t int_posthook_exec_irq
    (e_device_id dev_id, dev_irq_info_t *irq, uint32_t *regs)
{
    uint32_t    val, mask;
    bool        found;
    physaddr_t  addr = dev_get_device_addr(dev_id);

    for (int i=0; i<DEV_MAX_PH_INSTR; i++) {
        switch (irq->posthook.action[i].instr) {
            case IRQ_PH_NIL:
                break;

            case IRQ_PH_READ:
                val = read_reg_value((volatile uint32_t*)
                        (addr + irq->posthook.action[i].read.offset));
                irq->posthook.action[i].read.value = val;
                if (irq->posthook.status == irq->posthook.action[i].read.offset)
                {
                    regs[0] = val;
                }
                if (irq->posthook.data == irq->posthook.action[i].read.offset) {
                    regs[1] = val;
                }
                break;

            case IRQ_PH_WRITE:
                set_reg_value((volatile uint32_t*)
                    (addr + irq->posthook.action[i].write.offset),
                    irq->posthook.action[i].write.value,
                    irq->posthook.action[i].write.mask,
                    0);
                break;

            case IRQ_PH_AND:
                /* Retrieving the already read register value */
                found = false;
                for (int j=0;j<i;j++) {
                    if (irq->posthook.action[j].instr == IRQ_PH_READ &&
                        irq->posthook.action[j].read.offset ==
                            irq->posthook.action[i].and.offset_src)
                    {
                        val = irq->posthook.action[j].read.value;
                        found = true;
                        break;
                    }
                }

                if (found == false) {
                    val = read_reg_value((volatile uint32_t*)
                        (addr + irq->posthook.action[i].and.offset_src));
                }

                /* If there is no '1' bits in common between val and mask,
                 * mask is zero and no action is necessary */
                mask = irq->posthook.action[i].and.mask & val;

                switch (irq->posthook.action[i].and.mode) {
                    case MODE_STANDARD:
                        break;
                    case MODE_NOT:
                        val  = ~val;
                        break;
                    default:
                        break;
                }

                /* Setting the 'offset_dest' register */
                set_reg_value((volatile uint32_t*)
                    (addr + irq->posthook.action[i].and.offset_dest), val, mask, 0);

                break;

            case IRQ_PH_MASK:
                found = false;
                for (int j=0;j<i;j++) {
                    if (irq->posthook.action[j].instr == IRQ_PH_READ &&
                        irq->posthook.action[j].read.offset ==
                            irq->posthook.action[i].mask.offset_src)
                    {
                        val = irq->posthook.action[j].read.value;
                        found = true;
                        break;
                    }
                }
                if (found == false) {
                    val = read_reg_value((volatile uint32_t*)
                        (addr + irq->posthook.action[i].mask.offset_src));
                }

                found = false;
                for (int j=0;j<i;j++) {
                    if (irq->posthook.action[j].instr == IRQ_PH_READ &&
                        irq->posthook.action[j].read.offset ==
                            irq->posthook.action[i].mask.offset_mask)
                    {
                        mask = irq->posthook.action[j].read.value;
                        found = true;
                        break;
                    }
                }
                if (found == false) {
                    mask = read_reg_value((volatile uint32_t*)
                        (addr + irq->posthook.action[i].mask.offset_mask));
                }

                mask &= val;

                switch (irq->posthook.action[i].and.mode) {
                    case MODE_STANDARD:
                        break;
                    case MODE_NOT:
                        val  = ~val;
                        break;
                    default:
                        break;
                }

                set_reg_value((volatile uint32_t*)
                    (addr + irq->posthook.action[i].mask.offset_dest), val, mask, 0);
               break;

            default:
                KERNLOG(DBG_ERR, "unknown posthook instruction");
                break;
        }
    }

    return 0;
}

/*
** This function considers that the device posthook has been sanitized at
** device register time.
*/
uint32_t int_posthook_exec(uint8_t irq, uint32_t *regs)
{
    device_t       *udev;
    e_device_id     dev_id;

    dev_id = get_device_from_interrupt(irq);
    if (dev_id == ID_DEV_UNUSED) {
        goto end;
    }

    udev = dev_get_device_from_id (dev_id);

    for (uint8_t i = 0; i < udev->irq_num; ++i) {
        if (udev->irqs[i].irq == irq) {
            int_posthook_exec_irq(dev_id, &udev->irqs[i], regs);
            break;
        }
    }

end:
    return 0;
}

