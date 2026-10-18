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

#include <stdint.h>
#include <string.h>
#include <x68k/dos.h>
#include <x68k/dos_internal.h>
#include "zusbfddrv_internal.h"
#ifdef CONFIG_BOOTDRIVER
#define _dos_putchar(...)
#define _dos_print(...)
#endif

#include <zusb.h>

//****************************************************************************
// Constants
//****************************************************************************

#define BANNER "X68000 Z USB FDD device driver version " GIT_REPO_VERSION "\r\n"
#define PRODUCT_NAME_SIZE 256
#define STATE_MAGIC 0x5a464444UL

//****************************************************************************
// Private functions
//****************************************************************************

//----------------------------------------------------------------------------
// Drive message
//----------------------------------------------------------------------------

#ifndef CONFIG_BOOTDRIVER
static void print_available_drive(char letter, const char *product)
{
  _dos_print("ドライブ");
  _dos_putchar(letter);
  _dos_print(":でUSBフロッピーディスク");
  if (product != NULL && product[0] != '\0') {
    _dos_print(" (");
    _dos_print(product);
    _dos_print(") ");
  }
  _dos_print("が利用可能です\r\n");
}
#endif

//----------------------------------------------------------------------------
// Drive connection
//----------------------------------------------------------------------------

// 戻り値: 接続した台数。最初のチャネルを確保できないときは -1
static int open_drives(int units, char product_names[][PRODUCT_NAME_SIZE])
{
  int opened = 0;

  for (int i = 0; i < units; i++) {
    initialize_drive(i);
    zusb_channels[i] = zusb_open_protected();
    if (zusb_channels[i] < 0) {
      if (i == 0) opened = -1;
      break;
    }

    zusb_set_channel(zusb_channels[i]);
    char product[PRODUCT_NAME_SIZE];
    char *name = product_names != NULL ? product_names[i] : product;
    name[0] = '\0';
    if (connect_fdd(i, name, PRODUCT_NAME_SIZE) < 0) {
      zusb_close();
      zusb_channels[i] = -1;
      break;
    }
    opened++;
  }

  active_units = opened < 0 ? 0 : opened;
  return opened;
}

#ifndef CONFIG_BOOTDRIVER
// 接続済みの全チャネルを解放する
static void close_drives(void)
{
  int ssp = tsr_super(0);
  for (int i = 0; i < active_units; i++) {
    zusb_set_channel(zusb_channels[i]);
    zusb_close();
    zusb_channels[i] = -1;
  }
  tsr_super(ssp);
  active_units = 0;
}
#endif

//----------------------------------------------------------------------------
// Driver removal
//----------------------------------------------------------------------------

#ifndef CONFIG_BOOTDRIVER
static void close_channels(const struct resident_state *s)
{
  int ssp = tsr_super(0);
  for (int i = 0; i < s->units; i++) {
    zusb_set_channel(s->channels[i]);
    zusb_close();
  }
  tsr_super(ssp);
}
#endif

//----------------------------------------------------------------------------
// Parse command-line option
//----------------------------------------------------------------------------

#ifndef CONFIG_BOOTDRIVER
static int parse_option(const char *arg, int *units, int *remove_requested)
{
  if (*arg != '/' && *arg != '-') {
    return -1;
  }

  switch (*(++arg) | 0x20) {
  case 'u':         // /u<units> .. ユニット数設定
    *units = *(++arg) - '0';
    if (*units < 1 || *units > MAX_DRIVE) {
      *units = 1;
    }
    return 0;
  case 'r':         // /r .. 常駐解除
    if (remove_requested != NULL) {
      *remove_requested = 1;
    }
    return 0;
  default:
    return -1;
  }
}
#endif

//****************************************************************************
// Device driver initialization
//****************************************************************************

int zusbfddrv_initialize(struct dos_req_header *req)
{
  _dos_print("\r\n" BANNER);

  // パラメータからユニット数を取得する (/u<ユニット数>)
#ifndef CONFIG_DRIVES
  int units = 1;
#else
  int units = CONFIG_DRIVES;
#endif

#ifndef CONFIG_BOOTDRIVER
  char *p = (char *)req->status;
  while (*p != '\0') {
    parse_option(p, &units, NULL);
    p += strlen(p) + 1;
  }
  char product_names[MAX_DRIVE][PRODUCT_NAME_SIZE];
#else
  char (*product_names)[PRODUCT_NAME_SIZE] = NULL;
#endif

  units = open_drives(units, product_names);
  if (units < 0) {
    _dos_print("ZUSB デバイスが見つかりません\r\n");
    return 0x700d;
  }
  if (units == 0) {
    _dos_print("USBフロッピーディスクが接続されていません\r\n");
    return 0x700d;
  }

#ifndef CONFIG_BOOTDRIVER
  for (int i = 0; i < units; i++) {
    print_available_drive('A' + *(uint8_t *)&req->fcb + i, product_names[i]);
  }
#endif

#ifdef CONFIG_BOOTDRIVER
  /* SCSI ROM のデバイスドライバ組み込み処理から渡される値
   *「何番目のパーティションから起動するか」を Human68k のドライバ初期化処理に返す
   * この値に基づいてどのドライブから起動するか (CONFIG.SYSをどのドライブから読むか) が決まる
   */
  extern uint8_t bootpart;
  *(char *)&req->fcb = bootpart;
#endif

  active_units = units;
  req->attr = units;
  req->status = (uint32_t)bpbtable;

#ifndef CONFIG_BOOTDRIVER
  state.magic = STATE_MAGIC;
  state.units = units;
  for (int i = 0; i < units; i++) {
    state.channels[i] = zusb_channels[i];
    state.letters[i] = 'A' + *(uint8_t *)&req->fcb + i;
  }
  tsr_setdevdata(TSR_THISDEV, &state);
#endif

  extern char _tsr_end;
  req->addr = &_tsr_end;

  return 0;
}

//****************************************************************************
// Program entry
//****************************************************************************

#ifndef CONFIG_BOOTDRIVER

int main(int argc, char **argv)
{
  int units = 1;
  int remove_requested = 0;

  if (argc > 2 ||
      (argc == 2 && parse_option(argv[1], &units, &remove_requested) < 0)) {
    _dos_print("\r\n" BANNER);
    _dos_print("usage: zusbfddrv.x -u[drives] | -r\r\n");
    return 1;
  }

  tsr_device_t dev = tsr_finddev(DRIVER_NAME);

  // 既に常駐している場合

  if (dev != NULL) {
    struct resident_state *s = tsr_getdevdata(dev);
    if (s == NULL || s->magic != STATE_MAGIC ||
        s->units < 1 || s->units > MAX_DRIVE) {
      _dos_print("zusbfddrv: 常駐情報が不正です\r\n");
      return 1;
    }
    if (!remove_requested) {
      for (int i = 0; i < s->units; i++) {
        print_available_drive(s->letters[i], NULL);
      }
      return 0;
    }
    if (!tsr_isfreeable(dev) || tsr_detachdrive(dev) < 0) {
      _dos_print("zusbfddrv: ドライブが使用中のため解除できません\r\n");
      return 1;
    }
    close_channels(s);
    if (tsr_freedev(dev) < 0) {
      _dos_print("zusbfddrv: 常駐解除できません\r\n");
      return 1;
    }
    _dos_print("zusbfddrv: 常駐解除しました\r\n");
    return 0;
  }

  // 常駐していない場合

  if (remove_requested) {
    _dos_print("zusbfddrv: 常駐していません\r\n");
    return 1;
  }

  _dos_print(BANNER);

  int ssp = tsr_super(0);
  if (zusb_open(0) < 0) {
    tsr_super(ssp);
    _dos_print("ZUSB デバイスが見つかりません\r\n");
    return 1;
  } else {
    zusb_close();
    tsr_super(ssp);
  }

  char product_names[MAX_DRIVE][PRODUCT_NAME_SIZE];
  struct dos_dpb *dpb_table[MAX_DRIVE];

  ssp = tsr_super(0);
  units = open_drives(units, product_names);
  tsr_super(ssp);
  if (units < 0) {
    _dos_print("ZUSB デバイスを利用できません\r\n");
    return 1;
  }
  if (units == 0) {
    _dos_print("USBフロッピーディスクが接続されていません\r\n");
    return 1;
  }

  for (int i = 0; i < units; i++) {
    if (tsr_bpb2dpb((struct dos_bpb *)bpbtable[i], &dpbs[i]) < 0) {
      _dos_print("zusbfddrv: ディスク情報を作成できません\r\n");
      close_drives();
      return 1;
    }
    dpb_table[i] = &dpbs[i];
  }
  if (tsr_attachdrive(-1, units, dpb_table, TSR_THISDEV) < 0) {
    _dos_print("zusbfddrv: 空きドライブがありません\r\n");
    close_drives();
    return 1;
  }

  state.magic = STATE_MAGIC;
  state.units = units;
  for (int i = 0; i < units; i++) {
    int drive = tsr_getlogicaldrive(dpbs[i].drive);
    state.channels[i] = zusb_channels[i];
    state.letters[i] = drive >= 0 ? 'A' + drive : '?';
  }
  tsr_setdevdata(TSR_THISDEV, &state);

  for (int i = 0; i < units; i++) {
    print_available_drive(state.letters[i], product_names[i]);
  }

  tsr_keepdev(NULL, 0);
}

#endif /* !CONFIG_BOOTDRIVER */
