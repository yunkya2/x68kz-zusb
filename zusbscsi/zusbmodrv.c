/*
 * Copyright (c) 2025,2026 Yuichi Nakamura (@yunkya2)
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

#include <stdint.h>
#include <x68k/dos.h>
#include <x68k/tsr.h>
#include "zusbmodrv.h"

//****************************************************************************
// Global variables
//****************************************************************************

TSR_DEVICE(_DEV_BDEV | _DEV_IOCTRL, MODRV_NAME, interrupt);

int modrv_scsiid = -1;  // 常駐するドライバが使用するSCSI ID

// MOメディア内のSCSIデバイスドライバの読み込み用バッファ
// (0x0800から0x4000までを読み込み、先頭0x400バイトを除いて常駐させる)
// + DPB用バッファ (起動後の常駐の場合)

uint8_t driver_image[0x4000 - 0x0800] __attribute__((aligned(4)));
