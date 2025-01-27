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
#include <ctype.h>
#include <setjmp.h>

#include <x68k/iocs.h>
#include <x68k/dos.h>

#include <zusb.h>
#include <scsi_cmd.h>

#include "zusbscsi.h"

//****************************************************************************
// Constants
//****************************************************************************

#define MAX_DRIVE     4     // 最大ドライブ数
#define DEV_TIMEOUT   500   // SCSIデバイス タイムアウト時間 (10ms単位)

// MSC接続で使用するendpoint

#define EP_BULK_IN    0
#define EP_BULK_OUT   1

static zusb_endpoint_config_t epcfg[ZUSB_N_EP] = {
    { ZUSB_DIR_IN,  ZUSB_XFER_BULK, 0 },
    { ZUSB_DIR_OUT, ZUSB_XFER_BULK, 0 },
    { 0, 0, -1 },
};

//****************************************************************************
// Global variables
//****************************************************************************

struct dos_req_header *reqheader;         // Human68kからのリクエストヘッダ

extern void *scsiiocs_org;                // ベクタ変更前のIOCS _SCSIDRV処理アドレス
extern uint8_t zusbscsi_mask;             // ZUSB MOドライバのSCSI ID処理マスク
extern uint8_t zusb_selected;             // SCSI IOCSがZUSB MOドライバを選択中か
extern void scsiiocs_zusb();              // 変更後のIOCS _SCSIDRV処理

extern struct zusb_unit zusb_unit[MAX_DRIVE];

//****************************************************************************
// Static variables
//****************************************************************************

static jmp_buf jenv;                      // ZUSB通信エラー時のジャンプ先
struct zusb_unit *zu;

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

//----------------------------------------------------------------------------
// Command & data transfer
//----------------------------------------------------------------------------

typedef struct __attribute__((packed)) zusb_msc_cbw  {
  uint_le32_t signature;
  uint_le32_t tag;
  uint_le32_t total_bytes;
  uint8_t dir;
  uint8_t lun;
  uint8_t cmd_len;
  uint8_t command[16];
} zusb_msc_cbw_t;

typedef struct __attribute__((packed)) zusb_msc_csw {
  uint_le32_t signature;
  uint_le32_t tag;
  uint_le32_t data_residue;
  uint8_t status;
} zusb_msc_csw_t;

#define ZUSB_MSC_CBW_SIGNATURE      0x43425355      // 'CBSU'

// データの転送完了を待つ
static int waitep(int epno)
{
  struct iocs_time tm1, tm2;
  tm1 = _iocs_ontime();
  while (!(zusb->stat & (1 << epno))) {
    tm2 = _iocs_ontime();
    int t = tm2.sec - tm1.sec;
    if (t < 0) {
      tm1 = _iocs_ontime();
    } else if (t >= DEV_TIMEOUT) {
      DPRINTF(" timeout\r\n");
      return -1;
    }
  }
  return 0;
}

// ZUSBからのエラーをチェックして、デバイスが外された場合は非接続状態にする
static int devcheck(int res)
{
  if ((res < 0) && ((zusb->err & 0xff) == ZUSB_ENODEV)) {
   DPRINTF("no such device\r\n");
   longjmp(jenv, -1);    // デバイスが存在しない -- USBデバイスが切り離された
  }
  return res;
}

// USBデータ転送を行って転送完了まで待つ
static int send_submit_wait(int epno, void *buf, int count)
{
  zusb_set_ep_region(epno, buf, count);
  zusb_send_cmd(ZUSB_CMD_SUBMITXFER(epno));
  return devcheck(waitep(epno));
}

// SCSI Command Block Wrapperを送信する
static int send_cbw(const void *cmd, size_t cmd_len, int dir, size_t data_len)
{
  zusb_msc_cbw_t *cbw = (zusb_msc_cbw_t *)&zusbbuf[0];
  cbw->signature = zusb_htole32(ZUSB_MSC_CBW_SIGNATURE);
  cbw->tag = zusb_htole32(0x12345678);
  cbw->total_bytes = zusb_htole32(data_len);
  cbw->dir = dir;
  cbw->lun = 0;
  cbw->cmd_len = cmd_len;
  memcpy(cbw->command, cmd, cmd_len);
  return send_submit_wait(EP_BULK_OUT, cbw, sizeof(*cbw));
}

// SCSI Command Status Wrapperを受信する
static int receive_csw(void)
{
  zusb_msc_csw_t *csw = (zusb_msc_csw_t *)&zusbbuf[0];
  int res = send_submit_wait(EP_BULK_IN, csw, sizeof(*csw));
  DPRINTF(":residue=%d status=%02x", zusb_le32toh(csw->data_residue), csw->status);
  return (res == 0) ? csw->status : res;
}

//----------------------------------------------------------------------------
// USB device connection
//----------------------------------------------------------------------------

// デバイスの接続処理を行う
static int connect_msc(void)
{
  int devid = 0;

  DPRINTF("connect_msc:\r\n");

  // MSC, SCSI transparent command set, Bulk-only transport
  while (devid = zusb_find_device_with_devclass(ZUSB_CLASS_MSC, 0x06, 0x50, devid)) {
    DPRINTF("devid=%d ", devid);
    zusb_desc_device_t *ddev = (zusb_desc_device_t *)zusbbuf;
    if (zusb_get_descriptor(zusbbuf) > 0 &&
        ddev->bDescriptorType == ZUSB_DESC_DEVICE) {
      if ((zu->vid && zu->pid) &&
          ((zu->vid != zusb_le16toh(ddev->idVendor)) ||
           (zu->pid != zusb_le16toh(ddev->idProduct)))) {
        DPRINTF("VID/PID mismatch (%04x:%04x != %04x:%04x)\r\n", zu->vid, zu->pid, 
                zusb_le16toh(ddev->idVendor), zusb_le16toh(ddev->idProduct));
        continue;   // VID,PID指定があるのに一致しない場合
      }
      zu->iProduct = ddev->iProduct;
    }

    // 見つかったデバイスに接続する
    if (zusb_connect_device(devid, 1, ZUSB_CLASS_MSC, 0x06, 0x50, epcfg) <= 0) {
      DPRINTF("connectinon failure. skip\r\n");
      continue;
    }

    int msc_scsi_sendcmd(const void *cmd, int cmd_len, int dir, void *buf, int size);

    // SCSI Inquiryコマンドを送ってperipheral device typeを調べる
    struct iocs_inquiry inq;
    scsi_inquiry_t cmd_inquiry = {
      .cmd_code = SCSI_CMD_INQUIRY,
      .alloc_length = sizeof(inq),
    };
    int res = msc_scsi_sendcmd(&cmd_inquiry, sizeof(cmd_inquiry), ZUSB_DIR_IN, &inq, sizeof(inq));
    if (res != 0) {
      DPRINTF("inquiry error\r\n");
      zusb_disconnect_device();
      continue;
    }

    DPRINTF("type=%02x\r\n", inq.unit);
    if (!(inq.unit == 0x05 || inq.unit == 0x07) ||
        (zu->devtype != 0 && zu->devtype != inq.unit)) {
      // デバイスタイプがCD-ROMでもMOでもない または 指定されたデバイスタイプと一致しない
      DPRINTF("device type mismatch\r\n");
      zusb_disconnect_device();
      continue;
    }
    zu->devtype = inq.unit;
    zu->devid = devid;
    return 0;
  }

  DPRINTF("device not found\r\n");
  return -1;
}

//----------------------------------------------------------------------------
// MSC SCSI command
//----------------------------------------------------------------------------

#define XFERSIZE    2048    // 1回のZUSBコマンドの転送単位 (セクタ長の倍数 && ZUSBBUFサイズ内)

// 指定したエンドポイントを使ってMSCにSCSIコマンドを送る
int msc_scsi_sendcmd(const void *cmd, int cmd_len, int dir, void *buf, int size)
{
  int res;
  int len;
  int residue = size;
  int total = 0;
  int ep = dir ? EP_BULK_IN : EP_BULK_OUT;

  DPRINTF("sendcmd");
  for (int i = 0; i < cmd_len; i++) {
    DPRINTF(" %02x", ((uint8_t *)cmd)[i]);
  }

  while (1) {
    if (setjmp(jenv)) {
      // USBデバイスが切り離された
      zusb_disconnect_device();
      zu->devid = -1;
      if (connect_msc() < 0) {
        return -1;  // 再接続に失敗したのでエラー終了
      } else {
        continue;   // 再接続できたのでやり直し
      }
    }

    if (send_cbw(cmd, cmd_len, dir ? ZUSB_DIR_IN : ZUSB_DIR_OUT, size) < 0) {
      DPRINTF(":C:err=%x\r\n", zusb->err);
      return -1;
    }

    while (residue > 0) {
      len = residue > XFERSIZE ? XFERSIZE : residue;

      if (!dir) {   // host to device - 書き込みデータをUSBバッファに転送
        memcpy(&zusbbuf[0x100], buf, len);
      }

      if (send_submit_wait(ep, &zusbbuf[0x100], len) < 0) {
        DPRINTF(":B:err=%x\r\n", zusb->err);
        break;
      }

      res = zusb->pcount[ep];
      residue -= res;
      total += res;
      if (res != len) {
        break;
      }

      if (dir) {  // device to host - 読み出したデータをUSBバッファから転送
        memcpy(buf, &zusbbuf[0x100], res);
      }
      buf += res;
    }

    if (size != total) {
      DPRINTF(":insufficient data %d != %d", size, total);
      zusb_send_cmd(ZUSB_CMD_CLEARHALT(ep));
      waitep(ep);
    }

    if ((res = receive_csw()) != 0) {
      DPRINTF(":R:err=%x\r\n", zusb->err);
      return 2;   // check condition
    }

    DPRINTF(":stat=%d\r\n", res);
    return 0;
  }
}

//----------------------------------------------------------------------------
// Utility function
//----------------------------------------------------------------------------

unsigned long hextoul(const char *p, char **endp)
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

  _dos_print("\r\nX68000 Z USB Pseudo SCSI IOCS driver version " GIT_REPO_VERSION "\r\n");

  /*
    オプション書式
        /id<SCSI ID>              このSCSI IDをZUSB MSCで利用 最初に見つかったdevice type 5 or 7のデバイス
        /id<SCSI ID>:MO           このSCSI IDをdevice type 7 (MO drive) で使用
        /id<SCSI ID>:CD           このSCSI IDをdevice type 5 (CD-ROM drive) で使用
        /id<SCSI ID>:<VID>:<PID>  このSCSI IDを指定したVID, PIDのデバイスで使用
  */

  memset(&zusb_unit, 0, sizeof(zusb_unit));
  for (int i = 0; i < MAX_DRIVE; i++) {
    zusb_unit[i].scsiid = -1;
    zusb_unit[i].devid = -1;
  }

  // コマンドラインパラメータを解析する
  int ch;
  int units = 0;
  char *p = (char *)req->status;
  while (*p++ != '\0')    // デバイスドライバ名をスキップする
    ;
  while (*p != '\0') {
    if (*p == '/' || *p == '-') {
      p++;
      if ((p[0] | 0x20) == 'i') {
        if ((p[1] | 0x20) != 'd') {
          p += strlen(p) + 1;
          continue;
        }
        p += 2;
      }
      int scsiid = *p++ - '0';
      if (scsiid >= 0 && scsiid < 7) {
        if ((ch = zusb_open_protected()) < 0) {
          _dos_print("ZUSB デバイスが見つかりません\r\n");
          for (int i = 0; i < MAX_DRIVE; i++) {
            if (zusb_unit[i].scsiid >= 0) {
              zusb_set_channel(i);
              zusb_close();
            }
          }
          return 0x700d;
        }
        zu = &zusb_unit[ch];
        zu->scsiid = scsiid;
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
    p += strlen(p) + 1;
  }

  if (units == 0) {
    _dos_print("接続デバイスが指定されていません\r\n");
    return 0x700d;
  }

  // リモートHDSドライバ用にIOCS _SCSIDRV処理を変更する
  scsiiocs_org = _iocs_b_intvcs(0x01f5, scsiiocs_zusb);

  int disp = false;
  for (int i = 0; i < MAX_DRIVE; i++) {
    zu = &zusb_unit[i];
    if (zu->scsiid < 0) {
      continue;     // このユニットにはSCSI IDは割り当てられていない
    }
    zusb_set_channel(i);
    if (connect_msc() < 0) {
      // 指定のデバイスに接続できなかったのでチャネルを閉じる
      zusb_close();
      zu->scsiid = -1;
      zu->devid = -1;
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
    for (int i = 0; i < MAX_DRIVE; i++) {
      if (zusb_unit[i].scsiid >= 0) {
        zusb_set_channel(i);
        zusb_close();
      }
    }
    _dos_print("指定されたデバイスに接続できません\r\n");
    return 0x700d;
  }

  extern char _end;
  req->addr = &_end;

  return 0;
}

//****************************************************************************
// ZUSB SCSI IOCS call
//****************************************************************************

#define SPC_PSNS_IO   0x01
#define SPC_PSNS_CD   0x02
#define SPC_PSNS_MSG  0x04
#define SPC_PSNS_BSY  0x08
#define SPC_PSNS_SEL  0x10
#define SPC_PSNS_ATN  0x20
#define SPC_PSNS_ACK  0x40
#define SPC_PSNS_REQ  0x80

int zusbscsi(uint32_t d1, uint32_t d2, uint32_t d3, uint32_t d4, uint32_t d5, void *a1)
{
  int res = 0;

  DPRINTF("zusbscsi[%02x]", d1);
  DPRINTF("d2=%d d3=%d d4=%d d5=%d a1=%p", d2, d3, d4, d5, a1);

  if (d1 == 0x01 || d1 == 0x02 || d1 >= 0x20) {
    zu = NULL;
    for (int i = 0; i < MAX_DRIVE; i++) {
      if (zusb_unit[i].scsiid == (d4 & 7)) {
        zu = &zusb_unit[i];
        zusb_set_channel(i);
        DPRINTF(" ch=%u\r\n", i);
        break;
      }
    }
  } else {
    DPRINTF("\r\n");
  }

  if (d1 != 0x00 && zu == NULL) {
    return -1;
  }

  static uint8_t scsi_cmd[16];
  static int scsi_cmd_len = -1;
  static int scsi_psns = 0;
  static int scsi_sts = 0;

  switch (d1) {
  case 0x00: // _S_RESET
    break;

  case 0x01: // _S_SELECT
  case 0x02: // _S_SELECTA
    scsi_cmd_len = -1;
    scsi_psns = SPC_PSNS_REQ|SPC_PSNS_BSY|SPC_PSNS_CD;
    scsi_sts = 0;
    break;

  case 0x03: // _S_CMDOUT
    scsi_cmd_len = (d3 > sizeof(scsi_cmd)) ? sizeof(scsi_cmd) : d3;
    memcpy(scsi_cmd, a1, scsi_cmd_len);
    scsi_psns = SPC_PSNS_REQ|SPC_PSNS_BSY;
    break;

  case 0x04: // _S_DATAIN
  case 0x0b: // _S_DATAINI
    if (scsi_cmd_len > 0) {
      scsi_sts = msc_scsi_sendcmd(scsi_cmd, scsi_cmd_len, ZUSB_DIR_IN, a1, d3);
      scsi_cmd_len = -1;
      scsi_psns = SPC_PSNS_REQ|SPC_PSNS_BSY|SPC_PSNS_CD|SPC_PSNS_IO;
      res = (scsi_sts < 0) ? -1 : 0;
    } else {
      res = -1;
    }
    break;

  case 0x05: // _S_DATAOUT
  case 0x0c: // _S_DATAOUTI
    if (scsi_cmd_len > 0) {
      scsi_sts = msc_scsi_sendcmd(scsi_cmd, scsi_cmd_len, ZUSB_DIR_OUT, a1, d3);
      scsi_cmd_len = -1;
      scsi_psns = SPC_PSNS_REQ|SPC_PSNS_BSY|SPC_PSNS_CD|SPC_PSNS_IO;
      res = (scsi_sts < 0) ? -1 : 0;
    } else {
      res = -1;
    }
    break;

  case 0x06: // _S_STSIN
    if (scsi_cmd_len > 0) {
      scsi_sts = msc_scsi_sendcmd(scsi_cmd, scsi_cmd_len, 0, NULL, 0);
      scsi_cmd_len = -1;
      res = (scsi_sts < 0) ? -1 : 0;
    }
    *(uint8_t *)a1 = scsi_sts;
    scsi_psns = SPC_PSNS_REQ|SPC_PSNS_BSY|SPC_PSNS_CD|SPC_PSNS_IO;
    break;

  case 0x07: // _S_MSGIN
    *(uint8_t *)a1 = 0;
    scsi_psns = 0;
    zu = NULL;
    zusb_selected = false;
    break;

  case 0x08: // _S_MSGOUT
    break;

  case 0x09: // _S_PHASE
    res = scsi_psns;
    break;

  case 0x20: // _S_INQUIRY
  {
    scsi_inquiry_t cmd_inquiry = {
      .cmd_code = SCSI_CMD_INQUIRY,
      .alloc_length = d3,
    };
    res = msc_scsi_sendcmd(&cmd_inquiry, sizeof(cmd_inquiry), ZUSB_DIR_IN, a1, d3);
    break;
  }

  case 0x21: // _S_READ
  case 0x26: // _S_READEXT
  case 0x2e: // _S_READI
  {
    DPRINTF("Read #%06x %04x %d:", d2, d3, d5);

    scsi_read10_t cmd_readwrite = {
      .cmd_code     = SCSI_CMD_READ_10,
      .lba          = d2,
      .block_count  = d3,
    };
    res = msc_scsi_sendcmd(&cmd_readwrite, sizeof(cmd_readwrite), ZUSB_DIR_IN, a1, d3 * (256 << d5));
    break;
  }

  case 0x22: // _S_WRITE
  case 0x27: // _S_WRITEEXT
  {
    DPRINTF("Write #%06x %04x %d:", d2, d3, d5);

    scsi_read10_t cmd_readwrite = {
      .cmd_code     = SCSI_CMD_WRITE_10,
      .lba          = d2,
      .block_count  = d3,
    };
    res = msc_scsi_sendcmd(&cmd_readwrite, sizeof(cmd_readwrite), ZUSB_DIR_OUT, a1, d3 * (256 << d5));
    break;
  }

  case 0x28: // _S_VERIFYEXT
  {
    DPRINTF("Verify #%06x %04x %d:", d2, d3, d5);

    scsi_verify10_t cmd_verify = {
      .cmd_code     = SCSI_CMD_VERIFY_10,
      .lba          = d2,
      .block_count  = d3,
    };
    res = msc_scsi_sendcmd(&cmd_verify, sizeof(cmd_verify), ZUSB_DIR_OUT, a1, d3 * (256 << d5));
    break;
  }

  case 0x23: // _S_FORMAT
  {
    scsi_format_unit_t cmd_format_unit = {
      .cmd_code = SCSI_CMD_FORMAT_UNIT,
      ._reserved1 = d3 >> 8,
      .ffmt = d3 & 0xff,
    };
    res = msc_scsi_sendcmd(&cmd_format_unit, sizeof(cmd_format_unit), 0, NULL, 0);
    break;
  }

  case 0x24: // _S_TESTUNIT
  {
    scsi_test_unit_ready_t cmd_test_unit_ready = {
      .cmd_code = SCSI_CMD_TEST_UNIT_READY,
    };
    res = msc_scsi_sendcmd(&cmd_test_unit_ready, sizeof(cmd_test_unit_ready), 0, NULL, 0);
    break;
  }

  case 0x25: // _S_READCAP
  {
    scsi_read_capacity10_t cmd_read_capacity = {
      .cmd_code = SCSI_CMD_READ_CAPACITY_10,
    };
    res = msc_scsi_sendcmd(&cmd_read_capacity, sizeof(cmd_read_capacity), ZUSB_DIR_IN, a1, 8);
    break;
  }

  case 0x29: // _S_MODESENSE
  {
    scsi_mode_sense6_t cmd_mode_sense = {
      .cmd_code = SCSI_CMD_MODE_SENSE_6,
      .page_code = d2,
      .alloc_length = d3,
    };

    res = msc_scsi_sendcmd(&cmd_mode_sense, sizeof(cmd_mode_sense), ZUSB_DIR_IN, a1, d3);
    if (res == 2 && zu->devtype == 0x05 && d2 == 0x3f) {
      /*
        USB CD-ROMドライブへのワークアラウンド

        SCSI MODE SENSEコマンドに応答を返さないドライブがある
        計測技研のCD-ROMドライバ(CDDEV.SYS)などはドライブに対してMODE SENSEを発行しないので
        問題なく動作するが、SUSIE.XがMODE SENSEの結果でwrite protectの有無を判断しているため
        応答を返さないとSUSIEのCD-ROMドライバが動作しない

        device typeがCD-ROMにMODE SENSEで全パラメータを要求してエラーになった場合
        ダミーデータを返して正常終了したことにする
        (CD-ROMなので常にwrite protect状態で問題ない)
      */
      memset(a1, 0, d3);
      ((uint8_t *)a1)[2] = 0x80;  // write protect
      res = 0;
    }
    break;
  }

  case 0x2a: // _S_MODESELECT
  {
    scsi_mode_select6_t cmd_mode_select = {
      .cmd_code = SCSI_CMD_MODE_SELECT_6,
      .flag_1 = d2,
      .alloc_length = d3,
    };
    res = msc_scsi_sendcmd(&cmd_mode_select, sizeof(cmd_mode_select), ZUSB_DIR_OUT, a1, d3);
    break;
  }

  case 0x2b: // _S_REZEROUNIT
  {
    scsi_rezero_unit_t cmd_rezero_unit = {
      .cmd_code = SCSI_CMD_REZERO_UNIT,
    };
    res = msc_scsi_sendcmd(&cmd_rezero_unit, sizeof(cmd_rezero_unit), 0, NULL, 0);
    break;
  }

  case 0x2c: // _S_REQUEST
  {
    scsi_request_sense_t cmd_request_sense = {
      .cmd_code = SCSI_CMD_REQUEST_SENSE,
      .alloc_length = d3,
    };

    memset(a1, 0xff, d3);
    res = msc_scsi_sendcmd(&cmd_request_sense, sizeof(cmd_request_sense), ZUSB_DIR_IN, a1, d3);
    break;
  }

  case 0x2d: // _S_SEEK
  {
    scsi_seek_t cmd_seek = {
      .cmd_code = SCSI_CMD_SEEK,
      .lba_msb = d2 >> 16,
      .lba = d2,
    };
    res = msc_scsi_sendcmd(&cmd_seek, sizeof(cmd_seek), 0, NULL, 0);
    break;
  }

  case 0x2f: // _S_STARTSTOP
  {
    scsi_start_stop_unit_t cmd_start_stop_unit = {
      .cmd_code     = SCSI_CMD_START_STOP_UNIT,
      .power_condition = d3 & 3,
    };
    res = msc_scsi_sendcmd(&cmd_start_stop_unit, sizeof(cmd_start_stop_unit), 0, NULL, 0);
    break;
  }

  case 0x31: // _S_REASSIGN
  {
    scsi_reassign_blocks_t cmd_reassign_blocks = {
      .cmd_code = SCSI_CMD_REASSIGN_BLOCKS,
    };
    res = msc_scsi_sendcmd(&cmd_reassign_blocks, sizeof(cmd_reassign_blocks), ZUSB_DIR_OUT, a1, d3);
    break;
  }

  case 0x32: // _S_PAMEDIUM
  {
    scsi_prevent_allow_medium_removal_t cmd_pamedium = {
      .cmd_code = SCSI_CMD_PREVENT_ALLOW_MEDIUM_REMOVAL,
      .prevent  = d3 & 1,
    };
    res = msc_scsi_sendcmd(&cmd_pamedium, sizeof(cmd_pamedium), 0, NULL, 0);
    break;
  }

  default:
    res = -1;
    break;
  }

  DPRINTF("res=%d\r\n", res);
  return res;
}

//****************************************************************************
// Dummy program entry
//****************************************************************************

void _start(void)
{}
