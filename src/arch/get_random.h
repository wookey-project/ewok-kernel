#ifndef __GET_RANDOM_H__
#define __GET_RANDOM_H__

#include "soc-rng.h"

retval_t    get_random(unsigned char *buf, uint16_t len);
uint32_t    get_random_u32(void);

#endif                          /* __GET_RANDOM_H__ */
