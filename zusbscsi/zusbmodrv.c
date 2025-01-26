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

#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <stdbool.h>
#include <stdarg.h>
#include <string.h>
#include <setjmp.h>

#include <x68k/iocs.h>
#include <x68k/dos.h>

#include <zusb.h>
#include <scsi_cmd.h>

#include "zusbscsi.h"

//****************************************************************************
// Constants
//****************************************************************************

//****************************************************************************
// Global variables
//****************************************************************************

struct dos_req_header *reqheader;         // Human68kからのリクエストヘッダ

struct zusb_unit *zusb_unit = NULL;

//****************************************************************************
// Static variables
//****************************************************************************

//****************************************************************************
// for debugging
//****************************************************************************

#ifdef DEBUG
#include <x68k/iocs.h>
char heap[1024];                // temporary heap for debug print
void *_HSTA = heap;
void *_HEND = heap + 1024;
void *_PSP;

void DPRINTF(char *fmt, ...)
{
  char buf[256];
  va_list ap;

  va_start(ap, fmt);
  vsiprintf(buf, fmt, ap);
  va_end(ap);
#ifndef DEBUG_UART
  _iocs_b_print(buf);
#else
  char *p = buf;
  while (*p) {
    while (_iocs_osns232c() == 0)
      ;
    _iocs_out232c(*p++);
  }
#endif
}
#else
#define DPRINTF(...)
#endif

//****************************************************************************
// Private functions
//****************************************************************************

//****************************************************************************
// Device driver interrupt rountine
//****************************************************************************

int interrupt(void)
{
  uint16_t err = 0;
  struct dos_req_header *req = reqheader;

  // Initialize以外はエラー
  if (req->command != 0x00) {
    return 0x700d;
  }

  _dos_print("\r\nX68000 Z USB Mass Storage Device Driver version " GIT_REPO_VERSION "\r\n");

  // コマンドラインパラメータからSCSI IDを取得する
  int scsiid = -1;
  char *p = (char *)req->status;
  while (*p++ != '\0')    // デバイスドライバ名をスキップする
    ;
  while (*p != '\0') {
    if (*p == '/' || *p =='-') {
      p++;
      if ((p[0] | 0x20) == 'i') {
        if ((p[1] | 0x20) != 'd') {
          p += strlen(p) + 1;
          continue;
        }
        p += 2;
      }
      scsiid = *p++ - '0';
      if (scsiid >= 0 && scsiid < 7) {
        scsiid = -1;
      }
    }
    p += strlen(p) + 1;
  }

  // 組み込み済みのZUSB SCSIドライバを探す
  const char *devh = (const char *)0x006800;
  while (memcmp(devh, "NUL     ", 8) != 0) {
    devh += 2;
  }
  devh -= 14;
  do {
    const char *p = devh + 14;
    if (memcmp(p, "/ZUSCSI/", 8) == 0) {
      zusb_unit = &(*(struct zusb_unit **)(p - 4))[-4];
      break;
    }
    devh = *(const char **)devh;
  } while (devh != (char *)-1);

  if (zusb_unit == NULL) {
    _dos_print("ZUSB SCSIドライバが組み込まれていません\r\n");
    return 0x700d;
  }

  // ZUSB SCSIドライバから利用可能なUSBマスストレージデバイスを探す
  volatile uint8_t *scsidrvflg = (volatile uint8_t *)0x000cec;
  if (scsiid < 0) {
    for (int i = 0; i < 4; i++) {
      if (zusb_unit[i].scsiid >= 0 && zusb_unit[i].devtype != 0x05) {
        if (*scsidrvflg & (1 << zusb_unit[i].scsiid)) {
          continue; // 既にドライバを組み込み済みなのでスキップする
        }
        scsiid = zusb_unit[i].scsiid;
        break;
      }
    }
  }
  if (scsiid < 0) {
    _dos_print("ZUSB SCSIドライバから利用可能なUSBマスストレージデバイスが接続されていません\r\n");
    return 0x700d;
  }
  if (*scsidrvflg & (1 << scsiid)) {
    _dos_print("指定されたSCSI IDは既にドライバを読み込み済みです\r\n");
    return 0x700d;
  }

  // USBマスストレージデバイスがX68kフォーマットされているかチェックする
  extern char _end[];
  struct iocs_readcap cap;

  if (_iocs_s_readcap(scsiid, &cap) != 0) {
    _dos_print("USBマスストレージデバイスからのドライバ読み込みに失敗しました\r\n");
    return 0x700d;
  }
  int blocksize = 0;
  int s = cap.size >> 8;
  while (!(s & 1)) {
      blocksize++;
      s >>= 1;
  }

  if (_iocs_s_read(0, 1, scsiid, blocksize, _end) != 0) {
    _dos_print("USBマスストレージデバイスからのドライバ読み込みに失敗しました\r\n");
    return 0x700d;
  }
  if (memcmp(_end, "X68SCSI1", 8) != 0) {
    _dos_print("X68kフォーマットされていないメディアです\r\n");
    return 0x700d;
  }

  // SCSIデバイスドライバを読み込む (0x0c00 - 0x4000)
  // (一旦0x0800-を読んで0x0c00-の内容を使う(2048bytes/sector対策))
  if (_iocs_s_read(0x0800 >> (blocksize + 8),
                   (0x4000 - 0x0800) >> (blocksize + 8),
                   scsiid, blocksize, &_end) != 0) {
    _dos_print("USBマスストレージデバイスからのドライバ読み込みに失敗しました\r\n");
    return 0x700d;
  }
  memcpy(_end, &_end[0x0400], 0x4000 - 0x0c00);

  struct devheader {
    uint32_t next;
    uint16_t type;
    uint32_t strategy;
    uint32_t interrupt;
    uint8_t name[8];
    uint8_t part;
    uint8_t _reserved[3];    
  };

  // SCSIデバイスドライバのstrategy/interruptルーチンをリロケーションする
  struct devheader *d = (struct devheader *)_end;
  d->strategy += (uint32_t)_end;
  d->interrupt += (uint32_t)_end;
  d->part = 1;    // パーティション数

  // SCSIデバイスドライバのヘッダをこのドライバ自身のヘッダにコピーする
  extern char devheader;
  struct devheader *dfrom = (struct devheader *)_end;
  struct devheader *dto = (struct devheader *)&devheader;
  *dto = *dfrom;

  int drive = *(uint8_t *)&req->fcb;

  // SCSIデバイスドライバの初期化 (strategyルーチン呼び出し)
  __asm__ volatile(
    "movem.l %%d0-%%d7/%%a0-%%a6,%%sp@-\n"
    "movea.l %0,%%a5\n"
    "movea.l %1@(6),%%a4\n"   // strategy routine
    "jsr %%a4@\n"
    "movem.l %%sp@+,%%d0-%%d7/%%a0-%%a6\n"
    : : "a"(reqheader), "a"(_end));

  // SCSIデバイスドライバの初期化 (interruptルーチン呼び出し)
  __asm__ volatile(
    "movem.l %%d0-%%d7/%%a0-%%a6,%%sp@-\n"
    "move.l %1,%%d2\n"
    "movea.l %0@(10),%%a4\n"  // interrupt routine
    "jsr %%a4@\n"
    "movem.l %%sp@+,%%d0-%%d7/%%a0-%%a6\n"
    : : "a"(_end), "d"(scsiid + 1));

  _dos_print("ドライブ");
  _dos_putchar('A' + drive);
  _dos_print(":でSCSI ID");
  _dos_putchar('0' + scsiid);
  _dos_print("のUSBマスストレージデバイスが利用可能です\r\n");

  return 0;
}

//****************************************************************************
// Dummy program entry
//****************************************************************************

void _start(void)
{}
