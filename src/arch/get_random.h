#ifndef __GET_RANDOM_H__
#define __GET_RANDOM_H__

#include "C/soc-rng.h"

retval_t    get_random(unsigned char *buf, uint16_t len);
retval_t    get_random_u32(uint32_t * random);

#endif                          /* __GET_RANDOM_H__ */
