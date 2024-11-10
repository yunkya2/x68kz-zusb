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
#include <ctype.h>

#include <x68k/iocs.h>
#include <x68k/dos.h>

#include <zusb.h>
#include <scsi_cmd.h>

#include "zusbfddrv.h"

//****************************************************************************
// Constants
//****************************************************************************

#define PROGNAME  "zusbfdformat"
#define BANNER    "X68000 Z USB FDD Formatter version " GIT_REPO_VERSION "\n"

#define OP_LIST_FORMATS           (1 << 0)
#define OP_PHYSICAL_FORMAT_ONLY   (1 << 1)
#define OP_LOGICAL_FORMAT_ONLY    (1 << 2)
#define OP_DUMP_DISK              (1 << 3)
#define OP_VOL_SET                (1 << 4)
#define OP_SYS_COPY               (1 << 5)

#define OP_NO_PROMPT              (1 << 8)
#define OP_QUIET                  (1 << 9)
#define OP_IGNORE_X86_SAFE        (1 << 10)

#define DEV_TIMEOUT   300   // SCSIデバイス タイムアウト時間 (10ms単位)

typedef struct format_info {
  uint8_t format_number;
  uint8_t media_byte;
  uint8_t dos_media_byte;
  char *name;

  int block_num;
  int block_size;
  int tracks;

  uint8_t bootbpb[17];
  struct __attribute__((packed)) {
    uint32_t sect_size;
    uint8_t  n, c, h, s;
    uint16_t sect_per_track;
    uint16_t dirent_per_sect;
    uint16_t dirent_fat; } bootparam;
} format_info_t;

static const format_info_t known_format[] = {
  // 2HD (1232KB)
  // fatlen=2 fatcount=2 fatsec=1 datasec=11 dirsec=5
  { 0, 0xfe, 0xfe, "２ＨＤ（１ＭＢ）",
    1232, 1024, 77 * 2,
    { 0x00, 0x04, 0x01, 0x01, 0x00, 0x02, 0xc0, 0x00, 0xd0, 0x04,
      0xfe, 0x02, 0x00, 0x08, 0x00, 0x02, 0x00 },
    { 1024,  3, 0, 0, 6,  0x0008, 0x001f, 0x0009 },
  },

  // 2HC (1200KB)
  // fatlen=7 fatcount=2 fatsec=1 datasec=29 dirsec=15
  { 5, 0xfd, 0xf9, "２ＨＣ（１ＭＢ）",
    2400, 512,  80 * 2,
    { 0x00, 0x02, 0x01, 0x01, 0x00, 0x02, 0xe0, 0x00, 0x60, 0x09,
      0xf9, 0x07, 0x00, 0x0f, 0x00, 0x02, 0x00 },
    {  512,  2, 0, 1, 1,  0x000f, 0x000f, 0x001b },
  },

  // 2HQ (1440KB)
  // fatlen=9 fatcount=2 fatsec=1 datasec=33 dirsec=19
  { 4, 0xfa, 0xf0, "２ＨＤ（１.４４ＭＢ）",
    2880, 512,  80 * 2,
    { 0x00, 0x02, 0x01, 0x01, 0x00, 0x02, 0xe0, 0x00, 0x40, 0x0b,
      0xf0, 0x09, 0x00, 0x12, 0x00, 0x02, 0x00 },
    {  512,  2, 0, 1, 2,  0x0012, 0x000f, 0x001f },
  },

  // 2DD  (640KB)
  // fatlen=2 fatcount=2 fatsec=1 datasec=12 dirsec=5
  { 8, 0xfb, 0xfb, "２ＤＤ（６４０ＫＢ）",
    1280, 512,  80 * 2,
    { 0x00, 0x02, 0x02, 0x01, 0x00, 0x02, 0x70, 0x00, 0x00, 0x05,
      0xfb, 0x02, 0x00, 0x08, 0x00, 0x02, 0x00 },
    {  512,  2, 0, 0, 6,  0x0008, 0x000f, 0x000a },
  },

  // 2DD  (720KB)
  // fatlen=3 fatcount=2 fatsec=1 datasec=14 dirsec=7
  { 9, 0xfc, 0xf9, "２ＤＤ（７２０ＫＢ）",
    1440, 512,  80 * 2,
    { 0x00, 0x02, 0x02, 0x01, 0x00, 0x02, 0x70, 0x00, 0xa0, 0x05,
      0xf9, 0x03, 0x00, 0x09, 0x00, 0x02, 0x00 },
    {  512,  2, 0, 0, 8,  0x0009, 0x000f, 0x000c },
  },
};

static const uint8_t bootsect[] = {
  0x60,0x3c,0x90,0x58,0x36,0x38,0x49,0x50,0x4c,0x33,0x30,0x00,0x04,0x01,0x01,0x00,
  0x02,0xc0,0x00,0xd0,0x04,0xfe,0x02,0x00,0x08,0x00,0x02,0x00,0x00,0x00,0x00,0x00,
  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x20,0x20,0x20,0x20,0x20,
  0x20,0x20,0x20,0x20,0x20,0x20,0x46,0x41,0x54,0x31,0x32,0x20,0x20,0x20,0x4f,0xfa,
  0xff,0xc0,0x4d,0xfa,0x01,0xb8,0x4b,0xfa,0x00,0xe0,0x49,0xfa,0x00,0xea,0x43,0xfa,
  0x01,0x20,0x4e,0x94,0x70,0x8e,0x4e,0x4f,0x7e,0x70,0xe1,0x48,0x8e,0x40,0x26,0x3a,
  0x01,0x02,0x22,0x4e,0x24,0x3a,0x01,0x00,0x32,0x07,0x4e,0x95,0x66,0x28,0x22,0x4e,
  0x32,0x3a,0x00,0xfa,0x20,0x49,0x45,0xfa,0x01,0x78,0x70,0x0a,0x00,0x10,0x00,0x20,
  0xb1,0x0a,0x56,0xc8,0xff,0xf8,0x67,0x38,0xd2,0xfc,0x00,0x20,0x51,0xc9,0xff,0xe6,
  0x45,0xfa,0x00,0xe0,0x60,0x10,0x45,0xfa,0x00,0xfa,0x60,0x0a,0x45,0xfa,0x01,0x10,
  0x60,0x04,0x45,0xfa,0x01,0x28,0x61,0x00,0x00,0x94,0x22,0x4a,0x4c,0x99,0x00,0x06,
  0x70,0x23,0x4e,0x4f,0x4e,0x94,0x32,0x07,0x70,0x4f,0x4e,0x4f,0x70,0xfe,0x4e,0x4f,
  0x74,0x00,0x34,0x29,0x00,0x1a,0xe1,0x5a,0xd4,0x7a,0x00,0xa4,0x84,0xfa,0x00,0x9c,
  0x84,0x7a,0x00,0x94,0xe2,0x0a,0x64,0x04,0x08,0xc2,0x00,0x18,0x48,0x42,0x52,0x02,
  0x22,0x4e,0x26,0x3a,0x00,0x7e,0x32,0x07,0x4e,0x95,0x34,0x7c,0x68,0x00,0x22,0x4e,
  0x0c,0x59,0x48,0x55,0x66,0xa6,0x54,0x89,0xb5,0xd9,0x66,0xa6,0x2f,0x19,0x20,0x59,
  0xd1,0xd9,0x2f,0x08,0x2f,0x11,0x32,0x7c,0x67,0xc0,0x76,0x40,0xd6,0x88,0x4e,0x95,
  0x22,0x1f,0x24,0x1f,0x22,0x5f,0x4a,0x80,0x66,0x00,0xff,0x7c,0xd5,0xc2,0x53,0x81,
  0x65,0x04,0x42,0x1a,0x60,0xf8,0x4e,0xd1,0x70,0x46,0x4e,0x4f,0x08,0x00,0x00,0x1e,
  0x66,0x02,0x70,0x00,0x4e,0x75,0x70,0x21,0x4e,0x4f,0x4e,0x75,0x72,0x0f,0x70,0x22,
  0x4e,0x4f,0x72,0x19,0x74,0x0c,0x70,0x23,0x4e,0x4f,0x61,0x08,0x72,0x19,0x74,0x0d,
  0x70,0x23,0x4e,0x4f,0x76,0x2c,0x72,0x20,0x70,0x20,0x4e,0x4f,0x51,0xcb,0xff,0xf8,
  0x4e,0x75,0x00,0x00,0x04,0x00,0x03,0x00,0x00,0x06,0x00,0x08,0x00,0x1f,0x00,0x09,
  0x1a,0x00,0x00,0x22,0x00,0x0d,0x48,0x75,0x6d,0x61,0x6e,0x2e,0x73,0x79,0x73,0x20,
  0x82,0xaa,0x20,0x8c,0xa9,0x82,0xc2,0x82,0xa9,0x82,0xe8,0x82,0xdc,0x82,0xb9,0x82,
  0xf1,0x00,0x00,0x25,0x00,0x0d,0x83,0x66,0x83,0x42,0x83,0x58,0x83,0x4e,0x82,0xaa,
  0x81,0x40,0x93,0xc7,0x82,0xdf,0x82,0xdc,0x82,0xb9,0x82,0xf1,0x00,0x00,0x00,0x23,
  0x00,0x0d,0x48,0x75,0x6d,0x61,0x6e,0x2e,0x73,0x79,0x73,0x20,0x82,0xaa,0x20,0x89,
  0xf3,0x82,0xea,0x82,0xc4,0x82,0xa2,0x82,0xdc,0x82,0xb7,0x00,0x00,0x20,0x00,0x0d,
  0x48,0x75,0x6d,0x61,0x6e,0x2e,0x73,0x79,0x73,0x20,0x82,0xcc,0x20,0x83,0x41,0x83,
  0x68,0x83,0x8c,0x83,0x58,0x82,0xaa,0x88,0xd9,0x8f,0xed,0x82,0xc5,0x82,0xb7,0x00,
  0x68,0x75,0x6d,0x61,0x6e,0x20,0x20,0x20,0x73,0x79,0x73,0x00,0x00,0x00,0x00,0x00,
};

//****************************************************************************
// Global variables
//****************************************************************************

uint32_t options = 0;
char *volume_name = NULL;

int format_num = 0;
const format_info_t *format_info = &known_format[0];

int format_drive = -1;    // drive number (1=A: 2=B: ...)
int format_unit = -1;     // device driver unit number

//****************************************************************************
// for debugging
//****************************************************************************

#ifdef DEBUG
#define DPRINTF(...)  printf(__VA_ARGS__)
#else
#define DPRINTF(...)
#endif

//****************************************************************************
// Private functions
//****************************************************************************

//----------------------------------------------------------------------------
// USB device connection
//----------------------------------------------------------------------------

#define EP_BULK_IN    0
#define EP_BULK_OUT   2
#define EP_INTERRUPT  4 

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

static int devcheck(int res)
{
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

  DPRINTF("result=%02x\r\n", sense->sense_key & 0xf);
  return sense->sense_key & 0xf;
}

// 指定したエンドポイントを使ってMSCにSCSIコマンドを送る
int msc_scsi_sendcmd(const void *cmd, int cmd_len, int dir, void *buf, int size)
{
  int res = 0;
  int len;
  int ep = dir ? EP_BULK_IN : EP_BULK_OUT;

  memset(&zusbbuf[0], 0, 12);
  memcpy(&zusbbuf[0], cmd, cmd_len);

  DPRINTF("sendcmd %02x:", zusbbuf[0]);
  if (send_ufi_scsicmd(&zusbbuf[0]) < 0) {
    // メディア交換時はここでエラーになる (ZUSB_EIO)
    DPRINTF("C:err=%x\r\n", zusb->err);
    return -1;
  }

  if (size > 0) {
    len = size;

    if (!dir) {   // host to device - 書き込みデータをUSBバッファに転送
      memcpy(&zusbbuf[0x100], buf, len);
      buf += len;
    }
    // データ転送コマンドを送る
    zusb_set_ep_region(ep, &zusbbuf[0x100], len);
    send_ufi_zusbcmd(ZUSB_CMD_SUBMITXFER(ep));

    // データ転送の完了を待つ
    if (waitep(ep) < 0) {
      DPRINTF("B:err=%x\r\n", zusb->err);
      return -1;
    }
    if ((res = zusb->pcount[ep]) == 0) {
      DPRINTF("no data\r\n");
      return -1;
    }

    if (dir && res > 0) {  // device to host - 読み出したデータをUSBバッファから転送
      memcpy(buf, &zusbbuf[0x100], res);
    }
  }

  if (send_ufi_submit_wait(EP_INTERRUPT, &zusbbuf[0], 2) < 0) {
    DPRINTF("I:err=%x\r\n", zusb->err);
    return -1;
  }
  DPRINTF("stat=%02x%02x\r\n", zusbbuf[0], zusbbuf[1]);

  return res;
}

//----------------------------------------------------------------------------
// Utility functions
//----------------------------------------------------------------------------

typedef struct capacity_descriptor {
  uint32_t block_num;
  uint8_t descriptor_type;
  uint8_t _reserved2;
  uint16_t block_size;
} capacity_descriptor_t;

static int get_current_capacity(void)
{
  scsi_read_format_capacities_resp_t resp;
  scsi_read_format_capacities_t cmd_read_format_capacities;
  int res;

  cmd_read_format_capacities.cmd_code = SCSI_CMD_READ_FORMAT_CAPACITIES;
  cmd_read_format_capacities.alloc_length = sizeof(resp);
  if (msc_scsi_sendcmd(&cmd_read_format_capacities, sizeof(cmd_read_format_capacities),
                       ZUSB_DIR_IN, &resp, cmd_read_format_capacities.alloc_length) < 0) {
    return 0;
  }
  if (resp.descriptor_type != 2) {
    return -1;    // unformatted or no media
  }

  for (int i = 0; i < sizeof(known_format) / sizeof(known_format[0]); i++) {
    if (resp.block_size == known_format[i].block_size &&
        resp.block_num == known_format[i].block_num) {
      format_info = &known_format[i];
      return 0;
    }
  }
  return -1;
}

//----------------------------------------------------------------------------
// Command functions
//----------------------------------------------------------------------------

static void dump_disk(int sector, int count)
{
  static uint8_t sect[1024];

  struct dos_dpbptr dpb;
  if (_dos_getdpb(format_drive, &dpb) < 0) {
    return;
  }

  while (count-- > 0) {
    _dos_diskred2(sect, format_drive, sector, 1);
    printf("\nsector=0x%08lx\n", sector);
    int i;
    char ascii[17];
    ascii[16] = '\0';
    for (i = 0; i < dpb.byte; i++) {
      if (i % 16 == 0) {
        printf("0x%03x: ", i);
      }
      printf("%02x ", sect[i]);
      ascii[i % 16] = (sect[i] >= 0x20 && sect[i] < 0x7f) ? sect[i] : '.';
      if (i % 16 == 15) {
        printf("  %s\n", ascii);
      }
    }
    printf("\n");
    sector++;
  }
}

static int physical_format(void)
{
  scsi_format_unit_t cmd_format_unit = {
    .cmd_code           = SCSI_CMD_FORMAT_UNIT,
    .defect_list_format = 0x17,
    .track_number       = 0,
    .interleave         = 0,
    .alloc_length       = sizeof(scsi_format_unit_param_t),
  };
  scsi_format_unit_param_t param = {
    .flag                = 0xb0,
    .defect_list_length = 8,
  };

  param.block_num = format_info->block_num;
  param.block_size = format_info->block_size;

  int res;
  int sense;

  for (int i = 0; i < format_info->tracks; i++) {
    printf("\r初期化中です・・・トラック %d/%d", i, format_info->tracks - 1);
    fflush(stdout);
    cmd_format_unit.track_number = i / 2;
    param.flag = (i % 2) ? 0xb1 : 0xb0;

    res = msc_scsi_sendcmd(&cmd_format_unit, sizeof(cmd_format_unit),
                           ZUSB_DIR_OUT, &param, sizeof(param));
    sense = msc_scsi_reqsense();
    if (res != sizeof(param) || sense != 0) {
      printf("\r");
      fflush(stdout);
      return -1;
    }
  }
  printf("\r");
  fflush(stdout);
  _dos_c_era_al();

  _dos_ioctrlfdctl(format_drive, 2, (void *)-1);
  return 0;
}

static int logical_format(void)
{
  static uint8_t sect[1024];
  struct dos_dpbptr dpb;

  if (_dos_getdpb(format_drive, &dpb) < 0) {
    return -1;
  }

  memset(sect, 0, sizeof(sect));
  memcpy(sect, bootsect, sizeof(bootsect));
  memcpy(&sect[0x00b], format_info->bootbpb, sizeof(format_info->bootbpb));
  memcpy(&sect[0x162], (uint8_t *)&format_info->bootparam, sizeof(format_info->bootparam));

  if (format_info->format_number == 4 && !(options & OP_IGNORE_X86_SAFE)) {
    sect[0] = 0xeb;
    sect[1] = 0xfe;
  }

  _dos_diskwrt2(sect, format_drive, 0, 1);

  memset(sect, 0, sizeof(sect));
  sect[0] = format_info->dos_media_byte;
  sect[1] = 0xff;
  sect[2] = 0xff;
  for (int i = 0; i < dpb.fatlen; i++) {
    for (int j = 0; j < dpb.fatcount; j++) {
      _dos_diskwrt2(sect, format_drive, dpb.fatsec + j * dpb.fatlen + i, 1);
    }
    memset(sect, 0, 3);
  }

  for (int i = 0; i < dpb.datasec - dpb.dirsec; i++) {
    _dos_diskwrt2(sect, format_drive, dpb.dirsec + i, 1);
  }
  return 0;
}

static void list_capacities(void)
{
  uint8_t buf[256];
  scsi_read_format_capacities_resp_t *resp;
  scsi_read_format_capacities_t cmd_read_format_capacities;
  int res;

  printf("フォーマット可能容量:\n");

  resp = (scsi_read_format_capacities_resp_t *)buf;
  cmd_read_format_capacities.cmd_code = SCSI_CMD_READ_FORMAT_CAPACITIES;
  cmd_read_format_capacities.alloc_length = sizeof(*resp);
  if (msc_scsi_sendcmd(&cmd_read_format_capacities, sizeof(cmd_read_format_capacities),
                       ZUSB_DIR_IN, buf, cmd_read_format_capacities.alloc_length) < 0) {
    return;
  }

  cmd_read_format_capacities.alloc_length = resp->list_length + 4;
  if (msc_scsi_sendcmd(&cmd_read_format_capacities, sizeof(cmd_read_format_capacities),
                       ZUSB_DIR_IN, buf, cmd_read_format_capacities.alloc_length) < 0) {
    return;
  }

  capacity_descriptor_t *cdp;
  cdp = (capacity_descriptor_t *)&buf[sizeof(*resp)];
  while ((uint8_t *)cdp < &buf[cmd_read_format_capacities.alloc_length]) {
    for (int i = 0; i < sizeof(known_format) / sizeof(known_format[0]); i++) {
      if (cdp->block_size == known_format[i].block_size &&
          cdp->block_num == known_format[i].block_num) {
        if (known_format[i].format_number) {
          printf(" %s\t(/%d)\n", known_format[i].name, known_format[i].format_number);
        } else {
          printf(" %s\n", known_format[i].name);
        }
      }
    }
    cdp++;
  }
}

static void set_volume_name(void)
{
  int fd;
  struct dos_inpptr volbuf;

  while (1) {
    if (volume_name == NULL) {
      printf("ボリューム名を半角２１文字以内で指定してください:");
      fflush(stdout);
      volbuf.max = 21;
      _dos_kflushgs(&volbuf);
      volume_name = volbuf.buffer;
      printf("\n");

      if (volbuf.length == 0) {
        return;
      }
    }

    char volname[30];
    volname[0] = '@' + format_drive;
    volname[1] = ':';
    volname[2] = '\\';
    strncpy(&volname[3], volume_name, 21);
    volname[21 + 3] = '\0';
    volume_name = NULL;

    fd = _dos_create(volname, 0x0008);
    if (fd >= 0) {
      _dos_close(fd);
      break;
    }

    printf("ボリューム名の指定に誤りがあります\n");
  }
}

static void usage(void)
{
  printf(
    BANNER
    "使用法: " PROGNAME " ドライブ名: [スイッチ]\n"
    "\t/s\tシステムも転送する\n"
    "\t/v\tボリューム名を指定する\n"
    "\t/c\tＦＡＴとディレクトリを初期化する\n"
    "\t/l\tフォーマット可能な容量一覧を表示する\n"
    "\n\tフォーマット容量指定: \t(無指定時は２ＨＤ（１ＭＢ）)\n"
    "\t/4\tディスクを２ＨＤ（１.４４ＭＢ）でフォーマットする\n"
    "\t/5\tディスクを２ＨＣ（１ＭＢ）でフォーマットする\n"
    "\t/9\tディスクを２ＤＤ（７２０ＫＢ）でフォーマットする\n"
    "\t/8\tディスクを２ＤＤ（６４０ＫＢ）でフォーマットする\n"
    "\t※実際にフォーマット可能かどうかはドライブの仕様に依存します\n"
  );
  exit(1);
}

//****************************************************************************
// Main routine
//****************************************************************************

int main(int argc, char **argv)
{
  int8_t *zusb_channels = NULL;
  int dump_sector = 0;
  int dump_count = 1;

  _dos_super(0);

  // コマンドライン引数を得る

  for (int i = 1; i < argc; i++) {
    if (argv[i][0] == '-' || argv[i][0] == '/') {
      char opt = toupper(argv[i][1]);
      switch (opt) {
      // オプション指定
      case 'L':
        options |= OP_LIST_FORMATS;
        break;
      case 'P':
        options |= OP_PHYSICAL_FORMAT_ONLY;
        break;
      case 'C':
        options |= OP_LOGICAL_FORMAT_ONLY;
        break;
      case 'D':
        if (i + 1 < argc) {
          dump_sector = strtol(argv[++i], NULL, 0);
        }
        if (i + 1 < argc) {
          dump_count = strtol(argv[++i], NULL, 0);
        }
        options |= OP_DUMP_DISK;
        break;
      case 'S':
        options |= OP_SYS_COPY;
        break;
      case 'V':
        options |= OP_VOL_SET;
        if (argv[i][2] != '\0') {
          volume_name = &argv[i][2];
        }
        break;
      case 'Y':
        options |= OP_NO_PROMPT;
        break;
      case 'Q':
        options |= OP_QUIET;
        break;
      case 'I':
        options |= OP_IGNORE_X86_SAFE;
        break;

      // フォーマット種別指定
      case '4':
      case '5':
      case '8':
      case '9':
        for (int i = 0; i < sizeof(known_format) / sizeof(known_format[0]); i++) {
          if (known_format[i].format_number == opt - '0') {
            format_info = &known_format[i];
            break;
          }
        }
        break;

      default:
        usage();
      }
    } else {
      // ドライブ名指定
      int drive = toupper(argv[i][0]);
      if (drive >= 'A' && drive <= 'Z' && argv[i][1] == ':' && argv[i][2] == '\0') {
        format_drive = drive - 'A' + 1;
      } else {
        usage();
      }
    }
  }
  if (format_drive < 0) {
    usage();
  }

  if (!(options & OP_QUIET)) {
    printf(BANNER);
  }

  if (options & OP_DUMP_DISK) {
    dump_disk(dump_sector, dump_count);
    exit(0);
  }

  // 指定したドライブが ZUSBFDD デバイスであることを確認する
  struct dos_dpbptr dpb;
  if (_dos_getdpb(format_drive, &dpb) >= 0) {
    char *p = (char *)dpb.driver + 14;
    if (memcmp(p, "\x01ZUSBFDD", 8) == 0) {
      zusb_channels = &(*(int8_t **)(p - 4))[-4];
      format_unit = dpb.unit;
    }
  }
  if (zusb_channels == NULL) {
    printf(PROGNAME ": ドライブ %c: はZUSB FDDではありません\n", '@' + format_drive);
    exit(1);
  }

  zusb_set_channel(zusb_channels[format_unit]);

  // フォーマット可能な容量一覧を表示する

  if (options & OP_LIST_FORMATS) {
    list_capacities();
    exit(0);
  }

  // フォーマットを行う
  if (!(_dos_drvctrl(0, format_drive) & 0x2)) {
    printf(PROGNAME ": ドライブ %c: にディスクがありません\n", '@' + format_drive);
    exit(1);
  }

  if (_dos_drvctrl(9, format_drive) < 0) {
    printf(PROGNAME ": ドライブ %c: でオープンしているファイルがあります\n", '@' + format_drive);
    exit(1);
  }

  _dos_fflush();

  if (options & OP_LOGICAL_FORMAT_ONLY) {
    if (get_current_capacity() < 0) {
      printf(PROGNAME ": ドライブ %c: がフォーマットできません\n", '@' + format_drive);
      exit(1);
    }
  }

  if (!(options & OP_NO_PROMPT)) {
    printf("ドライブ %c: を%sで初期化します。何かキーを押してください", '@' + format_drive, format_info->name);
    fflush(stdout);
    _dos_kflushgc();
    printf("\n");
  }

  if (!(options & OP_LOGICAL_FORMAT_ONLY)) {
    if (physical_format() < 0) {
      printf(PROGNAME ": 物理フォーマット中にエラーが発生しました\n");
      exit(1);
    }
  }
  if (!(options & OP_PHYSICAL_FORMAT_ONLY)) {
    if (logical_format() < 0) {
      printf(PROGNAME ": 論理フォーマット中にエラーが発生しました\n");
      exit(1);
    }
  }

  printf("初期化を終了しました\n");

  if (!(options & OP_PHYSICAL_FORMAT_ONLY)) {
    if (options & OP_VOL_SET) {
      set_volume_name();
    }
  }

  exit(0);
}
