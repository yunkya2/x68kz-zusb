/*
 * Copyright (c) 2024 Yuichi Nakamura (@yunkya2)
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

#include "zusbfddrv.h"

//****************************************************************************
// Constants
//****************************************************************************

#define MAX_DRIVE     4     // 最大ドライブ数
#define RETRY_COUNT   3     // read/writeエラーのリトライ回数
#define DEV_TIMEOUT   300   // SCSIデバイス タイムアウト時間 (10ms単位)

static const struct dos_bpb known_bpb[] = {
  { 1024, 1, 2, 1, 192, 1232, 0xfe, 2, 0, },    // 2HD (1232KB)
  {  512, 1, 2, 1, 224, 2400, 0xfd, 7, 0, },    // 2HC (1200KB)
  {  512, 1, 2, 1, 224, 2880, 0xfa, 9, 0, },    // 2HQ (1440KB)
  {  512, 2, 2, 1, 112, 1280, 0xfb, 2, 0, },    // 2DD  (640KB)
  {  512, 2, 2, 1, 112, 1440, 0xfc, 3, 0, },    // 2DD  (720KB)
};

static const uint16_t sense_errcode[] = {
  0x0000,   //  0:No sense           -> (エラーなし)
  0x0001,   //  1:Recovered error    -> (メディア交換)
  0x7002,   //  2:Not ready          -> ドライブの準備が出来ていない
  0x7007,   //  3:Medium error       -> 無効なメディア
  0x700c,   //  4:Hardware error     -> その他のエラー
  0x7008,   //  5:Illegal request    -> セクタが見つからない
  0x0001,   //  6:Unit attention     -> (メディア交換)
  0x700d,   //  7:Data protect       -> ライトプロテクト
  0x700c,   //  8:Blank check        -> その他のエラー
  0x700c,   //  9:Vendor specific    -> その他のエラー
  0x700c,   // 10:Copy aborted       -> その他のエラー
  0x700c,   // 11:Aborted command    -> その他のエラー
  0x700c,   // 12:equal              -> その他のエラー
  0x700c,   // 13:Volume overflow    -> その他のエラー
  0x700c,   // 14:Miscompare         -> その他のエラー
  0x700c,   // 15:Reserved           -> その他のエラー
};

//****************************************************************************
// Global variables
//****************************************************************************

struct dos_req_header *reqheader;   // Human68kからのリクエストヘッダ

jmp_buf jenv;

int drives = 1;

extern int8_t zusb_channels[MAX_DRIVE];

struct drive {
  const struct dos_bpb **current_bpb;
  int medium_change_reported;
  int medium_write_protected;

  int last_status;
  struct iocs_time last_tm;
  int last_error;

  int devid;
  int iManufacturer;
  int iProduct;
} drive[MAX_DRIVE];

struct drive *d;

const struct dos_bpb *bpbtable[MAX_DRIVE];

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
  _iocs_b_print(buf);
}
#else
#define DPRINTF(...)
#endif

//****************************************************************************
// Private functions
//****************************************************************************

//----------------------------------------------------------------------------
// USB device connection
//----------------------------------------------------------------------------

static const zusb_endpoint_config_t epcfg_tmpl[ZUSB_N_EP] = {
    { ZUSB_DIR_IN,  ZUSB_XFER_BULK, 0 },
    { ZUSB_DIR_OUT, ZUSB_XFER_BULK, 0 },
    { ZUSB_DIR_IN,  ZUSB_XFER_INTERRUPT, 0 },
    { 0, 0, -1 },
};

#define EP_BULK_IN    0
#define EP_BULK_OUT   2
#define EP_INTERRUPT  4 

// デバイスの接続処理を行う
static int connect_fdd(void)
{
  int devid = 0;
  zusb_endpoint_config_t epcfg[ZUSB_N_EP];

  DPRINTF("connect_fdd: ");

  // MSC, UFI command set, CBI transport
  while (devid = zusb_find_device_with_devclass(ZUSB_CLASS_MSC, 0x04, 0x00, devid)) {
    zusb->devid = devid;
    zusb_desc_device_t *ddev = (zusb_desc_device_t *)zusbbuf;
    if (zusb_get_descriptor(zusbbuf) > 0 &&
        ddev->bDescriptorType == ZUSB_DESC_DEVICE) {
      d->iManufacturer = ddev->iManufacturer;
      d->iProduct = ddev->iProduct;
    }

    memcpy(epcfg, epcfg_tmpl, sizeof(epcfg));
    if (zusb_connect_device(devid, 1, ZUSB_CLASS_MSC, 0x04, 0x00, epcfg) > 0) {
      d->devid = devid;
      // エンドポイントパイプの設定
      int bulk_in = zusb->pcfg[0];
      int bulk_out = zusb->pcfg[1];
      int interrupt = zusb->pcfg[2];
      zusb->pcfg[EP_BULK_IN] = bulk_in;
      zusb->pcfg[EP_BULK_IN + 1] = bulk_in;
      zusb->pcfg[EP_BULK_OUT] = bulk_out;
      zusb->pcfg[EP_BULK_OUT + 1] = bulk_out;
      zusb->pcfg[EP_INTERRUPT] = interrupt;

      DPRINTF("%d\r\n", devid);
      return 0;
    }
  }
  DPRINTF("not ready\r\n", devid);
  return -1;
}

//----------------------------------------------------------------------------
// Command & data transfer
//----------------------------------------------------------------------------

// データの転送完了を待つ
int waitep(int epno)
{
  struct iocs_time tm1, tm2;
  tm1 = _iocs_ontime();
  while (!(zusb->stat & (1 << epno))) {
    tm2 = _iocs_ontime();
    int t = tm2.sec - tm1.sec;
    if (t >= DEV_TIMEOUT) {
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

// UFI SCSIコマンドを送信する
int send_ufi_scsicmd(void *cmd)
{
  zusb->err = 0;
  return devcheck(zusb_send_control(ZUSB_REQ_CS_IF_OUT, 0, 0, 0x00, 12, cmd));
}

// USBデータ転送を行って転送完了まで待つ
int send_ufi_submit_wait(int epno, void *buf, int count)
{
  zusb->err = 0;
  zusb_set_ep_region(epno, buf, count);
  if (devcheck(zusb_send_cmd(ZUSB_CMD_SUBMITXFER(epno))) < 0 || waitep(epno) < 0) {
    return -1;
  }
  return 0;
}

// USBデータ転送を行う
int send_ufi_zusbcmd(int cmd)
{
  zusb->err = 0;
  return devcheck(zusb_send_cmd(cmd));
}

//----------------------------------------------------------------------------
// MSC SCSI command
//----------------------------------------------------------------------------

// デバイスにREQUEST SENSEを発行してsense keyをHuman68kのエラーコードに変換して返す
int msc_scsi_reqsense(void)
{
  const scsi_request_sense_t cmd_request_sense = {
    .cmd_code     = SCSI_CMD_REQUEST_SENSE,
    .alloc_length = sizeof(scsi_request_sense_resp_t),
  };

  DPRINTF("reqsense:");

  memset(&zusbbuf[0], 0, 12);
  memcpy(&zusbbuf[0], &cmd_request_sense, sizeof(cmd_request_sense));
  if (send_ufi_scsicmd(&zusbbuf[0]) < 0) {
    DPRINTF("C:err=%x\r\n", zusb->err);
    return -1;
  }
  scsi_request_sense_resp_t *sense = (scsi_request_sense_resp_t *)&zusbbuf[0x100];
  if (send_ufi_submit_wait(EP_BULK_IN, sense, sizeof(*sense)) < 0) {
    DPRINTF("B:err=%x\r\n", zusb->err);
    return -1;
  }
  if (send_ufi_submit_wait(EP_INTERRUPT, &zusbbuf[0], 2) < 0) {
    DPRINTF("I:err=%x\r\n", zusb->err);
    return -1;
  }

  DPRINTF("result=%02x %04x\r\n", sense->sense_key & 0xf, sense_errcode[sense->sense_key & 0xf]);
  return sense_errcode[sense->sense_key & 0xf];
}

// 指定したエンドポイントを使ってMSCにSCSIコマンドを送る
int msc_scsi_sendcmd(const void *cmd, int cmd_len, int dir, void *buf, int size)
{
  int res;
  int len;
  int total = 0;
  int ep = dir ? EP_BULK_IN : EP_BULK_OUT;
  int sectbytes = (*d->current_bpb)->sectbytes;

  memset(&zusbbuf[0], 0, 12);
  memcpy(&zusbbuf[0], cmd, cmd_len);

  DPRINTF("sendcmd %02x:", zusbbuf[0]);
  if (send_ufi_scsicmd(&zusbbuf[0]) < 0) {
    // メディア交換時はここでエラーになる (ZUSB_EIO)
    DPRINTF("C:err=%x\r\n", zusb->err);
    return -1;
  }

  if (size > 0) {
    len = size > sectbytes ? sectbytes : size;
    size -= len;

    if (!dir) {   // host to device - 書き込みデータをUSBバッファに転送
      _iocs_dmamove(&zusbbuf[0x100], buf, 0x85, len);
      buf += len;
      total += len;
    }
    // 初回のデータ転送コマンドを送る
    zusb_set_ep_region(ep, &zusbbuf[0x100], len);
    send_ufi_zusbcmd(ZUSB_CMD_SUBMITXFER(ep));

    while (zusb->pcount[ep] == 0xffff) {    // コマンドの実行開始まで待つ
    }

    // 2つのエンドポイントを交互に使ってデータ転送を行う
    int side = 1;
    while (size > 0) {
      len = size > sectbytes ? sectbytes : size;
      size -= len;

      if (!dir) {   // host to device - 書き込みデータをUSBバッファに転送
        _iocs_dmamove(&zusbbuf[side ? 0x800 : 0x100], buf, 0x85, len);
        buf += len;
        total += len;
      }
      // 2回目以降のデータ転送コマンドを送る
      zusb_set_ep_region(ep + side, &zusbbuf[side ? 0x800 : 0x100], len);
      send_ufi_zusbcmd(ZUSB_CMD_SUBMITXFER(ep + side));

      // 前回のデータ転送の完了を待つ
      side = 1 - side;
      if (waitep(ep + side) < 0) {
        send_ufi_zusbcmd(ZUSB_CMD_CANCELXFER(ep + 1 - side));
        DPRINTF("B:err=%x\r\n", zusb->err);
        return -1;
      }
      if ((res = zusb->pcount[ep + side]) == 0) {
        DPRINTF("no data\r\n");
        return -1;
      }

      if (dir && res > 0) {    // device to host - 読み出したデータをUSBバッファから転送
        _iocs_dmamove(buf, &zusbbuf[side ? 0x800 : 0x100], 0x85, res);
        buf += res;
        total += res;
      }
    }

    // 最後のデータ転送の完了を待つ
    side = 1 - side;
    if (waitep(ep + side) < 0) {
      DPRINTF("B:err=%x\r\n", zusb->err);
      return -1;
    }
    if ((res = zusb->pcount[ep + side]) == 0) {
      DPRINTF("no data\r\n");
      return -1;
    }

    if (dir && res > 0) {  // device to host - 読み出したデータをUSBバッファから転送
      _iocs_dmamove(buf, &zusbbuf[side ? 0x800 : 0x100], 0x85, res);
    }
    if (total >= 0) {
      total += res;
    }
  }

  if (send_ufi_submit_wait(EP_INTERRUPT, &zusbbuf[0], 2) < 0) {
    DPRINTF("I:err=%x\r\n", zusb->err);
    return -1;
  }
  DPRINTF("stat=%02x%02x\r\n", zusbbuf[0], zusbbuf[1]);

  return total;
}

//----------------------------------------------------------------------------
// Utility function
//----------------------------------------------------------------------------

// ドライブの内部データを初期化する
int initialize_drive(void)
{
  *d->current_bpb = &known_bpb[0];    // default BPB : 2HD 1232kB
  d->medium_change_reported = false;
  d->medium_write_protected = false;
  d->last_status = 0;
  d->last_tm.day = d->last_tm.sec = 0;
  d->last_error = 0;
  d->devid = -1;
}

// メディアが交換されたかどうかをチェックする
int check_medium_change(void)
{
  int res;

  // チェックするのが前回から1秒以内なら同じ結果を返す
  if (d->medium_change_reported) {
    struct iocs_time tm = _iocs_ontime();
    if ((tm.day == d->last_tm.day) && (tm.sec - d->last_tm.sec < 100)) {
      return d->last_status;
    }
    d->last_tm = tm;
  }

  DPRINTF("check_medium_change:");

  const scsi_test_unit_ready_t cmd_test_unit_ready = {
    .cmd_code = SCSI_CMD_TEST_UNIT_READY
  };
  res = msc_scsi_sendcmd(&cmd_test_unit_ready, sizeof(cmd_test_unit_ready), ZUSB_DIR_IN, 0, 0);
  if (res == 0) {
    d->last_status = 0;     // メディアは交換されていない
    return d->last_status;
  }

  d->medium_change_reported = false;
  res = msc_scsi_reqsense();
  if (res == 0x0001) {    // メディアが交換された
    // 交換後のメディアのライトプロテクト状態を取得する
    d->medium_write_protected = 0;
    scsi_mode_sense10_resp_t resp;
    scsi_mode_sense10_t cmd_mode_sense = {
      .cmd_code     = SCSI_CMD_MODE_SENSE_10,
      .page_code    = 0x3f,
      .alloc_length = sizeof(resp),
    };
    res = msc_scsi_sendcmd(&cmd_mode_sense, sizeof(cmd_mode_sense),
                           ZUSB_DIR_IN, &resp, sizeof(resp));
    if (res >  0) {
      d->medium_write_protected = resp.wp_flag & 0x80;
    }
    d->last_status = 1;   // メディアが交換された
    return d->last_status;
  }

  d->last_status = -1;    // メディアにアクセスできない
  return d->last_status;
}

// メディアの容量を取得する
const struct dos_bpb *check_medium_capacity(void)
{
  DPRINTF("check_medium_capacity:");

  scsi_read_format_capacities_resp_t resp;
  const scsi_read_format_capacities_t cmd_read_format_capacities = {
    .cmd_code     = SCSI_CMD_READ_FORMAT_CAPACITIES,
    .alloc_length = sizeof(resp),
  };

  int res = msc_scsi_sendcmd(&cmd_read_format_capacities, sizeof(cmd_read_format_capacities),
                         ZUSB_DIR_IN, &resp, sizeof(resp));
  if (res > 0) {
    const struct dos_bpb *bpb = &known_bpb[0];    // default BPB : 2HD 1232kB
    DPRINTF("capacity=%lu %d %d\r\n", resp.block_num, resp.descriptor_type, resp.block_size);
    switch (resp.descriptor_type & 3) {
      case 1:  // unformatted media
        return bpb;

      case 2:  // formatted media
        for (int i = 0; i < sizeof(known_bpb) / sizeof(known_bpb[0]); i++) {
          if (resp.descriptor_type == 2 &&
              resp.block_size == known_bpb[i].sectbytes &&
              resp.block_num == known_bpb[i].sects) {
            DPRINTF("media byte=0x%02x\r\n", known_bpb[i].mediabyte);
            bpb = &known_bpb[i];
            break;
          }
        }
        return bpb;

      case 3:  // no media
      default:
        return NULL;
    }
  }
  return NULL;
}

// Read/Write処理
int do_read_write(uint8_t cmd, int dir, uint32_t lba, uint32_t count, void *buf)
{
  int err;

  DPRINTF("%s #%06x %04x:", (dir == ZUSB_DIR_IN) ? "Read" : "Write", lba, count);

  if (d->last_error) {
    // 前回エラーだったらメディアの交換チェックを行う
    if (check_medium_change() < 0) {  // メディアにアクセスできない
      return 0x7002;
    }
    const struct dos_bpb *bpb = check_medium_capacity();
    if (bpb != *d->current_bpb) {
      // 違う容量のディスクに交換されていたら無効なメディアエラーにする
      return 0x7007;
    }
  }

  scsi_read10_t cmd_readwrite = {
    .cmd_code     = cmd,
    .lba          = lba,
    .block_count  = count,
  };

  // Read/Write処理を行う(エラーならリトライ)
  for (int i = 0; i < RETRY_COUNT; i++) {
    int r = msc_scsi_sendcmd(&cmd_readwrite, sizeof(cmd_readwrite), dir,
                             buf, (*d->current_bpb)->sectbytes * count);
    if (r >= 0) {   // 正常終了
      d->last_error = 0;
      return 0;
    }

    // エラー
    err = msc_scsi_reqsense();
    d->last_error = err;
    if (err == 0x0001) {  // メディア交換
      i = 0;
      continue;
    }
  }
  return err;
}

//****************************************************************************
// Device driver interrupt rountine
//****************************************************************************

int interrupt(void)
{
  uint16_t err = 0;
  struct dos_req_header *req = reqheader;

  //--------------------------------------------------------------------------
  // Initialization
  //--------------------------------------------------------------------------

  if (req->command == 0x00) {
    // Initialize
    _dos_print("\r\nX68000 Z USB FDD device driver version " GIT_REPO_VERSION "\r\n");

    // パラメータからユニット数を取得する (/u<ユニット数>)
    int units = 1;
    char *p = (char *)req->status;
    while (*p != '\0') {
      if (*p == '/' || *p =='-') {
        p++;
        switch (*p | 0x20) {
        case 'u':         // /u<units> .. ユニット数設定
          units = *(++p) - '0';
          if (units < 1 || units > MAX_DRIVE) {
            units = 1;
          }
          break;
        }
      }
      p += strlen(p) + 1;
    }

    // ドライブ数だけZUSBチャネルを確保する
    for (int i = 0; i < units; i++) {
      d = &drive[i];
      d->current_bpb = &bpbtable[i];
      initialize_drive();
      if ((zusb_channels[i] = zusb_open_protected()) < 0) {
        _dos_print("ZUSB デバイスが見つかりません\r\n");
        return 0x700d;
      }
    }

    // (可能なら)デバイスへ接続する
    for (int i = 0; i < units; i++) {
      d = &drive[i];
      zusb_set_channel(zusb_channels[i]);
      if (connect_fdd() == 0) {
        char str[256];
        if (d->iProduct &&
          zusb_get_string_descriptor(str, sizeof(str), d->iProduct)) {
          _dos_putchar('A' + *(uint8_t *)&req->fcb + i);
          _dos_print(": ");
          _dos_print(str);
          _dos_print("\r\n");
        }
      }
    }

    req->attr = units;
    req->status = (uint32_t)bpbtable;

    _dos_print("ドライブ");
    _dos_putchar('A' + *(uint8_t *)&req->fcb);
    if (units > 1) {
      _dos_print(":-");
      _dos_putchar('A' + *(uint8_t *)&req->fcb + units - 1);
    }
    _dos_print(":でUSBフロッピーディスクが利用可能です\r\n");

    extern char _end;
    req->addr = &_end;
    return 0;
  }

  //--------------------------------------------------------------------------
  // Command request
  //--------------------------------------------------------------------------

  d = &drive[req->unit];
  zusb_set_channel(zusb_channels[req->unit]);
  DPRINTF("[%d%d]", req->command, req->unit);

  if (d->devid < 0) {
    // USBデバイスを再接続する
    if (connect_fdd() < 0) {
      return 0x7002;    // ドライブの準備が出来ていない
    }
  }

  if (setjmp(jenv)) {
    // USBデバイスが切り離された
    initialize_drive();
    zusb_disconnect_device();
    return 0x7002;      // ドライブの準備が出来ていない
  }

  switch (req->command) {
  case 0x01: /* disk check */
  {
    if (check_medium_change() == 0 && d->medium_change_reported) {
      *(int8_t *)&req->addr = 1;    // media not changed
    } else {
      DPRINTF("media changed\r\n");
      *(int8_t *)&req->addr = -1;   // media changed
      d->medium_change_reported = true;
    }
    break;
  }

  case 0x02: /* rebuild BPB */
  {
    const struct dos_bpb *bpb = check_medium_capacity();
    if (bpb != NULL) {
      *d->current_bpb = bpb;
    }
    req->status = (uint32_t)d->current_bpb;
    break;
  }

  case 0x05: /* drive control & sense */
  {
    switch (req->attr) {
    case 0:   // 状態検査1
    case 1:   // 排出
    case 2:   // 排出禁止1
    case 3:   // 排出許可1
    case 6:   // 排出禁止2
    case 7:   // 排出許可2
    case 9:   // 状態検査2
      int r = check_medium_change();
      if (r < 0) {
        req->attr = 0x04;   // drive not ready
      } else {
        req->attr = d->medium_write_protected ? 0x0a : 0x02;
      }
      break;
    default:
      req->attr = -1;
      break;
    }
    break;
  }

  case 0x04: /* read */
  {
    err = do_read_write(SCSI_CMD_READ_10, ZUSB_DIR_IN, (uint32_t)req->fcb, req->status, req->addr);
    break;
  }

  case 0x08: /* write */
  case 0x09: /* write+verify */
  {
    err = do_read_write(SCSI_CMD_WRITE_10, ZUSB_DIR_OUT, (uint32_t)req->fcb, req->status, req->addr);
    break;
  }

  case 0x03: /* ioctl in */
  {
    DPRINTF("Ioctl in\r\n");
    break;
  }

  case 0x0c: /* ioctl out */
  {
    DPRINTF("Ioctl out\r\n");
    break;
  }

  case 0x13: /* special ioctl */
  {
    DPRINTF("Special ioctl\r\n");
    switch (req->status >> 16) {
    case 2:
      d->medium_change_reported = false;
      break;
    case -1:
    case 0:
    case 1:
    default:
      err = 0x1003;   // Invalid command
      break;
    }
    break;
  }
    break;

  default:
    DPRINTF("Invalid command\r\n");
    err = 0x1003;   // Invalid command
    break;
  }

  return err;
}

//****************************************************************************
// Dummy program entry
//****************************************************************************

void _start(void)
{}
