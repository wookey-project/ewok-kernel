#ifndef _LIBC_
#define _LIBC_

#include "types.h"

/*
 * Define time to sleep (for loop)
 */
#define MICRO_TIME  	1
#define SHORT_TIME  	3
#define MEDIUM_TIME 	5
#define LONG_TIME   	6
#define DFU_TIME    	24

void *memset(void *s, int c, uint32_t n);
void *memcpy(void *dest, const void *src, uint32_t n);
uint32_t strlen(const char *s);
char *strncpy(char *dest, const char *src, uint32_t n);
char tolower (char c);
int8_t strcmp(const char *a, const char *b);
int8_t strcasecmp(const char *a, const char *b);
void sleep_intern(uint8_t length);

#endif                          /* _LIBC_ */
