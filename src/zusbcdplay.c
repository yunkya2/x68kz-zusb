/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2025 Yuichi Nakamura (@yunkya2)
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
#include <unistd.h>
#include <fcntl.h>

#include <x68k/iocs.h>
#include <x68k/dos.h>

#include <zusb.h>

// SCSI コマンドを発行する
int scsi_cmd(int id, void *cmd, int cmd_len, void *buf, int buf_len)
{
    uint8_t stat;
    uint8_t msg;
    int res;

    if ((res = _iocs_s_select(id)) != 0) {
        return -1;
    }
    if ((res = _iocs_s_cmdout(cmd_len, cmd)) != 0) {
        return -1;
    }
    if (buf_len > 0) {
        if ((res = _iocs_s_datain(buf_len, buf)) != 0) {
            return -1;
        }
    }
    if ((res = _iocs_s_stsin(&stat))) {
        return -1;
    }
    if ((res = _iocs_s_msgin(&msg))) {
        return -1;
    }
    return 0;
}

#define ZUSB_AUDIO_CS_SET_CUR   0x01
#define ZUSB_AUDIO_CS_GET_CUR   0x81

void audio_play(int epout, int samplerate, int volume, int scsiid, int startsect, int endsect)
{
    int config = 1;
    int use_config = 0;
    int use_intf_subclass = 0;
    int use_audio_stream_if = 0;
    int use_audio_stream_altif = 0;
    int volume_unit_id = 0;

    // Class-Specific Interface Descriptor から設定値を取得する

    int current_if;
    int current_altif;
    zusb_rewind_descriptor();
    while (zusb_get_descriptor(zusbbuf) > 0) {
        uint8_t *desc = zusbbuf;
        if (desc[1] == ZUSB_DESC_CONFIGURATION) {
            zusb_desc_configuration_t *dconf = (zusb_desc_configuration_t *)desc;
            use_config = (dconf->bConfigurationValue == config);
        } else if (desc[1] == ZUSB_DESC_INTERFACE) {
            zusb_desc_interface_t *dintf = (zusb_desc_interface_t *)desc;
            current_if = dintf->bInterfaceNumber;
            current_altif = dintf->bAlternateSetting;
            use_intf_subclass = (dintf->bInterfaceClass == ZUSB_CLASS_AUDIO) ? dintf->bInterfaceSubClass : 0;
        }
        if (!use_config || !use_intf_subclass) {
            continue;   // Configuration, Interface がUACのものでなければスキップ
        }

        if (use_intf_subclass == 1) {           // Audio Control Interface
            if (desc[1] == ZUSB_DESC_CS_INTERFACE) {
                switch (desc[2]) {  // interface subtype
                case 0x02:  // INPUT_TERMINAL
                    break;
                case 0x03:  // OUTPUT_TERMINAL
                    if (desc[5] == 0x03) {          // Speaker
                        volume_unit_id = desc[7];   // スピーカーに繋がるUnitを音量制御のfeature unitとする
                    }
                    break;
                case 0x06:  // FEATURE_UNIT
                    break;
                }
            }
        } else if (use_intf_subclass == 2) {    // Audio Stremaing Interface
            static uint8_t cs_if_desc[32];
            switch (desc[1]) {
            case ZUSB_DESC_CS_INTERFACE:
                if (desc[2] == 0x02 && desc[0] < sizeof(cs_if_desc)) {  // FORMAT_TYPE_I
                    memcpy(cs_if_desc, desc, desc[0]);  // エンドポイントディスクリプタが来るまで取っておく
                }
                break;
            case ZUSB_DESC_ENDPOINT:
                zusb_desc_endpoint_t *dendp = (zusb_desc_endpoint_t *)desc;
                if ((dendp->bEndpointAddress & ZUSB_DIR_MASK) == ZUSB_DIR_OUT) {
                    use_audio_stream_if = current_if;   // OUT側EPを持つinterfaceを出力用interfaceとする
                }
                if (cs_if_desc[4] == 2 && cs_if_desc[6] == 16) {
                    use_audio_stream_altif = current_altif;   // 16bit stereoのinterfaceを出力用alt interfaceとする
                }

                printf("EP 0x%02x ", dendp->bEndpointAddress);
                printf("#ch:%d bit:%d", cs_if_desc[4], cs_if_desc[6]);
                printf(" supported freq:");
                for (int i = 0; i < cs_if_desc[7]; i++) {
                    int freq = cs_if_desc[8 + i * 3] + 
                              (cs_if_desc[9 + i * 3] << 8) +
                              (cs_if_desc[10 + i * 3] << 16);
                    printf(" %dHz", freq);
                }
                printf("\n");
                break;
            }
        }
    }

    printf("audio_stream_if=%d/%d volume_unit_id=%d\n", use_audio_stream_if, use_audio_stream_altif, volume_unit_id);

    if (volume_unit_id) {
#define AUDIO_FEATURE_UNIT_CS_VOLUME        0x02
        if (volume != 9999) {   // スピーカー直前のfeature unitに音量を設定する(L,R)
            *(uint16_t *)&zusbbuf[0] = zusb_htole16(volume * 256);
            *(uint16_t *)&zusbbuf[2] = zusb_htole16(volume * 256);
            zusb_send_control(ZUSB_REQ_CS_IF_OUT, ZUSB_AUDIO_CS_SET_CUR,
                             (AUDIO_FEATURE_UNIT_CS_VOLUME << 8) | 1,
                             volume_unit_id << 8, sizeof(uint16_t), &zusbbuf[0]);
            zusb_send_control(ZUSB_REQ_CS_IF_OUT, ZUSB_AUDIO_CS_SET_CUR,
                             (AUDIO_FEATURE_UNIT_CS_VOLUME << 8) | 2,
                             volume_unit_id << 8, sizeof(uint16_t), &zusbbuf[2]);
        } else {                // スピーカー直前のfeature unitから現在の音量を取得する(L,R)
            zusb_send_control(ZUSB_REQ_CS_IF_IN, ZUSB_AUDIO_CS_GET_CUR,
                             (AUDIO_FEATURE_UNIT_CS_VOLUME << 8) | 1,
                             volume_unit_id << 8, sizeof(uint16_t), &zusbbuf[0]);
            zusb_send_control(ZUSB_REQ_CS_IF_IN, ZUSB_AUDIO_CS_GET_CUR,
                             (AUDIO_FEATURE_UNIT_CS_VOLUME << 8) | 2,
                             volume_unit_id << 8, sizeof(uint16_t), &zusbbuf[2]);
        }
        printf("volume: %ddB/%ddB\n",
               (int16_t)zusb_le16toh(*(uint16_t *)&zusbbuf[0]) / 256,
               (int16_t)zusb_le16toh(*(uint16_t *)&zusbbuf[2]) / 256);
    }

    samplerate = (samplerate < 0) ? 44100 : samplerate;
    if (samplerate > 0) {    // 出力用endpointにサンプリングレートを設定する
        *(uint32_t *)&zusbbuf[0] = zusb_htole32(samplerate);
        zusb_send_control(ZUSB_REQ_CS_EP_OUT, ZUSB_AUDIO_CS_SET_CUR,
                          0x0100,    // sampling frequency
                          epout, 3, &zusbbuf[0]);
    }
    zusb_send_control(ZUSB_REQ_CS_EP_IN, ZUSB_AUDIO_CS_GET_CUR,
                      0x0100,    // sampling frequency
                      epout, 3, &zusbbuf[0]);
    printf("sampling rate: %ldHz\n", zusb_le32toh(*(uint32_t *)&zusbbuf[0]));

    // 出力用interfaceを16bit stereoのinterfaceに切り替える (音が出るようになる)
    zusb->param = (use_audio_stream_if << 8) | use_audio_stream_altif;
    zusb_send_cmd(ZUSB_CMD_SETIFACE);

    //////////////////////////////////////////////////////////////////////////

    int sec = 2;
    int ndesc = 1000 * sec;   // 1回のオーディオ出力でバッファリングするディスクリプタ数(1ms単位)

    struct zusb_isoc_desc *desc[2];
    desc[0] = calloc(ndesc, sizeof(struct zusb_isoc_desc));
    desc[1] = calloc(ndesc, sizeof(struct zusb_isoc_desc));
    if (desc[0] == NULL || desc[1] == NULL) {
        printf("malloc error\n");
        return;
    }

    // ISOディスクリプタを初期化し、1回の出力に使用するデータ量を得る
    int bufsize = 0;
    int fdiv = samplerate * 4 / 1000;   // 1フレーム(1ms)に入るデータ量
    int frem = samplerate * 4 % 1000;   //  .. の余り
    int fcount = 0;
    for (int i = 0; i < ndesc; i++) {
        fcount += frem;
        if (fcount >= 4000) {   // 余りの処理
            fcount -= 4000;     // (44100Hzの場合、176bytes/frameが10回に1回180bytes/frameになる)
            desc[0][i].size = desc[1][i].size = fdiv + 4;
            bufsize += fdiv + 4;
        } else {
            desc[0][i].size = desc[1][i].size = fdiv;
            bufsize += fdiv;
        }
    }
    printf("bufsize = %d * 2 bytes\n", bufsize);

    uint8_t *wbuf[2];
    wbuf[0] = calloc(1, bufsize);
    wbuf[1] = calloc(1, bufsize);
    if (wbuf[0] == NULL || wbuf[1] == NULL) {
        printf("malloc error\n");
        return;
    }

    // CD-ROM読み出し速度を最高速に設定する
    static uint8_t cmd_cdspeed[] = { 0xbb, 0x00, 0xff, 0xff, 0, 0, 0, 0, 0, 0, 0, 0 };
    if (scsi_cmd(scsiid, cmd_cdspeed, sizeof(cmd_cdspeed), NULL, 0) < 0) {
        printf("cannot change CD-ROM speed\n");
        return;
    }

    uint32_t sectoff = 0;
    uint32_t nsects = endsect - startsect;

    uint8_t cmd_readcd[12];
    uint32_t counter = 75 * sec;
    cmd_readcd[0] = 0xd8;
    cmd_readcd[6] = counter >> 24;
    cmd_readcd[7] = counter >> 16;
    cmd_readcd[8] = counter >> 8;
    cmd_readcd[9] = counter;

    printf("start:\n");
    int readtime = 0;

    int s = 0;
    while (1) {
        int key = _iocs_b_keysns();
        if (key) {
            _iocs_b_keyinp();
            if ((key & 0xff00) == 0x3d00) {         // ->
                sectoff += 75 * 5;
            } else if ((key & 0xff00) == 0x3b00) {  // <-
                sectoff -= 75 * 5;
            } else {
                break;
            }
        }

        if (sectoff < 0 || sectoff >= nsects) {
            break;
        }

        struct iocs_time tm1 = _iocs_ontime();

        // バッファにデータを読み込む
        uint32_t readsect = startsect + sectoff;
        uint32_t remainsects = nsects - sectoff;
        uint32_t readcount = remainsects < counter ? remainsects : counter;

        cmd_readcd[2] = readsect >> 24;
        cmd_readcd[3] = readsect >> 16;
        cmd_readcd[4] = readsect >>  8;
        cmd_readcd[5] = readsect;
        if (scsi_cmd(scsiid, cmd_readcd, sizeof(cmd_readcd), wbuf[s], readcount * 2352) < 0) {
            printf("cannot read CD\n");
            break;
        }
        sectoff += readcount;
        int len = readcount * 2352;

        struct iocs_time tm2 = _iocs_ontime();

        // isochronous転送時にエンディアンが反転するので、あらかじめ反転しておく
         __asm__ volatile (
            "movea.l %0,%%a0\n"
            "1:\n"
            "movep.l %%a0@(0),%%d0\n"
            "movep.l %%a0@(1),%%d1\n"
            "movep.l %%d0,%%a0@(1)\n"
            "movep.l %%d1,%%a0@(0)\n"
            "movep.l %%a0@(8),%%d0\n"
            "movep.l %%a0@(9),%%d1\n"
            "movep.l %%d0,%%a0@(9)\n"
            "movep.l %%d1,%%a0@(8)\n"
            "movep.l %%a0@(16),%%d0\n"
            "movep.l %%a0@(17),%%d1\n"
            "movep.l %%d0,%%a0@(17)\n"
            "movep.l %%d1,%%a0@(16)\n"
            "movep.l %%a0@(24),%%d0\n"
            "movep.l %%a0@(25),%%d1\n"
            "movep.l %%d0,%%a0@(25)\n"
            "movep.l %%d1,%%a0@(24)\n"
            "lea.l %%a0@(32),%%a0\n"
            "cmpa.l %1,%%a0\n"
            "blt.b 1b\n"
            : : "a" (wbuf[s]), "a" (wbuf[s] + len) : "%%d0", "%%d1", "%%a0");

        struct iocs_time tm3 = _iocs_ontime();

        // バッファのデータを出力する
        zusb_set_ep_region_isoc(epout, wbuf[s], desc[s], ndesc);
        zusb_send_cmd(ZUSB_CMD_SUBMITXFER(epout));

        // 前回のバッファの出力が終わるまで待つ
        while (zusb->pcount[epout] > ndesc) {
        }

        printf("\r%ld:%02ld read %ld sectors %d0ms %d0ms  ",
               sectoff / 75 / 60, sectoff / 75 % 60,
               readcount, tm2.sec - tm1.sec, tm3.sec - tm2.sec);
        fflush(stdout);
        readtime += tm2.sec - tm1.sec;

        // バッファの表裏を交代する
        s = 1 - s;
        memset(wbuf[s], 0, bufsize);
    }

    printf("\n");

    // ファイル末尾まで到達したのですべての出力が終わるまで待つ
    while (zusb->pcount[epout] > 0) {
        printf("\r%d  ", zusb->pcount[epout]);
    }
    printf("\r%d  \n", zusb->pcount[epout]);

    // 出力用interfaceをalt interface #0に戻す (音を止める)
    zusb->param = (use_audio_stream_if << 8) | 0x00;
    zusb_send_cmd(ZUSB_CMD_SETIFACE);
}

//////////////////////////////////////////////////////////////////////////////

int main(int argc, char **argv)
{
    int devid = -1;
    int devvid = -1;
    int devpid = -1;
    int samplerate = 44100;
    int volume = 9999;
    int scsiid = 6;
    int track = 0;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-h") == 0) {
            printf("Usage: %s [-h][-v<volume>][-i<scsiid>] [devid | vid:pid] [track]\n", argv[0]);
            printf(" <volume>: -128 .. 127 (dB)\n");
            return 0;
        } else if (strncmp(argv[i], "-v", 2) == 0) {
            volume = strtol(&argv[i][2], NULL, 0);
        } else if (strncmp(argv[i], "-i", 2) == 0) {
            scsiid = strtol(&argv[i][2], NULL, 0);
        } else if (strchr(argv[i], ':') && ((devvid < 0) || (devpid < 0))) {
            devvid = strtol(argv[i], NULL, 16);
            devpid = strtol(strchr(argv[i], ':') + 1, NULL, 16);
        } else if (devvid < 0 && devpid < 0 && devid < 0) {
            devid = strtol(argv[i], NULL, 0);
        } else if (track == 0) {
            track = strtol(argv[i], NULL, 0);
        }
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
        // devid の指定がなかったらUACデバイス一覧を表示する
        printf("UAC devices\n");
        devid = 0;
        while ((devid = zusb_find_device_with_devclass(ZUSB_CLASS_AUDIO, -1, -1, devid))) {
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

    // UACデバイスに接続する

    zusb_endpoint_config_t epcfg[ZUSB_N_EP] = {
        { ZUSB_DIR_IN,  ZUSB_XFER_ISOCHRONOUS, 0 },
        { ZUSB_DIR_OUT, ZUSB_XFER_ISOCHRONOUS, 0 },
        { 0, 0, -1 },
    };

    if (zusb_connect_device(devid, 1, ZUSB_CLASS_AUDIO, -1, -1, epcfg) <= 0) {
        printf("USB UACに接続できません\n");
        zusb_close();
        return 0;
    }

    uint8_t cmd_readtoc[12] = { 0x43, 0x00 };
    cmd_readtoc[8] = 12;
    cmd_readtoc[6] = 0xaa;
    uint8_t buf_readtoc[12];

    if (scsi_cmd(scsiid, cmd_readtoc, sizeof(cmd_readtoc), buf_readtoc, sizeof(buf_readtoc)) < 0) {
        printf("cannot read TOC\n");
        return 0;
    }
    int firsttrack = buf_readtoc[2];
    int lasttrack = buf_readtoc[3];

    if (track > 0) {
        // CD-DAのTOC情報を取得して再生する

        if (track < firsttrack || track > lasttrack) {
            printf("track %d is out of range\n", track);
            return 0;
        }
        uint32_t lastlba = zusb_be32toh(*(uint32_t *)&buf_readtoc[8]);

        cmd_readtoc[6] = track;
        if (scsi_cmd(scsiid, cmd_readtoc, sizeof(cmd_readtoc), buf_readtoc, sizeof(buf_readtoc)) < 0) {
            printf("cannot read TOC\n");
            return 0;
        }
        uint32_t firstlba = zusb_be32toh(*(uint32_t *)&buf_readtoc[8]);

        if (track < lasttrack) {
            cmd_readtoc[6] = track + 1;
            if (scsi_cmd(scsiid, cmd_readtoc, sizeof(cmd_readtoc), buf_readtoc, sizeof(buf_readtoc)) < 0) {
                printf("cannot read TOC\n");
                return 0;
            }
            lastlba = zusb_be32toh(*(uint32_t *)&buf_readtoc[8]);
        }
        printf("firstlba=0x%lx lastlba=0x%lx\n", firstlba, lastlba);
        audio_play(1, samplerate, volume, scsiid, firstlba, lastlba);
    } else {
        // TOC情報一覧を表示する

        uint32_t firstlba = 0;
        uint32_t nextlba;
        uint32_t lastlba = zusb_be32toh(*(uint32_t *)&buf_readtoc[8]);
        for (int tr = firsttrack; tr <= lasttrack + 1; tr++) {
            if (tr <= lasttrack) {
                cmd_readtoc[6] = tr;
                if (scsi_cmd(scsiid, cmd_readtoc, sizeof(cmd_readtoc), buf_readtoc, sizeof(buf_readtoc)) < 0) {
                    printf("cannot read TOC\n");
                    return 0;
                }
                nextlba = zusb_be32toh(*(uint32_t *)&buf_readtoc[8]);
            } else {
                nextlba = lastlba;
            }

            if (tr > firsttrack) {
                uint32_t from = firstlba + 75 * 2;
                uint32_t to = nextlba + 75 * 2 - 1;
                uint32_t dur = nextlba - firstlba;
                printf("%u: %02lu:%02lu:%02lu - %02lu:%02lu:%02lu (%02lu:%02lu:%02lu)\n",
                       tr - 1,
                       (from / 75 / 60) % 60, (from / 75) % 60, from % 75,
                       (to / 75 / 60) % 60, (to / 75) % 60, to % 75,
                       (dur / 75 / 60) % 60, (dur / 75) % 60, dur % 75);
            }
            firstlba = nextlba;
        }
    }

    zusb_disconnect_device();
    zusb_close();
    return 0;
}
