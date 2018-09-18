#ifndef __GET_RANDOM_H__
#define __GET_RANDOM_H__

#include "soc-rng.h"

int get_random(unsigned char *buf, uint16_t len);

#endif /* __GET_RANDOM_H__ */
