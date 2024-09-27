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
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <x68k/iocs.h>
#include <x68k/dos.h>

#include <zusb.h>

extern void zusbintr_asm();
extern struct resident_param {
    void *oldvect;
    void *mblock;
    volatile struct zusb_regs **oldzusb;
    uint8_t **oldzusbbuf;
} resparam;

__asm__(
"resparam:\n"
".long 0\n"
".long _start-0xf0\n"
".long zusb\n"
".long zusbbuf\n"

".ascii \"ZUJ\\0\"\n"

"zusbintr_asm:\n"
"movem.l %d0-%d7/%a0-%a6,%sp@-\n"
"bsr zusbintr\n"
"movem.l %sp@+,%d0-%d7/%a0-%a6\n"
"rte\n"
);


static void skeyset(uint16_t scancode)
{
    __asm__ volatile (
        "move.l %0,%%d1\n"
        "moveq.l #0x05,%%d0\n"
        "trap #15\n"
        : : "d"(scancode) : "%%d0", "%%d1"
    );
}

static uint8_t joykey[] =
//            R     L            A     B
{ 0x00, 0x00, 0x14, 0x26,  0x00, 0x1e, 0x2e, 0x00,
  0x3b, 0x3d, 0x3c, 0x3e,  0x00, 0x00, 0x1f, 0x13 };
// ←     →     ↑     ↓                 START SELECT

uint16_t joystat = 0;

void zusbintr(void)
{
    uint16_t stat = zusb->stat;
    zusb->stat = zusb->stat;
    if (stat & ZUSB_STAT_ERROR) {
        zusb->inten = 0;
        return;
    }

    switch (zusbbuf[2]) {
    case 0x00:  // left
        zusbbuf[1] |= 0x80;
        break;
    case 0xff:  // right
        zusbbuf[1] |= 0x40;
        break;
    }
    switch (zusbbuf[3]) {
    case 0x00:  // up
        zusbbuf[1] |= 0x20;
        break;
    case 0xff:  // down
        zusbbuf[1] |= 0x10;
        break;
    }

    uint16_t newjoystat = *(uint16_t *)zusbbuf;
    uint16_t changed = joystat ^ newjoystat;
    joystat = newjoystat;

    for (int i = 0; i < 16; i++) {
        if (changed & (1 << i)) {
            if (joystat & (1 << i)) {
                skeyset(joykey[15 - i]);
            } else {
                skeyset(joykey[15 - i] | 0x80);
            }
        }
    }

    zusb_send_cmd(ZUSB_CMD_SUBMITXFER(0));
}

int main(int argc, char **argv)
{
    printf("X68000 Z JOYCARD test\n");

    int stay = 0;
    int release = 0;

    for (int i = 1; i < argc; i++) {
        if (argv[i][0] == '/' || argv[i][0] =='-') {
            switch (argv[i][1]) {
            case 'r':
                release = 1;
                break;
            case 's':
                stay = 1;
                break;
            default:
                printf("X68000 Z JOYCARD からの入力をキー入力として扱います\n");
                printf("Usage: zusbjoyc.x [-s][-r]\n");
                break;
            }
        }
    }

    _iocs_b_super(0);

    if (release) {
        int v;
        uint32_t oldvect;
        for (v = 0xd0; v < 0xd4; v++) {
            char magic[4];
            oldvect = *(volatile uint32_t *)(v * 4);
            if (_dos_bus_err((void *)(oldvect - 4), magic, 4) == 0 &&
                strcmp(magic, "ZUJ") == 0) {
                break;
            }
        }
        if (v >= 0xd4) {
            printf("zusbjoyc が常駐していません\n");
            exit(1);
        }

        struct resident_param *rp = (struct resident_param *)(oldvect - 4 - sizeof(struct resident_param));

        zusb = *rp->oldzusb;
        zusbbuf = *rp->oldzusbbuf;
        zusb->inten = 0;
        zusb_disconnect_device();
        zusb_close();

        _iocs_b_intvcs(v, rp->oldvect);
        _dos_mfree(rp->mblock);
        printf("zusbjoyc の常駐を解除しました\n");
        exit(0);
    }

    int res = stay ? zusb_open_protected() : zusb_open();
    if (res < 0) {
        printf("ZUSB デバイスが見つかりません\n");
        exit(1);
    }

    while (_iocs_b_keysns() == 0) {
        int devid;
        struct iocs_time tm1, tm2;
        tm1 = _iocs_ontime();
        printf("\nX68000 Z JOYCARD を接続してください (何かキーを押すか10秒経つと終了します)\n");
        int quit = 0;
        zusb->stat = ZUSB_STAT_HOTPLUG;
        while ((devid = zusb_find_device_with_vid_pid(0x33dd, 0x0013, 0)) <= 0) {
            int stat;
            do {
                tm2 = _iocs_ontime();
                quit = (tm2.sec -tm1.sec >= (10 * 100));
                quit |= (_iocs_b_keysns() != 0);
                stat = zusb->stat & ZUSB_STAT_HOTPLUG;
            } while (stat == 0 && !quit);
            if (quit) {
                break;
            }
            zusb->stat = ZUSB_STAT_HOTPLUG;
        }
        if (quit) {
            break;
        }
        printf("X68000 Z JOYCARD が接続されました\n");

        zusb_endpoint_config_t epcfg[8] = {
            { ZUSB_DIR_IN, ZUSB_XFER_INTERRUPT, 0 },
            { 0, 0, -1 },
        };

        if (zusb_connect_device(devid, 1, ZUSB_CLASS_HID, -1, -1, epcfg) <= 0) {
            printf("X68000 Z JOYCARD に接続できません\n");
            zusb_close();
            return 0;
        }

        zusb_set_ep_region(0, zusbbuf, 4);

        zusb_send_control(ZUSB_REQ_CS_IF_OUT, 0x0a, 0x0000, 0, 0, NULL);    // SET_IDLE

        if (stay) {
            zusb->inten = 0;
            zusb_send_cmd(ZUSB_CMD_GETIVECT);
            resparam.oldvect = _iocs_b_intvcs(zusb->param & 0xff, zusbintr_asm);

            zusb_send_cmd(ZUSB_CMD_SUBMITXFER(0));
            zusb->inten = ZUSB_STAT_ERROR|ZUSB_STAT_PCOMPLETE(0);

            _dos_allclose();
            printf("常駐しました\n");
            _dos_keeppr(0xffffff, 0);
            exit(0);
        }

        while (_iocs_b_keysns() == 0) {
            int res = zusb_send_cmd(ZUSB_CMD_SUBMITXFER(0));
            if (res < 0) {
                break;
            }
            int stat;
            do {
                stat = zusb->stat;
            } while (!(stat & (ZUSB_STAT_PCOMPLETE(0)|ZUSB_STAT_ERROR|ZUSB_STAT_HOTPLUG)));
            zusb->stat = zusb->stat;

            if (stat & (ZUSB_STAT_ERROR|ZUSB_STAT_HOTPLUG)) {
                break;
            }

            for (int i = 0; i < zusb->pcount[0]; i++) {
                printf("%02x ", zusbbuf[i]);
            }
            printf("\r");
        }
        zusb_disconnect_device();
    }
    printf("\n終了します\n");
    zusb_close();
    exit(0);
}
