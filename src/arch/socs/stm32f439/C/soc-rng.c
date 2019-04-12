/* \file soc-rng.c
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
#include "soc-rcc.h"
#include "soc-rng.h"
#include "debug.h"

/**
 * @brief Initialize RNG (mainly initialize it clock).
 *
 * @param nothing
 * @return nothing
 */
static void rng_init(void)
{
    set_reg_bits(r_CORTEX_M_RCC_AHB2ENR, RCC_AHB2ENR_RNGEN);

    return;
}

/**
 * @brief Run the random number genrator.
 *
 * Run the RNG to get a random number. return 0 if
 * generation is completed, or an error code if not.
 *
 * As explained in FIPS PUB, we discard the first
 * random number generated and compare each generation
 * to the next one. Each number has to be compared to
 * previous one and generation fails if they're equal.
 *
 * @param  random Random number buffer.
 * @return 0 if success, error code is failure.
 */
static volatile unsigned int rng_enabled = 0;
static volatile unsigned int not_first_rng = 0;
static volatile uint32_t last_rng = 0;

static int soc_rng_init(void)
{
    rng_init();
    rng_enabled = 1;
    /* Enable random number generation */
    set_reg(r_CORTEX_M_RNG_CR, 1, RNG_CR_RNGEN);
    /* Wait for the RNG to be ready */
    while (!(read_reg_value(r_CORTEX_M_RNG_SR) & RNG_SR_DRDY_Msk)) {
    };
    /* Check for error */
    if (read_reg_value(r_CORTEX_M_RNG_SR) & RNG_SR_CEIS_Msk) {
        return 2;
    } else if (read_reg_value(r_CORTEX_M_RNG_SR) & RNG_SR_SEIS_Msk) {
        return 3;
    }
    return 0;
}

static uint8_t rng_run(uint32_t * random)
{
    /* Enable RNG clock if needed */
    if (rng_enabled == 0) {
        return soc_rng_init();
    }
    /* Read random number */
    else if (read_reg_value(r_CORTEX_M_RNG_SR) & RNG_SR_DRDY_Msk) {
        *random = read_reg_value(r_CORTEX_M_RNG_DR);
        if ((not_first_rng == 0) || (last_rng == *random)) {
            /* FIPS PUB test of current with previous random
             * and discard the first random.
             */
            last_rng = *random;
            not_first_rng = 1;
            return 4;
        } else {
            last_rng = *random;
            return 0;
        }
    } else {
        return 3;
    }
}

/**
 * \brief Handles clock error (CEIS bit read as '1').
 */
static void rng_ceis_error(void)
{
    /* Check that clock controller is correctly configured */
    LOG("[Clock error\n");
    /* Clear error */
    set_reg(r_CORTEX_M_RNG_SR, 0, RNG_SR_CEIS);
}

/**
 * \brief Handles seed error (SEIS bit read as '1').
 *
 * Seed error, we should not read the random number provided.
 */
static void rng_seis_error(void)
{
    LOG("SEIS (seed) error\n");
    /* Clear error */
    set_reg(r_CORTEX_M_RNG_SR, 0, RNG_SR_SEIS);
    /* Clear and set RNGEN bit to restart the RNG */
    set_reg(r_CORTEX_M_RNG_CR, 0, RNG_CR_RNGEN);
    set_reg(r_CORTEX_M_RNG_CR, 1, RNG_CR_RNGEN);
}

static void rng_fips_error(void)
{
    LOG("FIPS PUB warning: current random is the same as the previous one (or it is the first one)\n");
}

static void rng_unknown_error(void)
{
    ERROR("Unknown error happened (maybe data wasn't ready?)\n");
}

/**
 * @brief Launch a random number generation and handles errors.
 *
 * @param random Random number buffer
 */
int soc_rng_manager(uint32_t * random)
{
    uint8_t ret;
    bool seed_ok = false;

    while (!seed_ok) {
        ret = rng_run(random);
        switch (ret) {
            case 0:
                seed_ok = true;
                break;
            case 1:
                rng_ceis_error();
                break;
            case 2:
                rng_seis_error();
                /* We have a seed error, discard the random and run again! */
                break;
            case 3:
                rng_unknown_error();
                break;
            case 4:
                rng_fips_error();
                break;
            default:
                /* ret is non-zero. This should never happend */
                return -1;
                break;
        }
    }
    return 0;
}
