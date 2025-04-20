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
#include "xfnc.h"

//****************************************************************************
// Definition
//****************************************************************************

#define xfnc_enter()      retval.type = 0; retval.i = -1; \
                          int usp = _iocs_b_super(0)
#define xfnc_leave(errno) _iocs_b_super(usp); \
                          xfnc_return_error(&retval, errno, errmsg[errno])

//****************************************************************************
// Static variables
//****************************************************************************

static xfnc_fac_t retval;             // 関数の戻り値格納用
static char retval_str[256];          // 文字列戻り値用

static uint8_t zusb_ch_bitmap = 0;    // 使用中のチャネルビットマップ

static int zusb_ch = -1;              // オープン中のチャネル
static int zusb_devid = -1;           // 検索中のデバイスID
static int zusb_if = -1;              // 検索中のインターフェース番号
static int zusb_ifalt = -1;           // 検索中の代替設定番号
static int zusb_ep = -1;              // 検索中のエンドポイント番号
static bool zusb_connected = false;   // デバイス接続フラグ
static bool zusb_dev_seek = false;    // zusb_seek() 実行フラグ

// 非同期read/write用データ
static struct {
  uint8_t *buf;                 // read/writeバッファ (ZUSBBUF)
  uint8_t *data;                // ユーザデータ転送アドレス
  int size;                     // 転送サイズ
} zusb_async_data[ZUSB_N_EP];

//****************************************************************************
// Error code
//****************************************************************************

#define ZERR_NOZUSB             1
#define ZERR_NOFREECH           2
#define ZERR_NOTOPENED          3
#define ZERR_IOERROR            4
#define ZERR_NOTSEARCHING       5
#define ZERR_NOTCONNECTED       6
#define ZERR_ILLPARAM           7

static char *errmsg[] = {
  NULL,
  "ZUSBが存在しません",
  "ZUSBに空きチャネルがありません",
  "ZUSBチャネルがオープンされていません",
  "I/Oエラーが発生しました",
  "USBデバイスが検索されていません",
  "USBデバイスに接続していません",
  "パラメータが不正です",
};

//****************************************************************************
// for debugging
//****************************************************************************

//#define DEBUG
//#define DEBUG_UART

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
// Service functions
//****************************************************************************

static void zusb_rewind_dev(void)
{
  zusb_devid = -1;
  zusb_dev_seek = false;
  zusb_if = -1;
  zusb_ifalt = -1;
  zusb_ep = -1;
  zusb_connected = false;
}

//****************************************************************************
// X-BASIC functions
//****************************************************************************

//  func int zusb_open([ch;char])
//  USBチャネルをオープンします
//  IN:   ch        オープンするチャネル番号 (省略時は0)
//  OUT:  >0        接続できたチャネル番号
//        -1        エラー

static const uint16_t xfnc_param_zusb_open[] = {
  XFNC_PARAM_CHAR_OMIT,
  XFNC_PARAM_RET_INT
};

static int func_zusb_open(void *a)
{
  xfnc_enter();
  xfnc_fac_t *fac = xfnc_get_fac(a);

  DPRINTF("func_zusb_open()\n");

  int ch = 0;
  if (fac[0].type >= 0) {
    ch = fac[0].i;
  }

  int res = zusb_open(ch);
  if (res == -1) {
    xfnc_leave(ZERR_NOZUSB);
  } else if (res < 0) {
    xfnc_leave(ZERR_NOFREECH);
  }

  zusb_rewind_dev();
  zusb_ch_bitmap |= 1 << ch;
  zusb_ch = ch;
  retval.i = ch;
  xfnc_leave(0);
}

//////////////////////////////////////////////////////////////////////////////

//  func int zusb_close()
//  オープンされているチャネルをクローズします
//  IN:             なし
//  OUT:   0        正常終了
//        -1        エラー

static const uint16_t xfnc_param_zusb_close[] = {
  XFNC_PARAM_RET_INT
};

static int func_zusb_close(void *a)
{
  xfnc_enter();
  xfnc_fac_t *fac = xfnc_get_fac(a);

  DPRINTF("func_zusb_close()\n");

  if (zusb_ch < 0) {
    xfnc_leave(ZERR_NOTOPENED);
  }

  zusb_close();
  zusb_rewind_dev();
  zusb_ch_bitmap &= ~(1 << zusb_ch);
  zusb_ch = -1;
  retval.i = 0;
  xfnc_leave(0);
}

//////////////////////////////////////////////////////////////////////////////

//  func int zusb_setch(ch;int)
//  オープン済みのUSBチャネルを選択します
//  IN:   ch        選択するチャネル番号
//  OUT:   0        正常終了
//        -1        エラー

static const uint16_t xfnc_param_zusb_setch[] = {
  XFNC_PARAM_CHAR,
  XFNC_PARAM_RET_INT
};

static int func_zusb_setch(void *a)
{
  xfnc_enter();
  xfnc_fac_t *fac = xfnc_get_fac(a);

  DPRINTF("func_zusb_setch()\n");

  int ch = fac[0].i;
  if (!(zusb_ch_bitmap & (1 << ch))) {
    xfnc_leave(ZERR_NOTOPENED);
  }

  zusb_rewind_dev();
  zusb_ch = ch;
  retval.i = 0;
  xfnc_leave(0);
}

//////////////////////////////////////////////////////////////////////////////

//  func int zusb_find([devid;int],[vid;int],[pid;int],[mstr;str],[pstr;str],[sstr;str])
//  USBデバイスを検索します
//  IN:   devid     見つかったUSBデバイスのデバイスIDを返す変数
//        vid       見つかったデバイスのVendor IDを返す変数
//        pid       見つかったデバイスのProduct IDを返す変数
//        mstr      見つかったデバイスのManufacturer文字列を返す変数
//        pstr      見つかったデバイスのProduct文字列を返す変数
//        sstr      見つかったデバイスのSerial文字列を返す変数
//  OUT:  >0        見つかったUSBデバイスのデバイスID
//         0        デバイスが見つからなかった
//        -1        エラー

static const uint16_t xfnc_param_zusb_find[] = {
  XFNC_PARAM_INT_OMIT_PTR,
  XFNC_PARAM_INT_OMIT_PTR,
  XFNC_PARAM_INT_OMIT_PTR,
  XFNC_PARAM_STR_OMIT_PTR,
  XFNC_PARAM_STR_OMIT_PTR,
  XFNC_PARAM_STR_OMIT_PTR,
  XFNC_PARAM_RET_INT
};

static int func_zusb_find(void *a)
{
  xfnc_enter();
  xfnc_fac_t *fac = xfnc_get_fac(a);

  DPRINTF("func_zusb_find()\n");

  if (zusb_ch < 0) {
    xfnc_leave(ZERR_NOTOPENED);
  }

  // zusb_seek()で移動済みでなければデバイスIDを検索する 
  if (zusb_devid <= 0 || !zusb_dev_seek) {
    // 最初のデバイスIDを得る
    if (zusb_send_cmd(ZUSB_CMD_GETDEV) < 0) {
      xfnc_leave(ZERR_IOERROR);
    }
    DPRINTF("devid=%d\n", zusb->devid);

    // 検索中のデバイスIDの次のデバイスを検索する
    if (zusb_devid > 0) {
      while (zusb->devid != zusb_devid && zusb->devid != 0) {
        if (zusb_send_cmd(ZUSB_CMD_NEXTDEV) < 0) {
          xfnc_leave(ZERR_IOERROR);
        }
        DPRINTF("devid=%d\n", zusb->devid);
      }
      while (zusb->devid == zusb_devid) {
        if (zusb_send_cmd(ZUSB_CMD_NEXTDEV) < 0) {
          xfnc_leave(ZERR_IOERROR);
        }
        DPRINTF("devid=%d\n", zusb->devid);
      }
      if (zusb->devid == 0) {
        zusb_devid = -1;
        retval.i = 0;
        xfnc_leave(0);
      }
    }
    zusb_devid = zusb->devid;
  }

  zusb_dev_seek = false;
  zusb_if = -1;
  zusb_ifalt = -1;
  zusb_ep = -1;
  retval.i = zusb_devid;

  // デバイスディスクリプタを取得する
  int res;
  while ((res = zusb_get_descriptor(zusbbuf)) > 0) {
    zusb_desc_device_t *ddev = (zusb_desc_device_t *)zusbbuf;

    if (ddev->bDescriptorType == ZUSB_DESC_DEVICE) {
      DPRINTF(" device %d 0x%04x:0x%04x\n", zusb_devid,
              zusb_le16toh(ddev->idVendor), zusb_le16toh(ddev->idProduct));

      if (fac[0].type >= 0) {
        *fac[0].ip = zusb_devid;
      }
      if (fac[1].type >= 0) {
        *fac[1].ip = zusb_le16toh(ddev->idVendor);
      }
      if (fac[2].type >= 0) {
        *fac[2].ip = zusb_le16toh(ddev->idProduct);
      }

      if (fac[3].type >= 0) {
        memset(fac[3].sp + 1, 0, fac[3].sp[0]);
        if (zusb_get_string_descriptor(retval_str, sizeof(retval_str), ddev->iManufacturer) > 0) {
          strncpy(fac[3].sp + 1, retval_str, fac[3].sp[0]);
        }
      }
      if (fac[4].type >= 0) {
        memset(fac[4].sp + 1, 0, fac[4].sp[0]);
        if (zusb_get_string_descriptor(retval_str, sizeof(retval_str), ddev->iProduct) > 0) {
          strncpy(fac[4].sp + 1, retval_str, fac[4].sp[0]);
        }
      }
      if (fac[5].type >= 0) {
        memset(fac[5].sp + 1, 0, fac[5].sp[0]);
        if (zusb_get_string_descriptor(retval_str, sizeof(retval_str), ddev->iSerialNumber) > 0) {
          strncpy(fac[5].sp + 1, retval_str, fac[5].sp[0]);
        }
      }
      break;
    }
  }
  if (res < 0) {
    retval.i = -1;
    xfnc_leave(ZERR_IOERROR);
  }

  xfnc_leave(0);
}

//////////////////////////////////////////////////////////////////////////////

//  func int zusb_seek(devid;int)
//  USBデバイスの検索位置を指定のIDに移動します
//  IN:   devid     デバイスID
//  OUT:   0        正常終了
//        -1        エラー

static const uint16_t xfnc_param_zusb_seek[] = {
  XFNC_PARAM_INT,
  XFNC_PARAM_RET_INT
};

static int func_zusb_seek(void *a)
{
  xfnc_enter();
  xfnc_fac_t *fac = xfnc_get_fac(a);

  DPRINTF("func_zusb_seek()\n");

  if (zusb_ch < 0) {
    xfnc_leave(ZERR_NOTOPENED);
  }

  // 指定されたデバイスIDを検索する
  zusb_rewind_dev();
  zusb_send_cmd(ZUSB_CMD_GETDEV);
  DPRINTF("devid=%d\n", zusb->devid);
  while (zusb->devid != fac[0].i && zusb->devid != 0) {
    if (zusb_send_cmd(ZUSB_CMD_NEXTDEV) < 0) {
      xfnc_leave(ZERR_IOERROR);
    }
    DPRINTF("devid=%d\n", zusb->devid);
  }

  if (zusb->devid > 0) {
    zusb_devid = fac[0].i;
    zusb_dev_seek = true;
  }
  retval.i = 0;
  xfnc_leave(0);
}

//////////////////////////////////////////////////////////////////////////////

//  func int zusb_rewind()
//  USBデバイスの検索位置を最初に戻します
//  IN:   なし
//  OUT:   0        正常終了
//        -1        エラー

static const uint16_t xfnc_param_zusb_rewind[] = {
  XFNC_PARAM_RET_INT
};

static int func_zusb_rewind(void *a)
{
  xfnc_enter();
  xfnc_fac_t *fac = xfnc_get_fac(a);

  DPRINTF("func_zusb_rewind()\n");

  if (zusb_ch < 0) {
    xfnc_leave(ZERR_NOTOPENED);
  }

  zusb_rewind_dev();
  retval.i = 0;
  xfnc_leave(0);
}

//////////////////////////////////////////////////////////////////////////////

//  func int zusb_getif([intf;int],[cls;int],[subc;int],[proto;int],[nep;int])
//  USBデバイスのインターフェースを取得します
//  IN:   intf      見つかったインターフェース番号を返す変数
//        cls       見つかったインターフェースのデバイスクラスを返す変数
//        subc      見つかったインターフェースのデバイスサブクラスを返す変数
//        proto     見つかったインターフェースのデバイスプロトコルを返す変数
//        nep       見つかったインターフェースのエンドポイント数を返す変数
//  OUT:   1        インターフェースが見つかった
//         0        インターフェースが見つからなかった
//        -1        エラー

static const uint16_t xfnc_param_zusb_getif[] = {
  XFNC_PARAM_INT_OMIT_PTR,
  XFNC_PARAM_INT_OMIT_PTR,
  XFNC_PARAM_INT_OMIT_PTR,
  XFNC_PARAM_INT_OMIT_PTR,
  XFNC_PARAM_INT_OMIT_PTR,
  XFNC_PARAM_RET_INT
};

static int func_zusb_getif(void *a)
{
  xfnc_enter();
  xfnc_fac_t *fac = xfnc_get_fac(a);

  DPRINTF("func_zusb_getif()\n");
  DPRINTF(" zusb_devid=%d zusb_if=%d zusb_ifalt=%d zusb_ep=%02x\n", zusb_devid, zusb_if, zusb_ifalt, zusb_ep);

  if (zusb_ch < 0) {
    xfnc_leave(ZERR_NOTOPENED);
  }
  if (zusb_devid < 0) {
    xfnc_leave(ZERR_NOTSEARCHING);
  }

  int res;
  zusb_ep = -1;
  zusb_rewind_descriptor();

  if (zusb_if >= 0) {
    // 前回探したインターフェースまでディスクリプタを読み進める
    while ((res = zusb_get_descriptor(zusbbuf)) > 0) {
      zusb_desc_interface_t *dintf = (zusb_desc_interface_t *)zusbbuf;
      if (dintf->bDescriptorType == ZUSB_DESC_INTERFACE &&
          dintf->bInterfaceNumber == zusb_if &&
          dintf->bAlternateSetting == zusb_ifalt) {
        break;
      }
    }

    if (res < 0) {
      xfnc_leave(ZERR_IOERROR);
    } else if (res == 0) {
      retval.i = 0;
      xfnc_leave(0);
    }
  }

  // 次のインターフェースディスクリプタを探す
  while ((res = zusb_get_descriptor(zusbbuf)) > 0) {
    zusb_desc_interface_t *dintf = (zusb_desc_interface_t *)zusbbuf;

    if (dintf->bDescriptorType == ZUSB_DESC_INTERFACE) {
      DPRINTF(" interface %d %d %d %d\n",
              dintf->bInterfaceNumber, dintf->bInterfaceClass,
              dintf->bInterfaceSubClass, dintf->bInterfaceProtocol);

      retval.i = 1;
      zusb_if = dintf->bInterfaceNumber;
      zusb_ifalt = dintf->bAlternateSetting;
      zusb_ep = -1;
      if (fac[0].type >= 0) {
        *fac[0].ip = zusb_if;
      }
      if (fac[1].type >= 0) {
        *fac[1].ip = dintf->bInterfaceClass;
      }
      if (fac[2].type >= 0) {
        *fac[2].ip = dintf->bInterfaceSubClass;
      }
      if (fac[3].type >= 0) {
        *fac[3].ip = dintf->bInterfaceProtocol;
      }
      if (fac[4].type >= 0) {
        *fac[4].ip = dintf->bNumEndpoints;
      }
      break;
    }
  }

  if (res < 0) {
    xfnc_leave(ZERR_IOERROR);
  } else if (res == 0) {
    retval.i = 0;
  }

  xfnc_leave(0);
}

//////////////////////////////////////////////////////////////////////////////

//  func int zusb_getep([epaddr;int],[dir;int],[xfer;int],[maxpkt;int])
//  インターフェースが持つエンドポイントを取得します
//  IN:   epaddr    見つかったエンドポイントアドレスを返す変数
//        dir       見つかったエンドポイントの転送方向を返す変数 (0:OUT 1:IN)
//        xfer      見つかったエンドポイントの転送モードを返す変数
//                  (0:コントロール転送 1:アイソクロナス転送 2:バルク転送 3:インタラプト転送)
//        maxpkt    見つかったエンドポイントの最大パケットサイズを返す変数
//  OUT:  >0        見つかったエンドポイントアドレス
//         0        エンドポイントが見つからなかった
//        -1        エラー

static const uint16_t xfnc_param_zusb_getep[] = {
  XFNC_PARAM_INT_OMIT_PTR,
  XFNC_PARAM_INT_OMIT_PTR,
  XFNC_PARAM_INT_OMIT_PTR,
  XFNC_PARAM_INT_OMIT_PTR,
  XFNC_PARAM_RET_INT
};

static int func_zusb_getep(void *a)
{
  xfnc_enter();
  xfnc_fac_t *fac = xfnc_get_fac(a);

  DPRINTF("func_zusb_getep()\n");
  DPRINTF(" zusb_devid=%d zusb_if=%d zusb_ep=%02x\n", zusb_devid, zusb_if, zusb_ep);

  if (zusb_ch < 0) {
    xfnc_leave(ZERR_NOTOPENED);
  }
  if (zusb_devid < 0 || zusb_if < 0) {
    xfnc_leave(ZERR_NOTSEARCHING);
  }

  int res;
  zusb_rewind_descriptor();

  // 現在のインターフェースまでディスクリプタを読み進める
  while ((res = zusb_get_descriptor(zusbbuf)) > 0) {
    zusb_desc_interface_t *dintf = (zusb_desc_interface_t *)zusbbuf;
    if (dintf->bDescriptorType == ZUSB_DESC_INTERFACE &&
        dintf->bInterfaceNumber == zusb_if &&
        dintf->bAlternateSetting == zusb_ifalt) {
      break;
    }
  }

  if (res > 0 && zusb_ep >= 0) {
    // 前回探したエンドポイントまでディスクリプタを読み進める
    while ((res = zusb_get_descriptor(zusbbuf)) > 0) {
      zusb_desc_endpoint_t *dendp = (zusb_desc_endpoint_t *)zusbbuf;
        if (dendp->bDescriptorType == ZUSB_DESC_ENDPOINT &&
          dendp->bEndpointAddress == zusb_ep) {
        break;
      }
    }
  }

  if (res < 0) {
    xfnc_leave(ZERR_IOERROR);
  } else if (res == 0) {
    retval.i = 0;
    xfnc_leave(0);
  }

  // 次のエンドポイントディスクリプタを探す
  while ((res = zusb_get_descriptor(zusbbuf)) > 0) {
    zusb_desc_endpoint_t *dendp = (zusb_desc_endpoint_t *)zusbbuf;

    // 次のインターフェースディスクリプタが出てきたら終わり
    if (dendp->bDescriptorType == ZUSB_DESC_INTERFACE) {
      res = 0;
      break;
    }

    if (dendp->bDescriptorType == ZUSB_DESC_ENDPOINT) {
      DPRINTF(" ep=%02x attr=%02x maxpkt=%d\n",
              dendp->bEndpointAddress,
              dendp->bmAttributes, zusb_le16toh(dendp->wMaxPacketSize));

      retval.i = (dendp->bEndpointAddress << 8) | dendp->bmAttributes;
      zusb_ep = dendp->bEndpointAddress;
      if (fac[0].type >= 0) {
        *fac[0].ip = retval.i;
      }
      if (fac[1].type >= 0) {
        *fac[1].ip = !!(dendp->bEndpointAddress & ZUSB_DIR_MASK);
      }
      if (fac[2].type >= 0) {
        *fac[2].ip = dendp->bmAttributes;
      }
      if (fac[3].type >= 0) {
        *fac[3].ip = zusb_le16toh(dendp->wMaxPacketSize);
      }
      break;
    }
  }

  if (res < 0) {
    xfnc_leave(ZERR_IOERROR);
  } else if (res == 0) {
    retval.i = 0;
  }

  xfnc_leave(0);
}

//////////////////////////////////////////////////////////////////////////////

//  func int zusb_connect(config;int, intf;int)
//  USBデバイスの指定したインターフェースに接続します
//  IN:   config    接続先のコンフィグレーション番号 (必ず 1 を指定)
//        intf      接続先のインターフェース番号
//  OUT:   0        正常終了
//        -1        エラー

static const uint16_t xfnc_param_zusb_connect[] = {
  XFNC_PARAM_INT,
  XFNC_PARAM_INT,
  XFNC_PARAM_RET_INT
};

static int func_zusb_connect(void *a)
{
  xfnc_enter();
  xfnc_fac_t *fac = xfnc_get_fac(a);

  DPRINTF("func_zusb_connect()\n");

  if (zusb_ch < 0) {
    xfnc_leave(ZERR_NOTOPENED);
  }
  if (zusb_devid < 0) {
    xfnc_leave(ZERR_NOTSEARCHING);
  }

  int config = 1;
  int intf = fac[1].i;

  zusb->param = (config << 8) | intf;
  DPRINTF(" connect param:%04x\n", zusb->param);

  if (zusb_send_cmd(ZUSB_CMD_CONNECT) < 0) {
    xfnc_leave(ZERR_IOERROR);
  }

  zusb_connected = true;
  retval.i = 0;
  xfnc_leave(0);
}

//////////////////////////////////////////////////////////////////////////////

//  func int zusb_disconnect()
//  接続されているインターフェースから切断します
//  IN:             なし
//  OUT:   0        正常終了
//        -1        エラー

static const uint16_t xfnc_param_zusb_disconnect[] = {
  XFNC_PARAM_RET_INT
};

static int func_zusb_disconnect(void *a)
{
  xfnc_enter();

  DPRINTF("func_zusb_disconnect()\n");

  if (zusb_ch < 0) {
    xfnc_leave(ZERR_NOTOPENED);
  }

  zusb_send_cmd(ZUSB_CMD_DISCONNECT);
  zusb_connected = false;
  retval.i = 0;
  xfnc_leave(0);
}

//////////////////////////////////////////////////////////////////////////////

//  func int zusb_bind(epno;char, epaddr;int)
//  接続されたデバイスのエンドポイントをパイプに結び付けます
//  IN:   epno      設定先のパイプ番号 (0～7)
//        epaddr    設定するエンドポイントアドレス
//  OUT:   0        正常終了
//        -1        エラー

static const uint16_t xfnc_param_zusb_bind[] = {
  XFNC_PARAM_CHAR,
  XFNC_PARAM_INT,
  XFNC_PARAM_RET_INT
};

static int func_zusb_bind(void *a)
{
  xfnc_enter();
  xfnc_fac_t *fac = xfnc_get_fac(a);

  DPRINTF("func_zusb_bind()\n");

  if (zusb_ch < 0) {
    xfnc_leave(ZERR_NOTOPENED);
  }

  int ep = fac[0].c;
  if (ep < 0 || ep >= 8) {
    xfnc_leave(ZERR_ILLPARAM);
  }

  zusb->pcfg[ep] = fac[1].i;
  zusb->pcount[ep] = 0;

  retval.i = 0;
  xfnc_leave(0);
}

//////////////////////////////////////////////////////////////////////////////

//  func int zusb_control(type;int, req;int, value;int, index;int, [len;int], [data])
//  デバイスにコントロール転送を発行する
//  IN:   type      リクエストタイプ(bmType) (&H00=send, &H80=receive など..)
//        req       リクエスト番号 (bRequest)
//        value     リクエスト値 (wValue)
//        index     インデックス (wIndex)
//        len       転送するデータ長 (wLength: 省略時は0)
//        data      転送するデータ (数値型一次配列)
//  OUT:   0        正常終了
//        -1        エラー

static const uint16_t xfnc_param_zusb_control[] = {
  XFNC_PARAM_INT,
  XFNC_PARAM_INT,
  XFNC_PARAM_INT,
  XFNC_PARAM_INT,
  XFNC_PARAM_INT_OMIT,
  XFNC_PARAM_ARRAY1_FIC|XFNC_PARAM_OMIT,
  XFNC_PARAM_RET_INT
};

static int func_zusb_control(void *a)
{
  xfnc_enter();
  xfnc_fac_t *fac = xfnc_get_fac(a);

  DPRINTF("func_zusb_control()\n");

  if (zusb_ch < 0) {
    xfnc_leave(ZERR_NOTOPENED);
  }
  if (zusb_devid < 0) {
    xfnc_leave(ZERR_NOTSEARCHING);
  }

  int size = 0;
  if (fac[4].type >= 0) {
    if (fac[5].type < 0) {
      xfnc_leave(ZERR_ILLPARAM);
    }
    size = fac[4].i;
    if (size > (fac[5].a->maxsub + 1)) {
      xfnc_leave(ZERR_ILLPARAM);
    }
    size *= fac[5].a->size;
  }

  int res = zusb_send_control(fac[0].i, fac[1].i, fac[2].i, fac[3].i, size, zusbbuf);
  if (res < 0) {
    xfnc_leave(ZERR_IOERROR);
  } else {
    res /= fac[5].a->size;
  }
  memcpy(fac[5].a->data, (uint8_t *)zusbbuf, res);
  retval.i = res;

  xfnc_leave(0);
}

//////////////////////////////////////////////////////////////////////////////

static const uint16_t xfnc_param_zusb_readwrite[] = {
  XFNC_PARAM_ARRAY1_FIC,
  XFNC_PARAM_INT,
  XFNC_PARAM_CHAR,
  XFNC_PARAM_INT_OMIT,
  XFNC_PARAM_RET_INT
};

static int func_zusb_readwrite(xfnc_fac_t *fac, bool iswrite, bool isasync)
{
  xfnc_enter();

  DPRINTF("func_zusb_read()\n");

  if (zusb_ch < 0) {
    xfnc_leave(ZERR_NOTOPENED);
  }
  if (!zusb_connected) {
    xfnc_leave(ZERR_NOTCONNECTED);
  }

  int ep = fac[2].c;
  if (ep < 0 || ep >= 8) {
    xfnc_leave(ZERR_ILLPARAM);
  }

  int size = fac[1].i;
  if (size > (fac[0].a->maxsub + 1)) {
    xfnc_leave(ZERR_ILLPARAM);
  }
  size *= fac[0].a->size;

  uint8_t *buf = zusbbuf;
  if (fac[3].type >= 0) {
    buf = &zusbbuf[fac[3].i];
  }

  zusb_async_data[ep].size = fac[0].a->size;
  if (iswrite) {
    memcpy((uint8_t *)buf, fac[0].a->data, size);
    zusb_async_data[ep].buf = NULL;
    zusb_async_data[ep].data = NULL;
  } else {
    zusb_async_data[ep].buf = (uint8_t *)buf;
    zusb_async_data[ep].data = fac[0].a->data;
  }

  DPRINTF(" readwrite ep=%02x buf=%p size=%d\n", ep, buf, size);
  zusb_set_ep_region(ep, buf, size);
  zusb_send_cmd(ZUSB_CMD_SUBMITXFER(ep));
  if (isasync) {
    xfnc_leave(0);
  }

  while (!(zusb->stat & ZUSB_STAT_PCOMPLETE(ep))) {
    _dos_keysns();
    if (zusb->stat & ZUSB_STAT_ERROR) {
      xfnc_leave(ZERR_IOERROR);
    }
  }

  int16_t len = zusb->pcount[ep];

  if (!iswrite && len > 0) {
    memcpy(fac[0].a->data, (uint8_t *)buf, len);
    len /= fac[0].a->size;
  }

  DPRINTF(" readwrite end %d\n", retval.i);
  retval.i = len;
  xfnc_leave(0);
}

//  func zusb_read(data, len;int, epno;char, [pos;int])
//  指定したパイプからデータを読み込む (データが来るまで待つ)
//  IN:   data      読み込むデータの格納先 (数値型一次配列)
//        len       読み込むデータ長
//        epno      読み込むパイプ番号 (0～7)
//        pos       ZUSB バッファ上のデータ読み込み位置 (&H000～&H77F 省略時は0)
//  OUT:  >=0       正常終了 (読み込んだデータ長を返す)
//        -1        エラー

static int func_zusb_read(void *a)
{
  return func_zusb_readwrite(xfnc_get_fac(a), false, false);
}

//  func zusb_write(len;int, data, epno;char, [pos;int])
//  指定したパイプからデータを書き込む (書き込み完了まで待つ)
//  IN:   data      書き込むデータの格納先 (数値型一次配列)
//        len       書き込むデータ長
//        epno      書き込むパイプ番号 (0～7)
//        pos       ZUSB バッファ上のデータ書き込み位置 (&H000～&H77F 省略時は0)
//  OUT:  >=0       正常終了 (書き込んだデータ長を返す)
//        -1        エラー

static int func_zusb_write(void *a)
{
  return func_zusb_readwrite(xfnc_get_fac(a), true, false);
}

//  func zusb_readasync(data, len;int, epno;char, [pos;int])
//  指定したパイプからデータを読み込む (読み込み指示を出したらすぐ終了する)
//  IN:   data      読み込むデータの格納先 (数値型一次配列)
//        len       読み込むデータ長
//        epno      読み込むパイプ番号 (0～7)
//        pos       ZUSB バッファ上のデータ読み込み位置 (&H000～&H77F 省略時は0)
//  OUT:   0        正常終了
//        -1        エラー

static int func_zusb_readasync(void *a)
{
  return func_zusb_readwrite(xfnc_get_fac(a), false, true);
}

//  func zusb_writeasync(len;int, data, epno;char, [pos;int])
//  指定したパイプからデータを書き込む (書き込み指示を出したらすぐ終了する)
//  IN:   data      書き込むデータの格納先 (数値型一次配列)
//        len       書き込むデータ長
//        epno      書き込むパイプ番号 (0～7)
//        pos       ZUSB バッファ上のデータ書き込み位置 (&H000～&H77F 省略時は0)
//  OUT:   0        正常終了
//        -1        エラー

static int func_zusb_writeasync(void *a)
{
  return func_zusb_readwrite(xfnc_get_fac(a), true, true);
}

//////////////////////////////////////////////////////////////////////////////
//  func int zusb_stat([ep;char])
//  非同期読み書きが完了したかどうかを調べる
//  引数を省略すると、返されるバイト値のビット0～7が各パイプの状態を示す
//  IN:   epno      調査するパイプ番号 (0～7)
//  OUT:  >=0       (epnoを省略した場合)各パイプの状態を示すバイト値
//         1        (epnoを指定した場合)指定したパイプの読み書きが完了した
//         0        (epnoを指定した場合)指定したパイプは読み書き中
//        -1        エラー

static const uint16_t xfnc_param_zusb_stat[] = {
  XFNC_PARAM_CHAR_OMIT,
  XFNC_PARAM_RET_INT
};

static int func_zusb_stat(void *a)
{
  xfnc_enter();
  xfnc_fac_t *fac = xfnc_get_fac(a);

  DPRINTF("func_zusb_stat()\n");

  if (zusb_ch < 0) {
    xfnc_leave(ZERR_NOTOPENED);
  }
  if (!zusb_connected) {
    xfnc_leave(ZERR_NOTCONNECTED);
  }

  int ep = -1;
  if (fac[0].type >= 0) {
    ep = fac[0].c;
    if (ep < 0 || ep >= 8) {
      xfnc_leave(ZERR_ILLPARAM);
    }
  }

  int stat = zusb->stat;
  if (ep >= 0) {
    retval.i = !!(stat & ZUSB_STAT_PCOMPLETE(ep));
  } else {
    retval.i = stat & 0xff;
  }

  xfnc_leave(0);
}

//////////////////////////////////////////////////////////////////////////////
//  func int zusb_wait(epno;char)
//  非同期読み書きの完了を待って結果を返す
//  IN:   epno      パイプ番号 (0～7)
//  OUT:  >=0       正常終了 (読み書きしたデータ長を返す)
//        -1        エラー

static const uint16_t xfnc_param_zusb_wait[] = {
  XFNC_PARAM_CHAR,
  XFNC_PARAM_RET_INT
};

static int func_zusb_wait(void *a)
{
  xfnc_enter();
  xfnc_fac_t *fac = xfnc_get_fac(a);

  DPRINTF("func_zusb_wait()\n");

  if (zusb_ch < 0) {
    xfnc_leave(ZERR_NOTOPENED);
  }
  if (!zusb_connected) {
    xfnc_leave(ZERR_NOTCONNECTED);
  }

  int ep = fac[0].c;
  if (ep < 0 || ep >= 8) {
    xfnc_leave(ZERR_ILLPARAM);
  }

  while (!(zusb->stat & ZUSB_STAT_PCOMPLETE(ep))) {
    _dos_keysns();
    if (zusb->stat & ZUSB_STAT_ERROR) {
      xfnc_leave(ZERR_IOERROR);
    }
  }

  int16_t len = zusb->pcount[ep];
  DPRINTF(" wait ep=%02x len=%d\n", ep, len);

  if (len > 0 && zusb_async_data[ep].buf != NULL) {
    memcpy(zusb_async_data[ep].data, zusb_async_data[ep].buf, len);
  }

  retval.i = len / zusb_async_data[ep].size;
  xfnc_leave(0);
}

//****************************************************************************
// X-BASIC tables
//****************************************************************************

const char xfnc_token[] = 
  "zusb_open\0"
  "zusb_close\0"
  "zusb_setch\0"

  "zusb_find\0"
  "zusb_seek\0"
  "zusb_rewind\0"
  "zusb_getif\0"
  "zusb_getep\0"

  "zusb_connect\0"
  "zusb_disconnect\0"
  "zusb_bind\0"

  "zusb_control\0"
  "zusb_read\0"
  "zusb_write\0"
  "zusb_readasync\0"
  "zusb_writeasync\0"
  "zusb_stat\0"
  "zusb_wait\0"
  "";

const uint16_t *xfnc_param[] = {
  xfnc_param_zusb_open,
  xfnc_param_zusb_close,
  xfnc_param_zusb_setch,

  xfnc_param_zusb_find,
  xfnc_param_zusb_seek,
  xfnc_param_zusb_rewind,
  xfnc_param_zusb_getif,
  xfnc_param_zusb_getep,

  xfnc_param_zusb_connect,
  xfnc_param_zusb_disconnect,
  xfnc_param_zusb_bind,

  xfnc_param_zusb_control,
  xfnc_param_zusb_readwrite,
  xfnc_param_zusb_readwrite,
  xfnc_param_zusb_readwrite,
  xfnc_param_zusb_readwrite,
  xfnc_param_zusb_stat,
  xfnc_param_zusb_wait,
};

const int (*(xfnc_entry[]))() = {
  func_zusb_open,
  func_zusb_close,
  func_zusb_setch,

  func_zusb_find,
  func_zusb_seek,
  func_zusb_rewind,
  func_zusb_getif,
  func_zusb_getep,

  func_zusb_connect,
  func_zusb_disconnect,
  func_zusb_bind,

  func_zusb_control,
  func_zusb_read,
  func_zusb_write,
  func_zusb_readasync,
  func_zusb_writeasync,
  func_zusb_stat,
  func_zusb_wait,
};

//****************************************************************************
// Program entry
//****************************************************************************

void _start()
{
}
