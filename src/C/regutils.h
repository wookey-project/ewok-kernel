/*
 * \file regutils.h
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

#ifndef REGUTILS_H_
#define REGUTILS_H_
#include "types.h"

#define REG_ADDR(addr)                      ((volatile uint32_t *)(addr))
#define REG_VALUE(reg, value, pos, mask)    ((reg)  |= (((value) << (pos)) & (mask)))

#define SET_BIT(REG, BIT)     ((REG) |= (BIT))
#define CLEAR_BIT(REG, BIT)   ((REG) &= ~(BIT))
#define READ_BIT(REG, BIT)    ((REG) & (BIT))
#define CLEAR_REG(REG)        ((REG) = (0x0))

#define ARRAY_SIZE(array, type)	(sizeof(array) / sizeof(type))

/* implicit convertion to int */
#define MIN(x, y) (((x) < (y)) ? (x) : (y))

__INLINE uint8_t min_u8(uint8_t x, uint8_t y)
{
    if (x < y)
        return x;
    else
        return y;
}

/*
 * These macros assume that the coding style (bits_name_Msk and bits_name_Pos)
 * is respected when defining registers bitfields
 */
#define set_reg(REG, VALUE, BITS)	set_reg_value(REG, VALUE, BITS##_Msk, BITS##_Pos)
#define get_reg(REG, BITS)		get_reg_value(REG, BITS##_Msk, BITS##_Pos)

__INLINE uint32_t get_reg_value(volatile const uint32_t * reg, uint32_t mask,
                                uint8_t pos);
__INLINE int8_t set_reg_value(volatile uint32_t * reg, uint32_t value,
                              uint32_t mask, uint8_t pos);

__INLINE uint32_t read_reg_value(volatile uint32_t * reg);
__INLINE uint16_t read_reg16_value(volatile uint16_t * reg);
__INLINE void write_reg_value(volatile uint32_t * reg, uint32_t value);
__INLINE void write_reg16_value(volatile uint16_t * reg, uint16_t value);

__INLINE void set_reg_bits(volatile uint32_t * reg, uint32_t value);
__INLINE void clear_reg_bits(volatile uint32_t * reg, uint32_t value);

__INLINE uint32_t to_big32(uint32_t value);
__INLINE uint16_t to_big16(uint16_t value);
__INLINE uint32_t to_little32(uint32_t value);
__INLINE uint16_t to_little16(uint16_t value);
__INLINE uint32_t from_big32(uint32_t value);
__INLINE uint16_t from_big16(uint16_t value);
__INLINE uint32_t from_little32(uint32_t value);
__INLINE uint16_t from_little16(uint16_t value);

__INLINE uint32_t get_reg_value(volatile const uint32_t * reg, uint32_t mask,
                                uint8_t pos)
{
    if ((mask == 0x00) || (pos > 31))
        return 0;

    return (uint32_t) (((*reg) & mask) >> pos);
}

__INLINE uint16_t get_reg16_value(volatile uint16_t * reg, uint16_t mask,
                                  uint8_t pos)
{
    if ((mask == 0x00) || (pos > 15))
        return 0;

    return (uint16_t) (((*reg) & mask) >> pos);
}

__INLINE int8_t set_reg_value(volatile uint32_t * reg, uint32_t value,
                              uint32_t mask, uint8_t pos)
{
    uint32_t tmp;

    if (pos > 31)
        return -1;

    if (mask == 0xFFFFFFFF) {
        (*reg) = value;
    } else {
        tmp = read_reg_value(reg);
        tmp &= ~mask;
        tmp |= (value << pos) & mask;
        write_reg_value(reg, tmp);
    }

    return 0;
}

__INLINE int8_t set_reg16_value(volatile uint16_t * reg, uint16_t value,
                                uint16_t mask, uint8_t pos)
{
    uint16_t tmp;

    if (pos > 15)
        return -1;

    if (mask == 0xFFFF) {
        (*reg) = value;
    } else {
        tmp = read_reg16_value(reg);
        tmp &= (uint16_t) ~ mask;
        tmp |= (uint16_t) ((value << pos) & mask);
        write_reg16_value(reg, tmp);
    }

    return 0;
}

__INLINE uint32_t read_reg_value(volatile uint32_t * reg)
{
    return (uint32_t) (*reg);
}

__INLINE uint16_t read_reg16_value(volatile uint16_t * reg)
{
    return (uint16_t) (*reg);
}

__INLINE void write_reg_value(volatile uint32_t * reg, uint32_t value)
{
    (*reg) = value;
}

__INLINE void write_reg16_value(volatile uint16_t * reg, uint16_t value)
{
    (*reg) = value;
}

__INLINE void set_reg_bits(volatile uint32_t * reg, uint32_t value)
{
    *reg |= value;
}

__INLINE void set_reg16_bits(volatile uint16_t * reg, uint16_t value)
{
    *reg |= value;
}

__INLINE void clear_reg_bits(volatile uint32_t * reg, uint32_t value)
{
    *reg &= (uint32_t) ~ (value);
}

__INLINE uint32_t to_big32(uint32_t value)
{
#if __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__
    return ((value & 0xff) << 24) | ((value & 0xff00) << 8)
        | ((value & 0xff0000) >> 8) | ((value & 0xff000000) >> 24);
#else
    return value;
#endif
}

__INLINE uint16_t to_big16(uint16_t value)
{
#if __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__
    return (uint16_t) ((value & 0xff) << 8) | (uint16_t) ((value & 0xff00) >>
                                                          8);
#else
    return value;
#endif
}

__INLINE uint32_t to_little32(uint32_t value)
{
#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
    return ((value & 0xff) << 24) | ((value & 0xff00) << 8)
        | ((value & 0xff0000) >> 8) | ((value & 0xff000000) >> 24);
#else
    return value;
#endif
}

__INLINE uint16_t to_little16(uint16_t value)
{
#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
    return ((value & 0xff) << 8) | ((value & 0xff00) >> 8);
#else
    return value;
#endif
}

__INLINE uint32_t from_big32(uint32_t value)
{
#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
    return value;
#else
    return ((value & 0xff) << 24) | ((value & 0xff00) << 8)
        | ((value & 0xff0000) >> 8) | ((value & 0xff000000) >> 24);
#endif
}

__INLINE uint16_t from_big16(uint16_t value)
{
#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
    return value;
#else
    return (uint16_t) ((value & 0xff) << 8) | (uint16_t) ((value & 0xff00) >>
                                                          8);
#endif
}

__INLINE uint32_t from_little32(uint32_t value)
{
#if __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__
    return value;
#else
    return ((value & 0xff) << 24) | ((value & 0xff00) << 8)
        | ((value & 0xff0000) >> 8) | ((value & 0xff000000) >> 24);
#endif
}

__INLINE uint16_t from_little16(uint16_t value)
{
#if __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__
    return value;
#else
    return ((value & 0xff) << 8) | ((value & 0xff00) >> 8);
#endif
}

#endif                          /*!REGUTILS_H_ */
