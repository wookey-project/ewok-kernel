/* \file stack_check.c
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
#include "debug.h"
#include "get_random.h"

/* Global variable holding the stack canary value */
volatile uint32_t __stack_chk_guard = 0;

/* Initialize the stack guard with a random value
 * Note: of course, this function must NOT be enforced
 * with stack protection! Hence the specific optimization attribute.
 */
__attribute__((optimize("-fno-stack-protector","-O0"))) void init_stack_chk_guard(void){
	uint32_t random;
	if (get_random((unsigned char*)&random, sizeof(uint32_t)) != SUCCESS) {
		panic("Failed to initialize the check guard ...");
	}

	/* This operation must not be optimized, hence the -O0 in the optimization
	 * flag!
	 */
	__stack_chk_guard = random;

	LOG("The new stack canary is %x\n", __stack_chk_guard);

	return;
}

void __stack_chk_fail(void){
	/* We have failed to check our stack canary */
	panic("Failed to check the stack guard ...");

	return;
}
