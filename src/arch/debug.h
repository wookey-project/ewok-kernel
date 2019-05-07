/* \file debug.c
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
#ifndef DEBUG_H_
#define DEBUG_H_

#include "autoconf.h"
#ifdef CONFIG_ARCH_CORTEX_M4
#include "m4-systick.h"
#else
#error "no systick support for other by now!"
#endif
#include "soc-usart.h"

/**
 * This is the DBGLOG log levels definition. This is syslog compatible
 */
typedef enum {
    DBG_EMERG = 0,
    DBG_ALERT = 1,
    DBG_CRIT = 2,
    DBG_ERR = 3,
    DBG_WARN = 4,
    DBG_NOTICE = 5,
    DBG_INFO = 6,
    DBG_DEBUG = 7,
} e_dbglevel_t;

/**
 * dbg_log - log strings in ring buffer
 * @fmt: format string
 */
int dbg_log(const char *fmt, ...);

/**
 * menuconfig controlled debug print
 */
#define DEBUG(level, fmt, ...) {  \
  if (level <= CONFIG_DBGLEVEL) {  dbg_log(fmt, __VA_ARGS__); dbg_flush(); } \
}

void debug_console_init(void);

/**
 * dbg_flush - flush the ring buffer to UART
 */
void dbg_flush(void);

/**
 * panic - output string on UART, flush ring buffer and stop
 * @fmt: format string
 */
void panic(char *fmt, ...);

#define assert(EXP)									\
	do {										\
		if (!(EXP))								\
			panic("Assert in file %s on line %d\n", __FILE__, __LINE__);	\
	} while (0)

#if DEBUG_LVL >= 3
#define LOG(fmt, ...) dbg_log("%lld: [II] %s:%d, %s:"fmt, get_ticks(), __FILE__, __LINE__,  __FUNCTION__, ##__VA_ARGS__)
#else
#define LOG(fmt, ...) do {} while (0)
#endif

#if DEBUG_LVL >= 2
#define WARN(fmt, ...) dbg_log("%lld: [WW] %s:%d, %s:"fmt, get_ticks(), __FILE__, __LINE__,  __FUNCTION__, ##__VA_ARGS__)
#else
#define WARN(fmt, ...) do {} while (0)
#endif

#if DEBUG_LVL >= 1
extern volatile int logging;
#define ERROR(fmt, ...)							\
	do {									\
		dbg_log("%lld: [EE] %s:%d, %s:"fmt, get_ticks(), __FILE__, __LINE__,  __FUNCTION__, ##__VA_ARGS__);	\
		/*if (logging)*/							\
			dbg_flush();						\
	} while (0)
#else
#define ERROR(fmt, ...) do {} while (0)
#endif

#define LOG_CL(fmt, ...) dbg_log(""fmt, ##__VA_ARGS__)

void init_ring_buffer(void);

#endif /* !DEBUG_H_ */
