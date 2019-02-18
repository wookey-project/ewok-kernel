/* \file params.h
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
#ifndef PARAM_H_
# define PARAM_H_

#include "autoconf.h"
/*
 * BLOCK_SIZE - Size of block on GoodUSB
 *
 * This size should depend on the size of SD blocks. The minimum size is 512.
 * Increasing BLOCK_SIZE should force to decrease BIG_POOL_SIZE.
 *
 * The only tested value is 512.
 */
# define BLOCK_SIZE	512

/*
 * Malloc
 */
/* FIXME: pool size must be a multiple of 32 */
# define SMALL_POOL_SIZE		CONFIG_ALLOC_POOL_SMALL
# define SMALL_POOL_BLOCK_SIZE		16

# define MEDIUM_POOL_SIZE		CONFIG_ALLOC_POOL_MEDIUM
# define MEDIUM_POOL_BLOCK_SIZE		64

# define BIG_POOL_SIZE			CONFIG_ALLOC_POOL_BIG
# define BIG_POOL_BLOCK_SIZE		BLOCK_SIZE

# define MALLOC_POOL_PROMOTION		0


/*
 * Manager
 */
# define USB_TO_CRYPTO_QUEUE_SIZE	10
# define CRYPTO_TO_SD_QUEUE_SIZE	10
# define SD_COMMANDS_QUEUE_SIZE		10
# define SD_TO_CRYPTO_QUEUE_SIZE	10
/* This queue stores 64 bytes packets so it should be at greater or equal to
 * SD_TO_CRYPTO_QUEUE_SIZE.
 */
# define CRYPTO_TO_USB_QUEUE_SIZE	128


/*
 * logs
 */
# define DUMP_STATS			1
# define DUMP_STATS_FREQ		1

#endif /* PARAM_H_ */
