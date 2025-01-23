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
#include <unistd.h>
#include <fcntl.h>

#include <x68k/iocs.h>
#include <x68k/dos.h>

#include <zusb.h>

int main(int argc, char **argv)
{
    int devid = -1;
    int samplerate = -1;
    int volume = 9999;
    char *filename = NULL;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-h") == 0) {
            printf("Usage: %s [-h][-r<sample rate>][-v<volume>] [devid] [filename]\n", argv[0]);
            printf(" <sample rate>: 44100 or 48000\n");
            printf(" <volume>: -128 .. 127 (dB)\n");
            return 0;
        } else if (strncmp(argv[i], "-r", 2) == 0) {
            samplerate = strtol(&argv[i][2], NULL, 0);
        } else if (strncmp(argv[i], "-v", 2) == 0) {
            volume = strtol(&argv[i][2], NULL, 0);
        } else if (devid < 0) {
            devid = strtol(argv[i], NULL, 0);
        } else if (filename == NULL) {
            filename = argv[i];
        }
    }

    _iocs_b_super(0);

    if (zusb_open(0) < 0) {
        printf("ZUSB デバイスが見つかりません\n");
        exit(1);
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

    void audio_test(int epout, int samplerate, int volume, char *filename);
    audio_test(1, samplerate, volume, filename);

    zusb_disconnect_device();
    zusb_close();
    return 0;
}

//////////////////////////////////////////////////////////////////////////////

#define ZUSB_AUDIO_CS_SET_CUR   0x01
#define ZUSB_AUDIO_CS_GET_CUR   0x81

void audio_test(int epout, int samplerate, int volume, char *filename)
{
    int config = 1;
    int use_config = 0;
    int use_intf_subclass = 0;
    int use_audio_stream_if = 0;
    int volume_unit_id = 0;

    // Class-Specific Interface Descriptor から設定値を取得する

    int current_if;
    zusb_rewind_descriptor();
    while (zusb_get_descriptor(zusbbuf) > 0) {
        uint8_t *desc = zusbbuf;
        if (desc[1] == ZUSB_DESC_CONFIGURATION) {
            zusb_desc_configuration_t *dconf = (zusb_desc_configuration_t *)desc;
            use_config = (dconf->bConfigurationValue == config);
        } else if (desc[1] == ZUSB_DESC_INTERFACE) {
            zusb_desc_interface_t *dintf = (zusb_desc_interface_t *)desc;
            current_if = dintf->bInterfaceNumber;
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

    printf("audio_stream_if=%d volume_unit_id=%d\n", use_audio_stream_if, volume_unit_id);

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

    // 出力用interfaceをalt interface #1に切り替える (音が出るようになる)
    zusb->param = (use_audio_stream_if << 8) | 0x01;
    zusb_send_cmd(ZUSB_CMD_SETIFACE);

    //////////////////////////////////////////////////////////////////////////

    int ndesc = 2000;   // 1回のオーディオ出力でバッファリングするディスクリプタ数(1ms単位)

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

    int fd;
    if (!filename || ((fd = open(filename, O_RDONLY|O_BINARY)) < 0)) {
        printf("file open error\n");
        return;
    }

    // wavファイルだったらヘッダをスキップする
    uint8_t header[16];
    if (read(fd, header, sizeof(header)) == sizeof(header) &&
        memcmp(&header[0], "RIFF", 4) == 0 &&
        memcmp(&header[8], "WAVEfmt ", 8) == 0) {
        lseek(fd, 0x2c, SEEK_SET);
    } else {
        lseek(fd, 0, SEEK_SET);
    }

    printf("start:\n");

    int s = 0;
    while (1) {
        int key = _iocs_b_keysns();
        if (key) {
            _iocs_b_keyinp();
            if ((key & 0xff00) == 0x3d00) {         // ->
                lseek(fd, bufsize * 5, SEEK_CUR);
            } else if ((key & 0xff00) == 0x3b00) {  // <-
                lseek(fd, bufsize * -5, SEEK_CUR);
            } else {
                break;
            }
        }

        // バッファにデータを読み込む
        int len = read(fd, wbuf[s], bufsize);
        if (len <= 0) {
            break;
        }
        printf("length = %d %d\n", len, s);

        // エンディアンを反転 (出力データはlittle endian)
        uint16_t *w = (uint16_t *)wbuf[s];
        for (int i = 0; i < len; i += 2) {
            __asm__ volatile ("move.w %0@,%%d0\n"
                              "rol.w #8,%%d0\n"
                              "move.w %%d0,%0@\n" : : "a" (w) : "%%d0");
            w++;
        }

        // バッファのデータを出力する
        zusb_set_ep_region_isoc(epout, wbuf[s], desc[s], ndesc);
        zusb_send_cmd(ZUSB_CMD_SUBMITXFER(epout));

        // 前回のバッファの出力が終わるまで待つ
        while (zusb->pcount[epout] > ndesc) {
            printf("\r%d  ", zusb->pcount[epout]);
        }
        printf("\r%d  \n", zusb->pcount[epout]);

        // バッファの表裏を交代する
        s = 1 - s;
        memset(wbuf[s], 0, bufsize);
    }

    // ファイル末尾まで到達したのですべての出力が終わるまで待つ
    while (zusb->pcount[epout] > 0) {
        printf("\r%d  ", zusb->pcount[epout]);
    }
    printf("\r%d  \n", zusb->pcount[epout]);

    //////////////////////////////////////////////////////////////////////////

    zusb->param = (use_audio_stream_if << 8) | 0x00;
    zusb_send_cmd(ZUSB_CMD_SETIFACE);
}
