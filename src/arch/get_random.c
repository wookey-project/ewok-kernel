/* \file get_random.c
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

#include "libc.h"
#include "get_random.h"

retval_t get_random(unsigned char *buf, uint16_t len)
{
    uint16_t    i;
    uint32_t    random;

    /* First, set the buffer to zero */
    memset(buf, 0, len);

    /* Generate as much random as necessary */
    for (i = 0;
         i < sizeof(uint32_t) * (len / sizeof(uint32_t));
         i += sizeof(uint32_t))
    {
        if (soc_rng_manager((uint32_t *) (&(buf[i])))) {
            goto err;
        }
    }

    if ((len - i) > (int16_t) sizeof(uint32_t)) {
        /* We should not end here ... */
        goto err;
    }

    /* Handle the remaining bytes */
    if (i < len) {
        if (soc_rng_manager((&random))) {
            goto err;
        }
        while (i < len) {
            buf[i] = (random >> (8 * (len - i))) & 0xff;
            i++;
        }
    }

    return SUCCESS;
err:
    return FAILURE;
}

uint32_t get_random_u32(void)
{
    uint32_t random = 0;
    get_random((unsigned char *)&random, 4);
    return random;
}
