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
#include <stdbool.h>
#include <string.h>
#include <x68k/iocs.h>
#include <x68k/dos.h>
#include <x68k/tsr.h>
#include "zusbscsi.h"
#include "zusbmodrv.h"

//****************************************************************************
// for debugging
//****************************************************************************

#ifdef DEBUG
#include <stdio.h>
#include <stdarg.h>
#include <x68k/iocs.h>

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

static int parse_id(const char *p)
{
  if (*p != '/' && *p != '-') {
    return -1;
  }
  p++;
  if ((p[0] | 0x20) != 'i' || (p[1] | 0x20) != 'd' ||
      p[2] < '0' || p[2] > '6' || p[3] != '\0') {
    return -1;
  }
  return p[2] - '0';
}

//****************************************************************************
// Device driver initialization
//****************************************************************************

int zusbmodrv_initialize(struct dos_req_header *req, int scsiid)
{
  _dos_print("\r\nX68000 Z USB Mass Storage Device Driver version " GIT_REPO_VERSION "\r\n");

  // 組み込み済みのZUSB SCSIドライバを探す

  const struct zusbscsi_state *state;
  tsr_device_t dev = tsr_finddev(ZUSBSCSI_NAME);
  if (dev == NULL ||
      (state = tsr_getdevdata(dev)) == NULL ||
      state->magic != ZUSBSCSI_STATE_MAGIC) {
    _dos_print("ZUSB SCSIドライバが組み込まれていません\r\n");
    return 0x700d;
  }
  struct zusb_unit *zusb_unit = state->units;

  // ID指定がない場合、ZUSB SCSIドライバから利用可能なUSBマスストレージデバイスを探す

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
    _dos_print("USBマスストレージデバイスが接続されていません\r\n");
    return 0x700d;
  }

  // 指定されたIDのUSBマスストレージデバイスが存在するか確認する

  bool found = false;
  for (int i = 0; i < ZUSBSCSI_MAX_DRIVE; i++) {
    if (zusb_unit[i].scsiid == scsiid) {
      found = true;
      break;
    }
  }
  if (!found) {
    _dos_print("指定されたSCSI IDに割り当てられたUSBデバイスがありません\r\n");
    return 0x700d;
  }

  if (*scsidrvflg & (1 << scsiid)) {
    _dos_print("指定されたSCSI IDは既にドライバを読み込み済みです\r\n");
    return 0x700d;
  }
  modrv_scsiid = scsiid;

  // USBマスストレージデバイスがX68kフォーマットされているかチェックする

  struct iocs_readcap cap;

  if (_iocs_s_readcap(scsiid, &cap) != 0) {
    _dos_print("USBマスストレージデバイスからのドライバ読み込みに失敗しました\r\n");
    return 0x700d;
  }
  int blocksize = 0;
  int s = cap.size >> 8;
  if (s == 0) {
    _dos_print("未対応のセクタサイズです\r\n");
    return 0x700d;
  }
  while (!(s & 1)) {
      blocksize++;
      s >>= 1;
  }

  if (_iocs_s_read(0, 1, scsiid, blocksize, driver_image) != 0) {
    _dos_print("USBマスストレージデバイスからのドライバ読み込みに失敗しました\r\n");
    return 0x700d;
  }
  if (memcmp(driver_image, "X68SCSI1", 8) != 0) {
    _dos_print("X68kフォーマットされていないメディアです\r\n");
    return 0x700d;
  }

  // SCSIデバイスドライバを読み込む (0x0c00 - 0x4000)
  // (一旦0x0800-を読んで0x0c00-の内容を使う(2048bytes/sector対策))

  if (_iocs_s_read(0x0800 >> (blocksize + 8),
                   (0x4000 - 0x0800) >> (blocksize + 8),
                   scsiid, blocksize, driver_image) != 0) {
    _dos_print("USBマスストレージデバイスからのドライバ読み込みに失敗しました\r\n");
    return 0x700d;
  }
  memmove(driver_image, driver_image + 0x0400, 0x4000 - 0x0c00);

  // SCSIデバイスドライバのstrategy/interruptルーチンをリロケーションする
  struct dos_devheader *d = (struct dos_devheader *)driver_image;
  d->strategy += (uint32_t)driver_image;
  d->interrupt += (uint32_t)driver_image;
//  d->part = 1;    // パーティション数

  // SCSIデバイスドライバのヘッダをこのドライバ自身のヘッダにコピーする
  TSR_THISDEV->header.attr = d->attr;
  TSR_THISDEV->header.strategy = d->strategy;
  TSR_THISDEV->header.interrupt = d->interrupt;

  // SCSIデバイスドライバの初期化 (strategyルーチン呼び出し)
  __asm__ volatile(
    "movem.l %%d0-%%d7/%%a0-%%a6,%%sp@-\n"
    "movea.l %0,%%a5\n"
    "movea.l %1@(6),%%a4\n"   // strategy routine
    "jsr %%a4@\n"
    "movem.l %%sp@+,%%d0-%%d7/%%a0-%%a6\n"
    : : "a"(req), "a"(driver_image));

  // SCSIデバイスドライバの初期化 (interruptルーチン呼び出し)
  __asm__ volatile(
    "movem.l %%d0-%%d7/%%a0-%%a6,%%sp@-\n"
    "move.l %1,%%d2\n"
    "movea.l %0@(10),%%a4\n"  // interrupt routine
    "jsr %%a4@\n"
    "movem.l %%sp@+,%%d0-%%d7/%%a0-%%a6\n"
    : : "a"(driver_image), "d"(scsiid + 1));

#if 0
  dto->reserved[0] = MODRV_TAG0;
  dto->reserved[1] = MODRV_TAG1;
  dto->reserved[2] = scsiid;
#endif

  return 0;
}

//****************************************************************************
// Device driver interrupt routine
//****************************************************************************

int interrupt(struct dos_req_header *req, tsr_device_t dev)
{
  // CONFIG.SYSによるドライバの登録時のみ呼ばれる
  // 登録後はMOメディアから読み込んだSCSIデバイスドライバが使われる

  if (req->command != 0x00) {
    return 0x700d;
  }

  const char *p = (const char *)req->status;
  p += strlen(p) + 1;     // ドライバ名をスキップ
  int scsiid = (*p != '\0') ? parse_id(p) : -1;

  int drive = *(uint8_t *)&req->fcb;

  int result = zusbmodrv_initialize(req, scsiid);
  if (result != 0) {
    return result;
  }
  int units = req->attr;

  _dos_print("ドライブ");
  _dos_putchar('A' + drive);
  _dos_putchar(':');
  if (units > 1) {
    _dos_putchar('-');
    _dos_putchar('A' + drive + units - 1);
    _dos_putchar(':');
  }
  _dos_print("でSCSI ID");
  _dos_putchar('0' + modrv_scsiid);
  _dos_print("のUSBマスストレージデバイスが利用可能です\r\n");

  extern char _tsr_end;
  req->addr = &_tsr_end;
  return 0;
}

//****************************************************************************
// Program entry
//****************************************************************************

int main(int argc, char **argv)
{
  bool remove_requested = false;
  int scsiid = -1;

  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "/r") == 0 || strcmp(argv[i], "-r") == 0) {
      remove_requested = true;
    } else if ((scsiid = parse_id(argv[i])) < 0) {
      _dos_print("usage: zusbmodrv.x [/id<SCSI ID>] | /r\r\n");
      return 1;
    }
  }

  tsr_device_t dev = tsr_finddev(MODRV_NAME);

  // 既に常駐している場合

  if (dev != NULL) {
    if (!remove_requested) {
      _dos_print("既に常駐しています\r\n");
      return 1;
    }
    if (!tsr_isfreeable(dev)) {
      _dos_print("常駐解除できません\r\n");
      return 1;
    }

    int scsiid = *(int *)tsr_getdevdata(dev);

    int ssp = tsr_super(0);
    if (tsr_detachdrive(dev) < 0 || tsr_freedev(dev) < 0) {
      _dos_print("常駐解除できません\r\n");
      return 1;
    }
    *(volatile uint8_t *)0x000cec &= ~(1 << scsiid);
    tsr_super(ssp);

    _dos_print("常駐解除しました\r\n");
    return 0;
  }

  // 常駐していない場合

  if (remove_requested) {
    _dos_print("常駐していません\r\n");
    return 1;
  }

  int ssp = tsr_super(0);

  // デバイスドライバ初期化用のリクエストヘッダを作成

  struct dos_req_header req = { 0 };
  req.magic = 26;
  req.status = (uint32_t)"\0\0";
  *(uint8_t *)&req.fcb = 0;

  // デバイスドライバを初期化

  if (zusbmodrv_initialize(&req, scsiid) != 0) {
    goto rollback;
  }

  // 初期化後のドライバが返すBPBからDPBを作成する

  int units = req.attr;   // ユニット数 (パーティション数)
  struct dos_bpb **bpb_table = (struct dos_bpb **)req.status; // BPBテーブルのアドレス
  struct dos_dpb *dpb = (struct dos_dpb *)req.addr;   // ドライバの終了アドレス以降をDPBに使う
  req.addr = &dpb[units];
  struct dos_dpb **dpb_table = (struct dos_dpb **)req.addr;   // DPBのポインタ配列 (常駐後は不要)

  for (int i = 0; i < units; i++) {
    dpb_table[i] = &dpb[i];
    if (bpb_table[i] == NULL || tsr_bpb2dpb(bpb_table[i], dpb_table[i]) < 0) {
      _dos_print("ディスク情報を作成できません\r\n");
      goto rollback;
    }
  }

  // 作成したDPBを用いてブロックデバイスを追加する

  if (tsr_attachdrive(-1, units, dpb_table, TSR_THISDEV) < 0) {
    _dos_print("空きドライブがありません\r\n");
    goto rollback;
  }

  // 常駐終了する

  _dos_print("ドライブ");
  for (int i = 0; i < units; i++) {
    _dos_putchar('A' + tsr_getlogicaldrive(dpb_table[i]->drive));
    _dos_putchar(':');
    if (i < units - 1) {
      _dos_print(",");
    }
  }
  _dos_print("でSCSI ID");
  _dos_putchar('0' + modrv_scsiid);
  _dos_print("のUSBマスストレージデバイスが利用可能です\r\n");

  tsr_setdevdata(TSR_THISDEV, &modrv_scsiid);
  tsr_keepdev(req.addr, 0);

rollback:
  // エラー終了する場合に、使用中フラグを設定したSCSI IDを解放する
  if (modrv_scsiid >= 0) {
    *(volatile uint8_t *)0x000cec &= ~(1 << modrv_scsiid);
  }
  tsr_super(ssp);
  return 1;
}
