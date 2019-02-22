/* \file init.c
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

/**
 * @file main.c
 *
 * EwoK kernel main
 *
 */

#include "autoconf.h"
#include "debug.h"

#ifdef CONFIG_ARCH_CORTEX_M4
#include "m4-systick.h"
#else
#error "no systick support for other by now!"
#endif

#include "tasks.h"
#include "soc-init.h"
#include "soc-usart.h"
#include "soc-usart-regs.h"
#include "soc-layout.h"
#include "soc-interrupts.h"
#include "soc-flash.h"
#include "soc-rng.h"
#include "stack_check.h"
#include "m4-cpu.h"
#include "product.h"

#ifdef CONFIG_FPU_ENABLE
#include "m4-fpu.h"
#endif
#include "soc-dwt.h"

#include "m4-core.h"
#include "mpu.h"
#include "kernel.h"
#include "sched.h"
#include "devices.h"
#include "processor.h"
#include "softirq.h"
#include "syscalls.h"
#include "dma.h"
#include "exti.h"
#include "usart.h"
#include "get_random.h"

#define r_CORTEX_M_NVIC_ICER0	REG_ADDR(NVIC_BASE + (uint32_t)0x80)
#define NVIC_ICER		r_CORTEX_M_NVIC_ICER0


/*
  ok. I'm the kernel. This information is passed to some arch specific code of the BSP
  that is kernel specific (not generic with the loader)
*/

#ifdef CONFIG_ADAKERNEL
    /* Specific Ada runtime elaboration code */
extern void kernelinit(void);
extern void interrupts_init(void);
#endif

#define YELLOW "\x1b[1;33;40m"
#define WHITE  "\x1b[0;37;40m"

/*
 * We use the local -fno-stack-protector flag for main because
 * the stack protection has not been initialized yet.
 */
__attribute__ ((optimize("-fno-stack-protector")))
int main(int argc, char *args[])
{
    char *base_address = 0;
    uint32_t seed;

    disable_irq();

#ifdef CONFIG_ADAKERNEL
    /* Specific Ada runtime elaboration code */
    kernelinit();
    interrupts_init();
#endif
    core_systick_init();

    /* Configure the USART in UART mode, this is the kernel console initialization */
    debug_console_init();
    dbg_log(YELLOW "EWOK - Embedded lightWeight Opensource Kernel" WHITE "\n\n");
    dbg_flush();

    KERNLOG(DBG_INFO, "booting...\n");

    /*
     * Initialization of DWT. This is required for time measurement
     * (required for sys_get_systick()).
     */
    soc_dwt_init();

    /*
     * Initialize the platform TRNG, the collected seed value must
     * not be used as it is the first generated random value
     */
    if (get_random_u32(&seed) != SUCCESS) {
        ERROR("Call to the TRNG failed !\n");
        dbg_flush();
        panic("halting.\n");
    }

    /*
     * Initialize the stack protection, based on the hardware RNG device
     */
    init_stack_chk_guard();



#ifdef CONFIG_KERNEL_DMA_ENABLE
    /*
     * EwoK can be configured without DMA support. If DMA is supported, the DMA kernel
     * vector is initialized here
     */
    dma_init();
#endif

#ifdef CONFIG_FPU_ENABLE
    /*
     * If the FPU is supported, the FPU is configured and the associated IRQ handler
     * is registered here
     */
    fpu_enable();
#endif

    /*
     * Initialize the EXTI support. This is required for IT-triggered GPIOs
     */
    exti_init();

    /*
     * The kernel is a PIE executable. Its base address is given in first argument,
     * based on the loader informations
     */
    if (argc == 1) {
        base_address = (char *)args[0];
        system_init((uint32_t) base_address - VTORS_SIZE);
    } else {
        panic("Unable to get base address to support PIE");
    }

    /*
     * Let's print the first informational data on USART. Kernel remains silent when
     * DEBUG is set to 0
     */

#if CONFIG_DEBUG > 0
    /* debug mode, uart support is a kernel function, otherwise, it is a userspace app */
    KERNLOG(DBG_INFO, "Built date: %s at %s\n", __DATE__, __TIME__);
#ifdef CONFIG_STM32F4
    KERNLOG(DBG_INFO, "Board: STM32F429\n");
#else
    KERNLOG(DBG_INFO, "Board: STM32F407\n");
#endif
    KERNLOG(DBG_INFO, "==============================\n");
#endif

    /*
     * Let's configure the MPU. This is the most imortant part of the early kernel init.
     * After this sequence, the kernel is executed with the MPU activated and can generate
     * memory fault in case of invalid access.
     */
    if (mpu_kernel_init()) {
        ERROR("MPU Configuration failed !\n");
        dbg_flush();
        panic("MPU fail, halting.\n");
    }
    full_memory_barrier();

    /* create user tasks, each one has its init fn executed
     * (this function register all interrupts and devices accesses using syscalls,
     * associated devices are also initialized by this function after having registered irq/dev)
     */
    task_init();

    /* Initialize devices vector */
    dev_init();

    /* Initialize kernel devices (usart, led,...) */
    usart_init();

    /* Initialize softirq ring buffer and globals */
    softirq_init();

    /*
     * The kernel has finished its initialization, the first thread can now be executed
     */
    KERNLOG(DBG_INFO, "==============================\n");

    /*
     * Now that the kernel has finished to initialized tasks context, let's update
     * the systick handler to execute the sheduler
     */

    /*
     * scheduling initialization (registering of PendSV and Systick handlers, initialization
     * and sched subsystem and execution of the first thread) is done now.
     * The first thread is IDLE. It will wait for any interrupt, waiting for the first systick
     * which will generate the first effective scheduling.
     */
    sched_init();

    /*
     * There is no more kernel thread after this point. sched_init never returns. Any execution
     * of the bellowing lines is an abnormal event.
     */
    panic("Why am I here ?\n");

    return 0;
}
