/*
 * Copyright (c) 2026 Yuichi Nakamura (@yunkya2)
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

#ifndef ZUSBFDDRV_INTERNAL_H
#define ZUSBFDDRV_INTERNAL_H

#include <stdint.h>
#include <x68k/tsr.h>
#include <x68k/dos_internal.h>
#include "zusbfddrv.h"

//****************************************************************************
// Type definitions
//****************************************************************************

#define MAX_DRIVE 4

struct resident_state {
  uint32_t magic;
  int units;
  int8_t channels[MAX_DRIVE];
  char letters[MAX_DRIVE];
};

//****************************************************************************
// Global variables
//****************************************************************************

extern int8_t zusb_channels[MAX_DRIVE];
extern int active_units;
extern const struct dos_bpb *bpbtable[MAX_DRIVE];

extern struct dos_dpb dpbs[MAX_DRIVE];
extern struct resident_state state;

//****************************************************************************
// Function prototypes
//****************************************************************************

// zusbfddrv.c

int connect_fdd(int unit, char *product, int product_size);
void initialize_drive(int unit);

// zusbfddrv_main.c

int zusbfddrv_initialize(struct dos_req_header *req);

#endif /* ZUSBFDDRV_INTERNAL_H */
