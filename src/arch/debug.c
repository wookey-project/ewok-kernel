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
#include "stdarg.h"

#include "autoconf.h"
#include "debug.h"
#include "libc.h"
#include "product.h"
#include "soc-usart.h"

#define BUF_MAX		512

#ifndef CONFIG_KERNEL_NOSERIAL
volatile int logging = CONFIG_KERNEL_CONSOLE_TXT;
#endif

cb_usart_getc_t console_getc = NULL;
cb_usart_putc_t console_putc = NULL;

static struct {
    uint32_t start;
    uint32_t end;
    bool     full;
    char buf[BUF_MAX];
} ring_buffer;

void init_ring_buffer(void)
{
    /* init flags */
    int     i = 0;

    ring_buffer.end = 0;
    ring_buffer.start = ring_buffer.end;
    ring_buffer.full = false;

    /* memsetting buffer
     * NOTE: This may be useless as, in EwoK, the BSS is zeroified
     * at boot time.
     */
    for (i = 0; i < BUF_MAX; i++) {
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

static void ring_buffer_reset(void)
{
    ring_buffer.end = 0;
    ring_buffer.start = ring_buffer.end;
    ring_buffer.full = false;

    memset(ring_buffer.buf, 0x0, BUF_MAX);
}

static inline void ring_buffer_write_char(const char c)
{
    /* if the ring buffer is full when we try to put char in it,
     * the car is discared, waiting for the ring buffer to be flushed.
     */
    if (ring_buffer.full) {
        goto end;
    }
    ring_buffer.buf[ring_buffer.end] = c;
    if (((ring_buffer.end + 1) % BUF_MAX) != ring_buffer.start) {
        ring_buffer.end++;
        ring_buffer.end %= BUF_MAX;
    } else {
        /* full buffer detection */
        ring_buffer.full = true;
    }
 end:
    return;
}

/* functions implemented only when serial is activated */
static inline void ring_buffer_write_digit(uint8_t digit)
{
    if (digit < 0xa) {
        digit += '0';
        ring_buffer_write_char(digit);
    } else if (digit <= 0xf) {
        digit += 'a' - 0xa;
        ring_buffer_write_char(digit);
    }
}

static void ring_buffer_write_number(uint64_t value, uint8_t base)
{
    /* we define a local storage to hold the digits list
     * in any possible base up to base 2 (64 bits) */
    uint8_t number[64] = { 0 };
    int     index = 0;

    for (; (value / base) != 0; value /= base) {
        number[index++] = value % base;
    }
    /* finishing with most significant unit */
    number[index++] = value % base;

    /* Due to the last 'index++', index is targetting the first free cell.
     * We make it points the last *used* cell instead */
    index--;

    /* now we can print out, starting with the most significant unit */
    for (; index >= 0; index--) {
        ring_buffer_write_digit(number[index]);
    }
}

static inline void ring_buffer_write_string(char *str, uint32_t len)
{
    if (!str) {
        goto end;
    }
    for (uint32_t i = 0; (i < len) && (str[i]); ++i) {
        ring_buffer_write_char(str[i]);
    }
 end:
    return;
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

static uint8_t get_number_len(uint64_t value, uint8_t base)
{
    /* at least, if value is 0, its lenght is 1 digit */
    uint8_t len = 1;

    /* now we calculate the number of digits in the number */
    for (; (value / base) != 0; value /= base) {
        len++;
    }
    return len;
}



typedef enum {
    FS_NUM_DECIMAL,
    FS_NUM_HEX,
    FS_NUM_UCHAR,
    FS_NUM_SHORT,
    FS_NUM_LONG,
    FS_NUM_LONGLONG,
    FS_NUM_UNSIGNED,
} fs_num_mode_t;

typedef struct {
    bool    attr_0len;
    bool    attr_size;
    uint8_t size;
    fs_num_mode_t numeric_mode;
    bool    started;
    uint8_t consumed;
    uint32_t strlen;
} fs_properties_t;




static inline uint8_t print_handle_format_string(const char *fmt, va_list * args,
                                          uint8_t * consumed,
                                          uint32_t * out_str_len)
{
    fs_properties_t fs_prop = {
        .attr_0len = false,
        .attr_size = false,
        .size = 0,
        .numeric_mode = FS_NUM_DECIMAL, /*default */
        .started = false,
        .consumed = 0,
        .strlen = 0
    };

    /*
     * Sanitation
     */
    if (!fmt || !args || !consumed) {
        return 1;
    }

    /* Let parse the format string ... */
    do {
        /*
         * Handling '%' character
         */
        switch (fmt[fs_prop.consumed]) {
            case '%':
                {
                    if (fs_prop.started == false) {
                        /* starting string format parsing */
                        fs_prop.started = true;
                    } else if (fs_prop.consumed == 1) {
                        /* detecting '%' just after '%' */
                        ring_buffer_write_char('%');
                        fs_prop.strlen++;
                        /* => end of format string */
                        goto end;
                    } else {
                        /* invalid: there is content before two '%' chars
                         * in the same format_string (e.g. %02%) */
                        goto err;
                    }
                    break;
                }
            case '0':
                {
                    /*
                     * Handling '0' character
                     */
                    if (fs_prop.started == false) {
                        goto err;
                    }
                    fs_prop.attr_0len = true;
                    /* 0 must be completed with size content. We check it now */
                    while ((fmt[fs_prop.consumed + 1] >= '0') &&
                           (fmt[fs_prop.consumed + 1] <= '9')) {
                        /* getting back the size. Here only decimal values are handled */
                        fs_prop.size =
                            (fs_prop.size * 10) +
			    (fmt[fs_prop.consumed + 1] - '0');
                        fs_prop.consumed++;
                    }
                    /* if digits have been found after the 0len format string, attr_size is
                     * set to true
                     */
                    if (fs_prop.size != 0) {
                        fs_prop.attr_size = true;
                    }
                    break;
                }
            case 'd':
                {
                    /*
                     * Handling integers
                     */
                    if (fs_prop.started == false) {
                        goto err;
                    }
                    fs_prop.numeric_mode = FS_NUM_DECIMAL;
                    int     val = va_arg(*args, int);
                    uint8_t len = get_number_len(val, 10);

                    if (fs_prop.attr_size && fs_prop.attr_0len) {
                        /* we have to pad with 0 the number to reach
                         * the desired size */
                        for (uint32_t i = len; i < fs_prop.size; ++i) {
                            ring_buffer_write_char('0');
                            fs_prop.strlen++;
                        }
                    }
                    /* now we can print the number in argument */
                    ring_buffer_write_number(val, 10);
                    fs_prop.strlen += len;
                    /* => end of format string */
                    goto end;
                }
            case 'l':
                {
                    /*
                     * Handling long and long long int
                     */
                    long    lval = 0;
                    long long llval = 0;
                    uint8_t len;

                    if (fs_prop.started == false) {
                        goto err;
                    }
                    fs_prop.numeric_mode = FS_NUM_LONG;
                    /* detecting long long */
                    if (fmt[fs_prop.consumed + 1] == 'l') {
                        fs_prop.numeric_mode = FS_NUM_LONGLONG;
                        fs_prop.consumed++;
                    }
                    if (fs_prop.numeric_mode == FS_NUM_LONG) {
                        lval = va_arg(*args, long);

                        len = get_number_len(lval, 10);
                    } else {
                        llval = va_arg(*args, long long);

                        len = get_number_len(llval, 10);
                    }
                    if (fs_prop.attr_size && fs_prop.attr_0len) {
                        /* we have to pad with 0 the number to reach
                         * the desired size */
                        for (uint32_t i = len; i < fs_prop.size; ++i) {
                            ring_buffer_write_char('0');
                            fs_prop.strlen++;
                        }
                    }
                    /* now we can print the number in argument */
                    if (fs_prop.numeric_mode == FS_NUM_LONG) {
                        ring_buffer_write_number(lval, 10);
                    } else {
                        ring_buffer_write_number(llval, 10);
                    }
                    fs_prop.strlen += len;
                    /* => end of format string */
                    goto end;
                }
            case 'h': /* simplified through uint32_t cast */
            case 'u':
                {
                    /*
                     * Handling unsigned
                     */
                    if (fs_prop.started == false) {
                        goto err;
                    }
                    fs_prop.numeric_mode = FS_NUM_UNSIGNED;
                    uint32_t val = va_arg(*args, uint32_t);
                    uint8_t len = get_number_len(val, 10);

                    if (fs_prop.attr_size && fs_prop.attr_0len) {
                        /* we have to pad with 0 the number to reach
                         * the desired size */
                        for (uint32_t i = len; i < fs_prop.size; ++i) {
                            ring_buffer_write_char('0');
                            fs_prop.strlen++;
                        }
                    }
                    /* now we can print the number in argument */
                    ring_buffer_write_number(val, 10);
                    fs_prop.strlen += len;
                    /* => end of format string */
                    goto end;
                }
            case 'p':
                {
                    /*
                     * Handling pointers. Include 0x prefix, as if using
                     * %#x format string in POSIX printf.
                     */
                    if (fs_prop.started == false) {
                        goto err;
                    }
                    uint32_t val = va_arg(*args, physaddr_t);
                    uint8_t len = get_number_len(val, 16);

                    ring_buffer_write_string("0x", 2);
                    for (uint32_t i = len; i < fs_prop.size; ++i) {
                        ring_buffer_write_char('0');
                        fs_prop.strlen++;
                    }
                    /* now we can print the number in argument */
                    ring_buffer_write_number(val, 16);
                    fs_prop.strlen += len;
                    /* => end of format string */
                    goto end;
                }

            case 'x':
                {
                    /*
                     * Handling hexadecimal
                     */
                    if (fs_prop.started == false) {
                        goto err;
                    }
                    fs_prop.numeric_mode = FS_NUM_UNSIGNED;
                    uint32_t val = va_arg(*args, uint32_t);
                    uint8_t len = get_number_len(val, 16);

                    if (fs_prop.attr_size && fs_prop.attr_0len) {
                        /* we have to pad with 0 the number to reach
                         * the desired size */
                        for (uint32_t i = len; i < fs_prop.size; ++i) {
                            ring_buffer_write_char('0');
                            fs_prop.strlen++;
                        }
                    }
                    /* now we can print the number in argument */
                    ring_buffer_write_number(val, 16);
                    fs_prop.strlen += len;
                    /* => end of format string */
                    goto end;
                }
            case 'o':
                {
                    /*
                     * Handling octal
                     */
                    if (fs_prop.started == false) {
                        goto err;
                    }
                    fs_prop.numeric_mode = FS_NUM_UNSIGNED;
                    uint32_t val = va_arg(*args, uint32_t);
                    uint8_t len = get_number_len(val, 8);

                    if (fs_prop.attr_size && fs_prop.attr_0len) {
                        /* we have to pad with 0 the number to reach
                         * the desired size */
                        for (uint32_t i = len; i < fs_prop.size; ++i) {
                            ring_buffer_write_char('0');
                            fs_prop.strlen++;
                        }
                    }
                    /* now we can print the number in argument */
                    ring_buffer_write_number(val, 8);
                    fs_prop.strlen += len;

                    /* => end of format string */
                    goto end;
                }
            case 's':
                {
                    /*
                     * Handling strings
                     */
                    if (fs_prop.started == false) {
                        goto err;
                    }
                    /* no size or 0len attribute for strings */
                    if (fs_prop.attr_size && fs_prop.attr_0len) {
                        goto err;
                    }
                    char   *str = va_arg(*args, char *);

                    /* now we can print the number in argument */
                    ring_buffer_write_string(str, strlen(str));
                    fs_prop.strlen += strlen(str);

                    /* => end of format string */
                    goto end;
                }
 
                /* none of the above. Unsupported format */
            default:
                {
                    /* should not happend, unable to parse format string */
                    goto err;
                    break;
                }

        }
        fs_prop.consumed++;
    } while (fmt[fs_prop.consumed]);
 end:
    *out_str_len += fs_prop.strlen;
    *consumed = fs_prop.consumed + 1;   /* consumed is starting with 0 */
    return 0;
 err:
    *out_str_len += fs_prop.strlen;
    *consumed = fs_prop.consumed + 1;   /* consumed is starting with 0 */
    return 1;
}


static int print(const char *fmt, va_list args, logsize_t *sizew)
{
    int     i = 0;
    uint8_t consumed = 0;
    uint32_t out_str_s = 0;

    while (fmt[i]) {
        if (fmt[i] == '%') {
            if (print_handle_format_string
                (&(fmt[i]), &args, &consumed, &out_str_s)) {
                /* the string format parsing has failed ! */
                goto err;
            }
            i += consumed;
            consumed = 0;
        } else if (fmt[i] == '\n') {
		/* carriage return and line breaks are both requested
		 * on USART line */
		ring_buffer_write_string("\r\n", 2);
		out_str_s += 2;
		i++;
	} else {
            out_str_s++;
            ring_buffer_write_char(fmt[i++]);
        }
    }
    *sizew = out_str_s;
    return 0;
 err:
    *sizew = out_str_s;
    return -1;
}

int dbg_log(const char *fmt, ...)
{
    int     res = -1;
    va_list args;
    logsize_t  len;

    /*
     * if there is some asyncrhonous printf to pass to the kernel, do it
     * before execute the current printf command
     */
    va_start(args, fmt);
    res = print(fmt, args, &len);
    va_end(args);
    if (res == -1) {
        ring_buffer_reset();
        goto err;
    }
 err:
    return res;
}

/* WARNING: in NOSERIAL mode, panic doesn't printout any information */
void panic(char *fmt, ...)
{
    va_list args;
    logsize_t  len;

    va_start(args, fmt);
    print(fmt, args, &len);
    va_end(args);
    dbg_flush();
#if CONFIG_KERNEL_PANIC_FREEZE 
    while (1)
        continue;
#elif CONFIG_KERNEL_PANIC_REBOOT
    NVIC_SystemReset();
    /* and wait... */
    while (1);
#else
    /* fallback */
    while (1)
        continue;
#endif
}
