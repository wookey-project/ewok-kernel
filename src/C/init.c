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


/* Specific Ada runtime elaboration code */
extern void kernelinit(void);
extern void ewok_main(int, char**);

#if __GNUC__
#if __clang__
# pragma clang optimize off
#else
__attribute__ ((optimize("-fno-stack-protector")))
#endif
#endif
int main(int argc, char *args[])
{
    /* Specific Ada runtime elaboration code */
    kernelinit();

    /* Main Ada kernel code */
    ewok_main (argc, args);
    return 1;
}
#if __clang__
# pragma clang optimize on
#endif
