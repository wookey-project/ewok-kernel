#ifndef _LIBC_
#define _LIBC_

#include "types.h"

void *memset(void *s, int c, uint32_t n);
void *memcpy(void *dest, const void *src, uint32_t n);
uint32_t strlen(const char *s);
char *strncpy(char *dest, const char *src, uint32_t n);
char tolower (char c);
int8_t strcmp(const char *a, const char *b);
int8_t strcasecmp(const char *a, const char *b);

#endif                          /* _LIBC_ */
