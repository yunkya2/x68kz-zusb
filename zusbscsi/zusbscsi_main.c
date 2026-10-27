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

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <ctype.h>
#include <x68k/dos.h>
#include <x68k/iocs.h>
#include <x68k/tsr.h>
#include <zusb.h>
#include "zusbscsi_internal.h"

//----------------------------------------------------------------------------
// Utility function
//----------------------------------------------------------------------------

static unsigned long hextoul(const char *p, char **endp)
{
  unsigned long val = 0;
  while (1) {
    char c = tolower(*p++);
    if (c >= '0' && c <= '9') {
      val = val * 16 + c - '0';
    } else if (c >= 'a' && c <= 'f') {
      val = val * 16 + c - 'a' + 10;
    } else {
      break;
    }
  }
  if (endp) {
    *endp = (char *)p - 1;
  }
  return val;
}

// SUSIE の各ドライブに AskSDD を発行し、使用中の SCSI ID を集める
static uint8_t susie_used_ids(void)
{
  uint8_t used_ids = 0;
  for (int drive = 1; drive <= 26; drive++) {
    uint8_t signature[256];
    if (_dos_ioctrlfdctl(drive, -1, signature) != 0 ||
        memcmp(signature, "SUSIE", 5) != 0) {
      continue;
    }

    uint32_t params[8] = {0};  // pr0=0: AskSDD
    if (_dos_ioctrlfdctl(drive, 0x5355, (char *)params) == 0) {
      int scsiid = (params[0] >> 8) & 0x0f;
      if (scsiid < 8) {
        used_ids |= 1 << scsiid;
      }
    }
  }
  return used_ids;
}

//****************************************************************************
// Device driver initialization
//****************************************************************************

int zusbscsi_initialize(int argc, char **argv)
{
  _dos_print("\r\nX68000 Z USB Pseudo SCSI IOCS driver version " GIT_REPO_VERSION "\r\n");

  /*
    オプション書式
        /id<SCSI ID>              このSCSI IDをZUSB MSCで利用 最初に見つかったdevice type 5 or 7のデバイス
        /id<SCSI ID>:MO           このSCSI IDをdevice type 7 (MO drive) で使用
        /id<SCSI ID>:CD           このSCSI IDをdevice type 5 (CD-ROM drive) で使用
        /id<SCSI ID>:<VID>:<PID>  このSCSI IDを指定したVID, PIDのデバイスで使用
  */

  memset(&zusb_unit, 0, sizeof(zusb_unit));
  for (int i = 0; i < ZUSBSCSI_MAX_DRIVE; i++) {
    zusb_unit[i].scsiid = -1;
    zusb_unit[i].ch = -1;
  }

  // コマンドラインパラメータを解析する
  int ch;
  int units = 0;
  for (int arg = 0; arg < argc; arg++) {
    char *p = argv[arg];
    if (*p == '/' || *p == '-') {
      p++;
      if ((p[0] | 0x20) == 'i') {
        if ((p[1] | 0x20) != 'd') {
          continue;
        }
        p += 2;
      }
      int scsiid = *p++ - '0';
      if (scsiid >= 0 && scsiid < 7 && units < ZUSBSCSI_MAX_DRIVE) {
        if ((ch = zusb_open_protected()) < 0) {
          _dos_print("ZUSB デバイスが見つかりません\r\n");
          for (int i = 0; i < ZUSBSCSI_MAX_DRIVE; i++) {
            if (zusb_unit[i].scsiid >= 0) {
              zusb_set_channel(zusb_unit[i].ch);
              zusb_close();
            }
          }
          return 0x700d;
        }
        zu = &zusb_unit[units];
        zu->scsiid = scsiid;
        zu->ch = ch;
        units++;
        if (*p == ':') {
          p++;
          if (strchr(p, ':')) {             // /id<SCSI ID>:<VID>:<PID>
            zu->vid = hextoul(p, &p);
            p = strchr(p, ':') + 1;
            zu->pid = hextoul(p, &p);
          } else if ((*p | 0x20) == 'c') {  // /id<SCSI ID>:CD
            zu->devtype = 0x05;
          } else if ((*p | 0x20) == 'm') {  // /id<SCSI ID>:MO
            zu->devtype = 0x07;
          }
        }
      }
    }
  }

  if (units == 0) {
    _dos_print("接続デバイスが指定されていません\r\n");
    return 0x700d;
  }

  // リモートHDSドライバ用にIOCS _SCSIDRV処理を変更する
  scsiiocs_org = (void *)_iocs_b_intvcs(0x01f5, scsiiocs_zusb);

  int disp = false;
  for (int i = 0; i < ZUSBSCSI_MAX_DRIVE; i++) {
    zu = &zusb_unit[i];
    if (zu->scsiid < 0) {
      continue;     // このユニットにはSCSI IDは割り当てられていない
    }
    volatile uint8_t *scsidrvflg = (volatile uint8_t *)0x000cec;
    if (*scsidrvflg & (1 << zu->scsiid)) {
      _dos_print("SCSI ID ");
      _dos_putchar('0' + zu->scsiid);
      _dos_print(" は使用中です\r\n");
      continue;     // このSCSI IDは既に使用中
    }
    zusb_set_channel(zu->ch);
    if (connect_msc() < 0) {
      // 指定のデバイスに接続できなかったのでチャネルを閉じる
      zusb_close();
      zu->scsiid = -1;
      zu->ch = -1;
      continue;
    }

    // デバイスに接続できたのでSCSI IOCSコールで利用できるようにする
    zusbscsi_mask |= (1 << zu->scsiid);

    // 接続デバイスの情報を表示する
    if (!disp) {
      _dos_print("以下のSCSI IDでSCSI IOCSからUSBマスストレージデバイスが利用可能です\r\n");
      disp = true;
    }
    _dos_print("ID");
    _dos_putchar('0' + zu->scsiid);
    _dos_print(": ");
    switch (zu->devtype) {
    case 0x05:
      _dos_print("CD-ROMドライブ");
      break;
    case 0x07:
      _dos_print("光磁気ディスク");
      break;
    }
    if (zu->iProduct) {
      char product[256];
      product[0] = '\0';
      zusb_get_string_descriptor(product, sizeof(product), zu->iProduct);
      _dos_print(" (");
      _dos_print(product);
      _dos_print(")");
    }
    _dos_print("\r\n");
  }

  if (zusbscsi_mask == 0) {
    // IOCS _SCSIDRV処理を元に戻す
    _iocs_b_intvcs(0x01f5, scsiiocs_org);
    // 開いたZUSBデバイスを閉じる
    for (int i = 0; i < ZUSBSCSI_MAX_DRIVE; i++) {
      if (zusb_unit[i].scsiid >= 0) {
        zusb_set_channel(zusb_unit[i].ch);
        zusb_close();
      }
    }
    _dos_print("指定されたデバイスに接続できません\r\n");
    return 0x700d;
  }

  state.magic = ZUSBSCSI_STATE_MAGIC;
  state.oldvector = scsiiocs_org;
  state.newvector = scsiiocs_zusb;
  for (int i = 0; i < ZUSBSCSI_MAX_DRIVE; i++) {
    state.channels[i] = zusb_unit[i].ch;
  }
  state.mask = zusbscsi_mask;
  state.units = zusb_unit;
  tsr_setdevdata(TSR_THISDEV, &state);

  return 0;
}

//****************************************************************************
// Program entry
//****************************************************************************

int main(int argc, char **argv)
{
  int remove_requested = argc == 2 &&
      (strcmp(argv[1], "/r") == 0 || strcmp(argv[1], "-r") == 0);

  if (argc < 2 || (!remove_requested && argc > 5)) {
    _dos_print("usage: zusbscsi.x /id<n>[:MO|:CD|:<VID>:<PID>] ... | /r\r\n");
    return 1;
  }

  tsr_device_t dev = tsr_finddev(ZUSBSCSI_NAME);

  // 既に常駐している場合

  if (dev != NULL) {
    if (!remove_requested) {
      _dos_print("zusbscsi: 既に常駐しています\r\n");
      return 1;
    }

    struct zusbscsi_state *state = tsr_getdevdata(dev);
    int ssp = tsr_super(0);
    uint8_t loaded_ids = *(volatile uint8_t *)0x000cec;
    if (state == NULL || 
        state->magic != ZUSBSCSI_STATE_MAGIC ||
        !tsr_isfreeable(dev) ||
        _dos_intvcg(0x01f5) != state->newvector) {
      tsr_super(ssp);
      _dos_print("zusbscsi: 常駐解除できません\r\n");
      return 1;
    }

    // USBデバイスに割り当てたSCSI IDが使用中かどうかを確認する
    // 使用中ビットがセットされていてもそのIDをSUSIEが使用していなければ未使用とみなす
    // (SUSIEが常駐解除する際に使用中ビットをクリアしていないことへの対策)
    // (既存の他のSCSIドライバのほとんどが組み込み後の常駐解除ができないタイプなので考慮不要)
    uint8_t mask = state->mask;
    if ((loaded_ids & mask) != 0 &&
        (loaded_ids & mask & susie_used_ids()) != 0) {
      tsr_super(ssp);
      _dos_print("zusbscsi: 使用中の SCSI ID があるため常駐解除できません\r\n");
      return 1;
    }

    _iocs_b_intvcs(0x01f5, state->oldvector);
    for (int i = 0; i < ZUSBSCSI_MAX_DRIVE; i++) {
      if (state->channels[i] >= 0) {
        zusb_set_channel(state->channels[i]);
        zusb_close();
      }
    }
    if (tsr_freedev(dev) < 0) {
      tsr_super(ssp);
      _dos_print("zusbscsi: 常駐解除できません\r\n");
      return 1;
    }
    *(volatile uint8_t *)0x000cec &= ~mask;
    tsr_super(ssp);

    _dos_print("zusbscsi: 常駐解除しました\r\n");
    return 0;
  }

  // 常駐していない場合

  if (remove_requested) {
    _dos_print("zusbscsi: 常駐していません\r\n");
    return 1;
  }

  int ssp = tsr_super(0);
  int result = zusbscsi_initialize(argc - 1, argv + 1);
  tsr_super(ssp);
  if (result != 0) {
    return 1;
  }

  tsr_keepdev(NULL, 0);
}
