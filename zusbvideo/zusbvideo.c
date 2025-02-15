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
    int devvid = -1;
    int devpid = -1;
    int frames = -1;
    int videosize = -1;
    int resolution = -1;
    int mjpeg = false;
    int verbose = false;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-h") == 0) {
            printf("Usage: %s [-h][-v][-m][-r<resolution>][-s<videosize>] [devid | vid:pid] [frames]\n", argv[0]);
            printf(" <resolution>: 0=no display 1=256x256(default) 2=512x512\n");
            printf(" <video size>: 0=160x120(default) 1=320x240\n");
            return 0;
        } else if (strncmp(argv[i], "-v", 2) == 0) {
            verbose = true;
        } else if (strncmp(argv[i], "-m", 2) == 0) {
            mjpeg = true;
        } else if (strncmp(argv[i], "-r", 2) == 0) {
            resolution = strtol(&argv[i][2], NULL, 0);
        } else if (strncmp(argv[i], "-s", 2) == 0) {
            videosize = strtol(&argv[i][2], NULL, 0);
        } else if (strchr(argv[i], ':') && ((devvid < 0) || (devpid < 0))) {
            devvid = strtol(argv[i], NULL, 16);
            devpid = strtol(strchr(argv[i], ':') + 1, NULL, 16);
        } else if (devid < 0) {
            devid = strtol(argv[i], NULL, 0);
        } else if (frames < 0) {
            frames = strtol(argv[i], NULL, 0);
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
        // devid の指定がなかったらUVCデバイス一覧を表示する
        printf("UVC devices\n");
        devid = 0;
        while ((devid = zusb_find_device_with_devclass(ZUSB_CLASS_VIDEO, -1, -1, devid))) {
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

    // UVCデバイスに接続する

    zusb_endpoint_config_t epcfg[ZUSB_N_EP] = {
        { ZUSB_DIR_IN,  ZUSB_XFER_ISOCHRONOUS, 0 },
        { 0, 0, -1 },
    };

    if (zusb_connect_device(devid, 1, ZUSB_CLASS_VIDEO, -1, -1, epcfg) <= 0) {
        printf("USB UVCに接続できません\n");
        zusb_close();
        return 0;
    }

    void video_test(int epin, int videosize, int frames, int verbose, int resolution, int mjpeg);
    video_test(0, videosize, frames, verbose, resolution, mjpeg);

    zusb_disconnect_device();
    zusb_close();
    return 0;
}

//////////////////////////////////////////////////////////////////////////////

void yuv2rgbinit(void);
uint8_t *yuv2rgb(uint8_t *p, uint16_t *gv, int width);

typedef struct __attribute__((packed)) uvc_desc_vc_header {
    uint8_t bLength;
    uint8_t bDescriptorType;
    uint8_t bDescriptorSubtype;
    uint_le16_t bcdUVC;
    uint_le16_t wTotalLength;
    uint_le32_t dwClockFrequency;
    uint8_t bInCollection;
    uint8_t baInterfaceNr[];
} uvc_desc_vc_header_t;

typedef struct __attribute__((packed)) uvc_streaming_control {
    uint_le16_t bmHint;
    uint8_t bFormatIndex;
    uint8_t bFrameIndex;
    uint_le32_t dwFrameInterval;
    uint_le16_t wKeyFrameRate;
    uint_le16_t wPFrameRate;
    uint_le16_t wCompQuality;
    uint_le16_t wCompWindowSize;
    uint_le16_t wDelay;
    uint_le32_t dwMaxVideoFrameSize;
    uint_le32_t dwMaxPayloadTransferSize;
    uint_le32_t dwClockFrequency;
    uint8_t bmFramingInfo;
    uint8_t bPreferedVersion;
    uint8_t bMinVersion;
    uint8_t bMaxVersion;
} uvc_streaming_control_t;

typedef struct __attribute__((packed)) uvc_desc_vs_format_uncompressed {
    uint8_t bLength;
    uint8_t bDescriptorType;
    uint8_t bDescriptorSubType;
    uint8_t bFormatIndex;
    uint8_t bNumFrameDescriptors;
    uint8_t guidFormat[16];
    uint8_t bBitsPerPixel;
    uint8_t bDefaultFrameIndex;
    uint8_t bAspectRatioX;
    uint8_t bAspectRatioY;
    uint8_t bmInterfaceFlags;
    uint8_t bCopyProtect;
} uvc_desc_vs_format_uncompressed_t;

typedef struct __attribute__((packed)) uvc_desc_vs_frame_uncompressed {
    uint8_t bLength;
    uint8_t bDescriptorType;
    uint8_t bDescriptorSubType;
    uint8_t bFrameIndex;
    uint8_t bmCapabilities;
    uint_le16_t wWidth;
    uint_le16_t wHeight;
    uint_le32_t dwMinBitRate;
    uint_le32_t dwMaxBitRate;
    uint_le32_t dwMaxVideoFrameBufferSize;
    uint_le32_t dwDefaultFrameInterval;
    uint8_t bFrameIntervalType;
    uint_le32_t dwFrameInterval[];
} uvc_desc_vs_frame_uncompressed_t;

typedef struct __attribute__((packed)) uvc_desc_vs_format_mjpeg {
    uint8_t bLength;
    uint8_t bDescriptorType;
    uint8_t bDescriptorSubtype;
    uint8_t bFormatIndex;
    uint8_t bNumFrameDescriptors;
    uint8_t bmFlags;
    uint8_t bDefaultFrameIndex;
    uint8_t bAspectRatioX;
    uint8_t bAspectRatioY;
    uint8_t bmInterlaceFlags;
    uint8_t bCopyProtect;
} uvc_desc_vs_format_mjpeg_t;

typedef struct __attribute__((packed)) uvc_desc_vs_frame_mjpeg {
    uint8_t bLength;
    uint8_t bDescriptorType;
    uint8_t bDescriptorSubtype;
    uint8_t bFrameIndex;
    uint8_t bmCapabilities;
    uint_le16_t wWidth;
    uint_le16_t wHeight;
    uint_le32_t dwMinBitRate;
    uint_le32_t dwMaxBitRate;
    uint_le32_t dwMaxVideoFrameBufferSize;
    uint_le32_t dwDefaultFrameInterval;
    uint8_t bFrameIntervalType;
    uint_le32_t dwFrameInterval[];
} uvc_desc_vs_frame_mjpeg_t;

#define ZUSB_REQ_CS_SET_CUR   0x01
#define ZUSB_REQ_CS_GET_CUR   0x81
#define ZUSB_REQ_CS_SET_MAX   0x03
#define ZUSB_REQ_CS_GET_MAX   0x83

static const uint8_t guid_yuy2[] =
{ 0x59, 0x55, 0x59, 0x32,  0x00, 0x00,  0x10, 0x00,  0x80, 0x00,
  0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71 };

void disp_video_cs_request(void *buf)
{
    uvc_streaming_control_t *uvcctrl = (uvc_streaming_control_t *)buf;
    printf("fmt:%d frame:%d interval:%ld videosize:%ld payloadsize:%ld\n",
           uvcctrl->bFormatIndex, uvcctrl->bFrameIndex,
           zusb_le32toh(uvcctrl->dwFrameInterval),
           zusb_le32toh(uvcctrl->dwMaxVideoFrameSize),
           zusb_le32toh(uvcctrl->dwMaxPayloadTransferSize));
}

void video_test(int epin, int videosize, int frames, int verbose, int resolution, int mjpeg)
{
    int config = 1;
    int use_config = 0;
    int use_intf_subclass = 0;
    int use_video_stream_if = -1;
    int use_format_id = -1;
    int use_frame_id = -1;
    int current_format_id = 0;
    int bcdUVC = 0;

    int vsize_w;
    int vsize_h;
    switch (videosize) {
    default:
    case 0:
        vsize_w = 160;
        vsize_h = 120;
        break;
    case 1:
        vsize_w = 320;
        vsize_h = 240;
        break;
    case 2:
        vsize_w = 640;
        vsize_h = 480;
        break;
    case 3:
        vsize_w = 800;
        vsize_h = 600;
        break;
    case 4:
        vsize_w = 1280;
        vsize_h = 720;
        break;
    }

    if (frames < 0) {
        frames = 20;
    }

    // Class-Specific Interface Descriptor から設定値を取得する (format ID, frame IDを取得)

    zusb_rewind_descriptor();
    while (zusb_get_descriptor(zusbbuf) > 0) {
        uint8_t *desc = zusbbuf;
        if (desc[1] == ZUSB_DESC_CONFIGURATION) {
            zusb_desc_configuration_t *dconf = (zusb_desc_configuration_t *)desc;
            use_config = (dconf->bConfigurationValue == config);
        } else if (desc[1] == ZUSB_DESC_INTERFACE) {
            zusb_desc_interface_t *dintf = (zusb_desc_interface_t *)desc;
            use_intf_subclass = (dintf->bInterfaceClass == ZUSB_CLASS_VIDEO) ? dintf->bInterfaceSubClass : 0;
            if (use_intf_subclass == 2) {
                use_video_stream_if = dintf->bInterfaceNumber;
            }
        }
        if (!use_config) {
            continue;   // ConfigurationがUVCのものでなければスキップ
        }

        if (use_intf_subclass == 1) {           // Video Control Interface
            switch (desc[1]) {
            case ZUSB_DESC_CS_INTERFACE:
                if (desc[2] == 0x01) {          // VC_HEADER
                    uvc_desc_vc_header_t *dvch = (uvc_desc_vc_header_t *)desc;
                    bcdUVC = zusb_le16toh(dvch->bcdUVC);
                    break;
                }
            }
        } else if (use_intf_subclass == 2) {    // Video Streaming Interface
            switch (desc[1]) {
            case ZUSB_DESC_CS_INTERFACE:
                if (!mjpeg && desc[2] == 0x04) {            // VS_FORMAT_UNCOMPRESSED
                    uvc_desc_vs_format_uncompressed_t *dformat = (uvc_desc_vs_format_uncompressed_t *)desc;
                    current_format_id = dformat->bFormatIndex;
                    if (memcmp(dformat->guidFormat, guid_yuy2, sizeof(guid_yuy2)) == 0) {
                        use_format_id = current_format_id;
                    }
                } else if (!mjpeg && desc[2] == 0x05 &&     // VS_FRAME_UNCOMPRESSED
                           current_format_id == use_format_id) {
                    uvc_desc_vs_frame_uncompressed_t *dframe = (uvc_desc_vs_frame_uncompressed_t *)desc;
                    printf("frame id %d ", dframe->bFrameIndex);
                    printf("%d x %d ", zusb_le16toh(dframe->wWidth), zusb_le16toh(dframe->wHeight));
                    printf("%ldbps", zusb_le32toh(dframe->dwMaxBitRate));
                    printf("\n");
                    if (zusb_le16toh(dframe->wWidth) == vsize_w &&
                        zusb_le16toh(dframe->wHeight) == vsize_h) {
                        use_frame_id = dframe->bFrameIndex;
                    }
                } else if (mjpeg && desc[2] == 0x06) {      // VS_FORMAT_MJPEG
                    uvc_desc_vs_format_mjpeg_t *dformat = (uvc_desc_vs_format_mjpeg_t *)desc;
                    current_format_id = dformat->bFormatIndex;
                    use_format_id = current_format_id;
                } else if (mjpeg && desc[2] == 0x07 &&      // VS_FRAME_MJPEG
                           current_format_id == use_format_id) {
                    uvc_desc_vs_frame_mjpeg_t *dframe = (uvc_desc_vs_frame_mjpeg_t *)desc;
                    printf("frame id %d ", dframe->bFrameIndex);
                    printf("%d x %d ", zusb_le16toh(dframe->wWidth), zusb_le16toh(dframe->wHeight));
                    printf("%ldbps", zusb_le32toh(dframe->dwMaxBitRate));
                    printf("\n");
                    if (zusb_le16toh(dframe->wWidth) == vsize_w &&
                        zusb_le16toh(dframe->wHeight) == vsize_h) {
                        use_frame_id = dframe->bFrameIndex;
                    }
                }
                break;
            }
        }
    }

    if (use_video_stream_if < 0 || use_format_id < 0 || use_frame_id < 0) {
        printf("要求する解像度にUVCデバイスが対応していません\n");
        return;
    }

    // Video format, frame設定をネゴシエーションする

    size_t scsize = bcdUVC >= 0x0110 ? sizeof(uvc_streaming_control_t) : 26;
    uvc_streaming_control_t *uvcctrl = (uvc_streaming_control_t *)zusbbuf;

    printf("GET_MAX: ");
    zusb_send_control(ZUSB_REQ_CS_IF_IN, ZUSB_REQ_CS_GET_MAX,
                      0x0100,    // VS_PROBE_CONTROL
                      use_video_stream_if, scsize, uvcctrl);
    disp_video_cs_request(uvcctrl);
    uvcctrl->bFormatIndex = use_format_id;
    uvcctrl->bFrameIndex = use_frame_id;
    uvcctrl->dwFrameInterval = zusb_htole32(10000000 / 30);  // 30fps
    uvcctrl->dwMaxPayloadTransferSize = zusb_htole32(1024);

    printf("SET_CUR: ");
    zusb_send_control(ZUSB_REQ_CS_IF_OUT, ZUSB_REQ_CS_SET_CUR,
                      0x0100,    // VS_PROBE_CONTROL
                      use_video_stream_if, scsize, uvcctrl);
    disp_video_cs_request(uvcctrl);
    printf("GET_CUR: ");
    zusb_send_control(ZUSB_REQ_CS_IF_IN, ZUSB_REQ_CS_GET_CUR,
                      0x0100,    // VS_PROBE_CONTROL
                      use_video_stream_if, scsize, uvcctrl);
    disp_video_cs_request(uvcctrl);
    printf("COMMIT: ");
    zusb_send_control(ZUSB_REQ_CS_IF_OUT, ZUSB_REQ_CS_SET_CUR,
                      0x0200,    // VS_COMMIT_CONTROL
                      use_video_stream_if, scsize, uvcctrl);
    disp_video_cs_request(uvcctrl);

    int req_payload = zusb_le32toh(uvcctrl->dwMaxPayloadTransferSize);
    // High-bandwidth transferが動作しないのでpayload sizeを最大1024bytesに制限する
    req_payload = req_payload < 1024 ? req_payload : 1024;
    printf("requested payload size=%d\n", req_payload);

    // Class-Specific Interface Descriptor から設定値を取得する (altsettingを取得)

    int use_altif = -1;
    int use_payload = -1;
    int ifno = 0;
    zusb_rewind_descriptor();
    while (zusb_get_descriptor(zusbbuf) > 0) {
        int altif;
        uint8_t *desc = zusbbuf;
        if (desc[1] == ZUSB_DESC_CONFIGURATION) {
            zusb_desc_configuration_t *dconf = (zusb_desc_configuration_t *)desc;
            use_config = (dconf->bConfigurationValue == config);
        } else if (desc[1] == ZUSB_DESC_INTERFACE) {
            zusb_desc_interface_t *dintf = (zusb_desc_interface_t *)desc;
            ifno = dintf->bInterfaceNumber;
            altif = dintf->bAlternateSetting;
        }
        if (!use_config || ifno != use_video_stream_if) {
            continue;   // Configuration, InterfaceがUVC Video Streaming Interfaceでなければスキップ
        }

        if (desc[1] == ZUSB_DESC_ENDPOINT) {
            zusb_desc_endpoint_t *dendp = (zusb_desc_endpoint_t *)desc;
            int eppayload = zusb_le16toh(dendp->wMaxPacketSize);
            // 選択したframe IDが要求するpayloadを満たすendpointのaltsettingを探す
            if (eppayload >= req_payload) {
                if (use_payload < 0 || use_payload > eppayload) {
                    use_payload = eppayload;
                    use_altif = altif;
                }
            }
        }
    }

    printf("format:%d frame:%d altif:%d payload:%dbytes\n",
           use_format_id, use_frame_id, use_altif, use_payload);

    if (use_payload > 1024) {
        printf("要求するペイロードサイズにUVCデバイスが対応していません\n");
        return;
    }

    zusb->param = (use_video_stream_if << 8) | use_altif;
    zusb_send_cmd(ZUSB_CMD_SETIFACE);

    //////////////////////////////////////////////////////////////////////////

    int ndesc;      // 1画面分のデータを取得するのに必要なディスクリプタ数

    switch (videosize) {
    case 0:
        ndesc = 1024;
        break;
    case 1:
    default:
        ndesc = 2048;
        break;
    }
    if (mjpeg) {
        ndesc *= 2;
    }

    uint8_t *wbuf[2];
    struct zusb_isoc_desc *desc[2];
    wbuf[0] = malloc(ndesc * use_payload);
    wbuf[1] = malloc(ndesc * use_payload);
    desc[0] = calloc(ndesc, sizeof(struct zusb_isoc_desc));
    desc[1] = calloc(ndesc, sizeof(struct zusb_isoc_desc));
    if (wbuf[0] == NULL || wbuf[1] == NULL || desc[0] == NULL || desc[1] == NULL) {
        printf("malloc error\n");
        return;
    }

    // ISOディスクリプタを初期化する
    for (int i = 0; i < ndesc; i++) {
        desc[0][i].size = use_payload;
        desc[1][i].size = use_payload;
    }

    printf("start\n");

    if (!mjpeg) {
        switch (resolution) {
        case 0:     // no display
            break;
        default:
        case 1:     // 256x256
            _iocs_crtmod(14);
            _iocs_g_clr_on();
            break;
        case 2:     // 512x512
            _iocs_crtmod(12);
            _iocs_g_clr_on();
            break;
        }

        yuv2rgbinit();
    }

    // バッファにデータを入力する
    zusb_set_ep_region_isoc(epin, wbuf[0], desc[0], ndesc);
    zusb_send_cmd(ZUSB_CMD_SUBMITXFER(epin));

    struct iocs_time tm1, tm2;
    tm1 = _iocs_ontime();

    int count = 0;

    int s = 1;
    for (int f = 0; (frames == 0) || (f < frames); f++) {
        s = 1 - s;
        if (_iocs_b_keysns()) {
            break;
        }

        // 裏側のバッファにデータを入力する
        zusb_set_ep_region_isoc(epin, wbuf[1 - s], desc[1 - s], ndesc);
        zusb_send_cmd(ZUSB_CMD_SUBMITXFER(epin));

        // 表側バッファの入力が終わるまで待つ
        while (zusb->pcount[epin] > ndesc) {
            if (verbose) printf("\r%d  ", zusb->pcount[epin]);
        }
        if (verbose) printf("\r%d  \n", zusb->pcount[epin]);

        // 表側バッファから1画面分のデータを探し出す
        int total = 0;
        int head = 0;
        int firstdesc = -1;
        uint8_t *buf = wbuf[s];
        for (int i = 0; i < ndesc; i++, buf += use_payload) {
            if (desc[s][i].actual == 0) {           // frameにデータがない
                if (verbose) printf(".");
                continue;
            }
            if (desc[s][i].actual < buf[1]) {
                printf("\nerror: %d %d %d\n", i, desc[s][i].actual, buf[1]);
                head = i + 1;
                continue;
            }
            total += desc[s][i].actual - buf[1];    // stream headerを除いたデータ長
            if (verbose) printf("%x", buf[0] & 0xf);
            if (buf[0] & 2) {                       // End of Frame
                if (mjpeg) {
                    if (firstdesc >= 0) {
                        break;                      // MJPEGの場合は長さが不定
                    }
                    firstdesc = i + 1;              // 最初のフレームのEOFの次を取得フレームとする
                    total = 0;
                } else {
                    if (total == vsize_w * vsize_h * 2) {
                        firstdesc = head;           // 1画面分のデータの後にEOFが来たので検索完了
                        break;
                    }
                    head = i + 1;                   // 不完全なデータだったので次のフレームを探す
                    total = 0;
                }
            }
        }
        if (verbose) {
            if (firstdesc < 0) {
                printf("\n** frame data not found\n");
            } else {
                printf("\nfirst desc:%d total:%d\n", firstdesc, total);
            }
        }

        if (firstdesc < 0) {    // 不完全なデータしか得られなかったのでスキップする
            continue;
        }
        if (resolution == 0) {  // 画面表示しない
            continue;
        }

        if (mjpeg) {            // MJPEGの場合はJPEGデータをファイルに保存する
            FILE *fp = NULL;
            int first = 1;
            for (int i = firstdesc; i < ndesc; i++) {
                int size = desc[s][i].actual;
                if (size == 0) {
                    continue;
                }
                uint8_t *buf = wbuf[s] + i * use_payload;
                int end = buf[0] & 2;
                size -= buf[1];         // stream headerを飛ばす
                buf += buf[1];

                if (first) {
                    if (buf[0] == 0xd8 && buf[1] == 0xff) {
                        char name[100];
                        sprintf(name, "video%03d.jpg", count++);
                        fp = fopen(name, "wb");
                        printf("writing %s\n", name);
                    } else {
                        printf("ignore frame\n");
                        break;
                    }
                    first = 0;
                }

                for (int j = 0; j < size; j += 2) {
                    fputc(buf[j + 1], fp);
                    fputc(buf[j], fp);
                }
                if (end) {
                    break;
                }
            }
            if (fp) {
                fclose(fp);
            }
            continue;
        }

        // 見つかった1画面分のデータを表示する
        uint16_t *gv = (uint16_t *)0xc00000;
        uint16_t *gh = gv;
        int xr = vsize_w;
        int yr = vsize_h;
        int once = false;
        for (int i = firstdesc; i < ndesc; i++) {
            int size = desc[s][i].actual;
            if (size == 0) {
                continue;
            }
            if (!once) {
                if (!verbose) printf("\x1b[10;1H");
                printf("count=%d PTS=%d\n", f + 1, (buf[2] << 8) | buf[3] | (buf[4] << 24) | (buf[5] << 16));
                once = true;
            }

            uint8_t *buf = wbuf[s] + i * use_payload;
            size -= buf[1];         // stream headerを飛ばす
            buf += buf[1];
            size /= 2;

            while (size > 0) {
                int w = xr > size ? size : xr;
                buf = yuv2rgb(buf, gh, w);
                xr -= w;
                gh += w;
                size -= w;
                if (xr <= 0) {
                    xr = vsize_w;
                    yr--;
                    gv += 512;
                    gh = gv;
                    if (yr <= 0) {
                        i = ndesc;
                        break;
                    }
                }
            }
        }
    }

    // バッファの入力が終わるまで待つ
    while (zusb->pcount[epin] > 0) {
        if (verbose) printf("\r%d  ", zusb->pcount[epin]);
    }
    if (verbose) printf("\r%d  \n", zusb->pcount[epin]);

    tm2 = _iocs_ontime();
    printf("time=%d\n",tm2.sec - tm1.sec);

    //////////////////////////////////////////////////////////////////////////

    zusb->param = (use_video_stream_if << 8) | 0x00;
    zusb_send_cmd(ZUSB_CMD_SETIFACE);

    free(wbuf[0]);
    free(wbuf[1]);
    free(desc[0]);
    free(desc[1]);
}

//////////////////////////////////////////////////////////////////////////////
// YUV -> RGB 変換
//  R = clip((298 * (Y - 16) + 409 * (V - 128) + 128) >> 8)
//  G = clip((298 * (Y - 16) - 100 * (U - 128) - 208 * (V - 128) + 128) >> 8)
//  B = clip((298 * (Y - 16) + 516 * (U - 128) + 128) >> 8)

int16_t vrtbl[256];
int16_t vgtbl[256];
int16_t ugtbl[256];
int16_t ubtbl[256];
int16_t ytbl[256];

// Y,U,V各要素の乗算済みテーブルを作る(RGB各5bitずつしか使わないので8で割っておく)
void yuv2rgbinit(void)
{
    for (int i = 0; i < 256; i++) {
        vrtbl[i] = 409 * (i - 128) / 8;
        vgtbl[i] = 208 * (i - 128) / 8;
        ugtbl[i] = 100 * (i - 128) / 8;
        ubtbl[i] = 516 * (i - 128) / 8;
        ytbl[i] = (298 * (i - 16) + 128) / 8;
    }
}

// YUY2データをRGB 2ピクセルに変換する
uint8_t *yuv2rgb(uint8_t *p, uint16_t *gv, int width)
{
    int16_t r, g, b;

    while (width > 0) {
        int16_t vr = vrtbl[p[2]];
        int16_t vg = vgtbl[p[2]];
        int16_t ug = ugtbl[p[0]];
        int16_t ub = ubtbl[p[0]];
        int16_t y0 = ytbl[p[1]];
        int16_t y1 = ytbl[p[3]];
        p += 4;
        width -= 2;

        // 5bit分のみを用いて 0x0000～0x1f00 の範囲にクリッピングする(下位8bitは0)
        #define clip(x) ((x < 0) ? 0 : ((x > 0x1f00) ? 0x1f00 : x)) & ~0xff;

        r = y0 + vr;
        r = clip(r)
        g = y0 - ug - vg;
        g = clip(g)
        b = y0 + ub;
        b = clip(b)
        // 0x0000～0x1f00の範囲にクリッピングされたR,G,Bの値を16bitにまとめる(1ピクセル目)
        *gv++ = (b >> (8 - 1)) | (r >> (8 - 6)) | (g << (11- 8));

        r = y1 + vr;
        r = clip(r)
        g = y1 - ug - vg;
        g = clip(g)
        b = y1 + ub;
        b = clip(b)
        // 0x0000～0x1f00の範囲にクリッピングされたR,G,Bの値を16bitにまとめる(2ピクセル目)
        *gv++ = (b >> (8 - 1)) | (r >> (8 - 6)) | (g << (11- 8));
    }
    return p;
}
