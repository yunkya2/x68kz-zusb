/*
 * Copyright (c) 2025 Yuichi Nakamura (@yunkya2)
 *
 * The MIT License (MIT)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#ifndef _XFNC_H_
#define _XFHC_H_

#include <stdint.h>

//****************************************************************************
// Defines for X-BASIC external function
//****************************************************************************

// 関数に渡される引数の型
#define XFNC_TYPE_FLOAT         0
#define XFNC_TYPE_INT           1
#define XFNC_TYPE_CHAR          2
#define XFNC_TYPE_STR           3
#define XFNC_TYPE_NOTUSED       -1

// パラメータブロックのパラメータID
#define XFNC_PARAM_FLOAT        0x0001
#define XFNC_PARAM_INT          0x0002
#define XFNC_PARAM_CHAR         0x0004
#define XFNC_PARAM_STR          0x0008

#define XFNC_PARAM_PTR          0x0010
#define XFNC_PARAM_ARRAY1       0x0030
#define XFNC_PARAM_ARRAY2       0x0050
#define XFNC_PARAM_OMIT         0x0080
#define XFNC_PARAM_RET          0x8000

#define XFNC_PARAM_FLOAT_PTR    (XFNC_PARAM_FLOAT|XFNC_PARAM_PTR)
#define XFNC_PARAM_INT_PTR      (XFNC_PARAM_INT|XFNC_PARAM_PTR)
#define XFNC_PARAM_CHAR_PTR     (XFNC_PARAM_CHAR|XFNC_PARAM_PTR)
#define XFNC_PARAM_STR_PTR      (XFNC_PARAM_STR|XFNC_PARAM_PTR)

#define XFNC_PARAM_FLOAT_OMIT   (XFNC_PARAM_FLOAT|XFNC_PARAM_OMIT)
#define XFNC_PARAM_INT_OMIT     (XFNC_PARAM_INT|XFNC_PARAM_OMIT)
#define XFNC_PARAM_CHAR_OMIT    (XFNC_PARAM_CHAR|XFNC_PARAM_OMIT)
#define XFNC_PARAM_STR_OMIT     (XFNC_PARAM_STR|XFNC_PARAM_OMIT)

#define XFNC_PARAM_FLOAT_OMIT_PTR   (XFNC_PARAM_FLOAT|XFNC_PARAM_OMIT|XFNC_PARAM_PTR)
#define XFNC_PARAM_INT_OMIT_PTR     (XFNC_PARAM_INT|XFNC_PARAM_OMIT|XFNC_PARAM_PTR)
#define XFNC_PARAM_CHAR_OMIT_PTR    (XFNC_PARAM_CHAR|XFNC_PARAM_OMIT|XFNC_PARAM_PTR)
#define XFNC_PARAM_STR_OMIT_PTR     (XFNC_PARAM_STR|XFNC_PARAM_OMIT|XFNC_PARAM_PTR)

#define XFNC_PARAM_ARRAY1_ALL   (XFNC_PARAM_ARRAY1|0x0f)
#define XFNC_PARAM_ARRAY1_INT   (XFNC_PARAM_ARRAY1|XFNC_PARAM_INT)
#define XFNC_PARAM_ARRAY1_FIC   (XFNC_PARAM_ARRAY1|XFNC_PARAM_FLOAT|XFNC_PARAM_INT|XFNC_PARAM_CHAR)
#define XFNC_PARAM_ARRAY1_CHAR  (XFNC_PARAM_ARRAY1|XFNC_PARAM_CHAR)
#define XFNC_PARAM_ARRAY2_CHAR  (XFNC_PARAM_ARRAY2|XFNC_PARAM_CHAR)

#define XFNC_PARAM_RET_FLOAT    (XFNC_PARAM_RET|XFNC_TYPE_FLOAT)
#define XFNC_PARAM_RET_INT      (XFNC_PARAM_RET|XFNC_TYPE_INT)
#define XFNC_PARAM_RET_STR      (XFNC_PARAM_RET|XFNC_TYPE_STR)
#define XFNC_PARAM_RET_VOID     0xffff

// パラメータ受け渡し用 Floating Accumulator
typedef struct xfnc_fac {
  int16_t type;
  union {
    double f;
    struct { uint32_t i_dummy; int32_t i; };
    struct { uint32_t c_dummy; uint8_t c_dummy2[3]; uint8_t c; };
    struct { uint32_t s_dummy; uint8_t *s; };
    struct { uint32_t a_dummy; struct xfnc_array *a; };

    struct { uint32_t fp_dummy; double *fp; };
    struct { uint32_t ip_dummy; int32_t *ip; };
    struct { uint32_t cp_dummy; uint8_t *cp; };
    struct { uint32_t sp_dummy; uint8_t *sp; };
  }; 
} xfnc_fac_t;

typedef struct xfnc_array {
  uint32_t skipofst;
  uint16_t dim;
  uint16_t size;
  uint16_t maxsub;
  uint8_t data[];
} xfnc_array_t;

// 引数取得用マクロ
#define xfnc_get_fac(a)     ((xfnc_fac_t *)((long)&(a) + 2))

// 戻り値返却用マクロ
#define xfnc_return(fac) \
  __asm__ volatile ("move.l %0,%%a0" :: "a"(fac) : "%%a0"); \
  return 0;
#define xfnc_return_error(fac, errno, errmsg) \
  __asm__ volatile ("move.l %0,%%a0; move.l %1,%%a1" :: "a"(fac), "a"(errmsg) : "%%a0", "%%a1"); \
  return errno;

#endif /* _XFNC_H_ */
