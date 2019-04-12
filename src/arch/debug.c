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
#include <stdarg.h>

#include "autoconf.h"
#include "debug.h"
#include "libc.h"
#include "product.h"
#include "C/soc-usart.h"

#define BUF_SIZE	512
#define BUF_MAX		(BUF_SIZE - 1)
#define PUT_CHAR(c)					\
	ring_buffer.buf[ring_buffer.end++] = c;		\
	ring_buffer.end %= BUF_MAX;			\
	if (ring_buffer.end == ring_buffer.start) {	\
		ring_buffer.start++;			\
		ring_buffer.start %= BUF_MAX;		\
	}

#ifndef CONFIG_KERNEL_NOSERIAL
volatile int logging = CONFIG_KERNEL_CONSOLE_TXT;
#endif

cb_usart_getc_t console_getc = NULL;
cb_usart_putc_t console_putc = NULL;

static struct {
    uint32_t start;
    uint32_t end;
    char buf[BUF_SIZE];
} ring_buffer;

void init_ring_buffer(void)
{
    int i = 0;
    ring_buffer.end = 0;
    ring_buffer.start = ring_buffer.end;

    for (i = 0; i < BUF_SIZE; i++) {
        ring_buffer.buf[i] = '\0';
    }
}

#ifndef CONFIG_KERNEL_NOSERIAL
void cb_console_data_received(void)
{
    char c;
    if (console_getc == NULL) {
        panic("Error: console_getc not initialized!");
    }

    c = console_getc();


    if (logging && console_putc) {
        if (c == '\r') {
          console_putc('\r');
          console_putc('\n');
        } else {
          console_putc(c);
        }
    }
}

static usart_config_t console_config = { 0 };
#endif

void debug_console_init(void)
{
    /* init ring buffer. The ring buffer is keeped to support sys_ipc(LOG) syscalls,
     * even when no serial is activated. The ring buffer is never flushed and the
     * sys_ipc(LOG) syscall behave like writing in /dev/null.
     */
    init_ring_buffer();
#ifndef CONFIG_KERNEL_NOSERIAL
    /* Configure the USART in UART mode */
    console_config.usart = CONFIG_KERNEL_USART;
    console_config.baudrate = 115200;
    console_config.word_length = USART_CR1_M_8;
    console_config.stop_bits = USART_CR2_STOP_1BIT;
    console_config.parity = USART_CR1_PCE_DIS;
    console_config.hw_flow_control = USART_CR3_CTSE_CTS_DIS | USART_CR3_RTSE_RTS_DIS;
    console_config.options_cr1 = USART_CR1_TE_EN | USART_CR1_RE_EN | USART_CR1_UE_EN;
    console_config.callback_data_received = cb_console_data_received;
    console_config.callback_usart_getc_ptr = &console_getc;
    console_config.callback_usart_putc_ptr = &console_putc;

    /* Initialize the USART related to the console */
    soc_usart_init(&console_config);
    dbg_log("[USART%d initialized for console output, baudrate=%d]\n",
            console_config.usart, console_config.baudrate);
    dbg_flush();
#endif
}

/* functions implemented only when serial is activated */
static void write_digit(uint8_t digit)
{
    if (digit < 0xa)
        digit += '0';
    else
        digit += 'a' - 0xa;
    PUT_CHAR(digit);
}

static void itoa(unsigned long long value, uint8_t base)
{
    if (value / base == 0) {
        write_digit(value % base);
    } else {
        itoa(value / base, base);
        write_digit(value % base);
    }
}

static void copy_string(char *str, uint32_t len)
{
    uint32_t size =
        len < (BUF_MAX - ring_buffer.end) ? len : BUF_MAX - ring_buffer.end;
    strncpy(ring_buffer.buf + ring_buffer.end, str, size);
    uint32_t dist = ring_buffer.start - ring_buffer.end;
    if (ring_buffer.end < ring_buffer.start && dist < size) {
        ring_buffer.start += size - dist + 1;
        ring_buffer.start %= BUF_MAX;
    }
    ring_buffer.end += size;
    ring_buffer.end %= BUF_MAX;
    if (len - size)
        copy_string(str + size, len - size);
}

#ifndef CONFIG_KERNEL_NOSERIAL
/* flush behavior with activated serial... */
void dbg_flush(void)
{
    if (console_putc == NULL) {
        panic("Error: console_putc not initialized");
    }
    while (ring_buffer.start != ring_buffer.end) {
        console_putc(ring_buffer.buf[ring_buffer.start++]);
        ring_buffer.start %= BUF_MAX;
    }
}
#else
/* ... or in /dev/null mode */
void dbg_flush(void)
{
    ring_buffer.start = ring_buffer.end;
}
#endif


static void print(const char *fmt, va_list args)
{
    uint32_t i = 0;
    char *string;

    for (i = 0; fmt[i]; i++) {
        if (fmt[i] == '%') {
            i++;
            switch (fmt[i]) {
            case 'd':
                itoa(va_arg(args, uint32_t), 10);
                break;
            case 'x':
                PUT_CHAR('0');
                PUT_CHAR('x');
                itoa(va_arg(args, uint32_t), 16);
                break;
            case '%':
                PUT_CHAR('%');
                break;
            case 's':
                string = va_arg(args, char *);
                copy_string(string, strlen(string));
                break;
            case 'l':
                if (fmt[i + 1] == 'l' && fmt[i + 2] == 'd') {
                    itoa(va_arg(args, unsigned long long), 10);
                    i += 2;
                } else if (fmt[i + 1] == 'd') {
                    itoa(va_arg(args, unsigned long), 10);
                    i++;
                }
                break;
            case 'c':
                PUT_CHAR((unsigned char)va_arg(args, int));
                break;
            default:
                PUT_CHAR('?');
            }
        } else if (fmt[i] == '\n' && fmt[i + 1] != '\r') {
            copy_string("\n\r", 2);
        } else {
            PUT_CHAR(fmt[i]);
        }
    }
}

void dbg_log(const char *fmt, ...)
{
    va_list args;

    va_start(args, fmt);
    print(fmt, args);
    va_end(args);
}

/* WARNING: in NOSERIAL mode, panic doesn't printout any information */
void panic(char *fmt, ...)
{
    va_list args;

    va_start(args, fmt);
    print(fmt, args);
    va_end(args);
    dbg_flush();
    __asm__ volatile ("bkpt\n");
    while (1)
        continue;
}
