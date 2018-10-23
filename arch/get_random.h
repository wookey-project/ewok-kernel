#ifndef __GET_RANDOM_H__
#define __GET_RANDOM_H__

#include "soc-rng.h"

int get_random(unsigned char *buf, uint16_t len);

int get_random_u32(uint32_t *random);

#endif /* __GET_RANDOM_H__ */
