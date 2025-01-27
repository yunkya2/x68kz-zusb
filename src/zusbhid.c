/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2024 Yuichi Nakamura (@yunkya2)
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
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <stdint.h>
#include <errno.h>

#include <x68k/iocs.h>
#include <x68k/dos.h>

#include <zusb.h>

int main(int argc, char **argv)
{
    int devid = -1;
    int devvid = -1;
    int devpid = -1;
    int time = -1;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-h") == 0) {
            printf("Usage: %s [-h] [devid | vid:pid] [time]\n", argv[0]);
            return 0;
        } else if (strchr(argv[i], ':') && ((devvid < 0) || (devpid < 0))) {
            devvid = strtol(argv[i], NULL, 16);
            devpid = strtol(strchr(argv[i], ':') + 1, NULL, 16);
        } else if (devid < 0) {
            devid = strtol(argv[i], NULL, 0);
        } else if (time < 0) {
            time = strtol(argv[i], NULL, 0);
        }
    }
    if (time < 0) {
        time = 10;      // default 10sec
    }

    _iocs_b_super(0);

    if (zusb_open(0) < 0) {
        printf("ZUSB デバイスが見つかりません\n");
        exit(1);
    }

    if (devvid > 0 && devpid > 0) {
        // デバイスを vid:pid で指定された場合
        devid = zusb_find_device_with_vid_pid(devvid, devpid, 0);
    }

    if (devid < 0) {
        // devid の指定がなかったらHIDデバイス一覧を表示する
        printf("HID devices\n");
        devid = 0;
        while ((devid = zusb_find_device_with_devclass(ZUSB_CLASS_HID, -1, -1, devid))) {
            while (zusb_get_descriptor(zusbbuf) > 0) {
                char str[256];
                zusb_desc_device_t *ddev = (zusb_desc_device_t *)zusbbuf;
                if (ddev->bDescriptorType != ZUSB_DESC_DEVICE) {
                    break;
                }
                printf(" Device:%3d ", devid);
                printf("ID:0x%04x-0x%04x", zusb_le16toh(ddev->idVendor), zusb_le16toh(ddev->idProduct));
                if (ddev->iManufacturer &&
                    zusb_get_string_descriptor(str, sizeof(str), ddev->iManufacturer)) {
                    printf(" %s", str);
                }
                if (ddev->iProduct &&
                    zusb_get_string_descriptor(str, sizeof(str), ddev->iProduct)) {
                    printf(" %s", str);
                }
                printf("\n");
            }
        }
        zusb_close();
        return 0;
    }

    // HIDデバイスに接続する

    zusb_endpoint_config_t epcfg[ZUSB_N_EP] = {
        { ZUSB_DIR_IN, ZUSB_XFER_INTERRUPT, 0 },
        { ZUSB_DIR_IN, ZUSB_XFER_INTERRUPT, 0 },
        { ZUSB_DIR_IN, ZUSB_XFER_INTERRUPT, 0 },
        { ZUSB_DIR_IN, ZUSB_XFER_INTERRUPT, 0 },
        { ZUSB_DIR_IN, ZUSB_XFER_INTERRUPT, 0 },
        { ZUSB_DIR_IN, ZUSB_XFER_INTERRUPT, 0 },
        { ZUSB_DIR_IN, ZUSB_XFER_INTERRUPT, 0 },
        { ZUSB_DIR_IN, ZUSB_XFER_INTERRUPT, 0 },
    };

    if (zusb_connect_device(devid, 1, ZUSB_CLASS_HID, -1, -1, epcfg) <= 0) {
        printf("USB HIDに接続できません\n");
        zusb_close();
        return 0;
    }

    zusb_send_control(ZUSB_REQ_CS_IF_OUT, 0x0a, 0x0000, 0, 0, NULL);    // SET_IDLE

    // 接続したデバイスが持つすべてのINTERRUPT INエンドポイントからデータを読み込み表示する
    // キー入力があるか指定した時間(デフォルトは10秒)が経過したら終了

    uint16_t statmask = 0;
    for (int i = 0; i < ZUSB_N_EP; i++) {
        if (!epcfg[i].maxpacketsize) {
            continue;
        }
        printf("Read %d bytes from Device %d EP 0x%02x\n", epcfg[i].maxpacketsize, devid, epcfg[i].address);
        zusb_set_ep_region(i, &zusbbuf[256 * i] , epcfg[i].maxpacketsize);
        zusb_send_cmd(ZUSB_CMD_SUBMITXFER(i));
        statmask |= ZUSB_STAT_PCOMPLETE(i);
    }

    struct iocs_time tm1, tm2;
    tm1 = _iocs_ontime();
    while (1) {
        uint16_t stat;
        int quit = 0;

        do {
            tm2 = _iocs_ontime();
            if (tm2.sec < tm1.sec) {
                tm1 = _iocs_ontime();
            }
            quit = (time != 0) && (tm2.sec - tm1.sec >= (time * 100));
            quit |= (_iocs_b_keysns() != 0);
            stat = zusb->stat & statmask;
        } while (stat == 0 && !quit);
        if (quit) {
            break;
        }
        zusb->stat = stat;

        while (stat) {
            int ep = ffs(stat) - 1;
            stat &= ~(1 << ep);

            int len = zusb->pcount[ep];
            if (len > 0) {
                printf("EP 0x%02x: ", epcfg[ep].address);
                for (int j = 0; j < len; j++) {
                    printf("%02x ", zusbbuf[256 * ep + j]);
                }
                printf("\n");
                zusb_send_cmd(ZUSB_CMD_SUBMITXFER(ep));
            }
        }
    }

    zusb_disconnect_device();
    zusb_close();
    return 0;
}
