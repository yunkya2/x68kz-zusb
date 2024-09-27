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
    int sector = -1;
    int count = -1;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-h") == 0) {
            printf("Usage: %s [-h] [devid] [sector] [count]\n", argv[0]);
            return 0;
        } else if (devid < 0) {
            devid = strtol(argv[i], NULL, 0);
        } else if (sector < 0) {
            sector = strtol(argv[i], NULL, 0);
        } else if (count < 0) {
            count = strtol(argv[i], NULL, 0);
        }
    }

    _iocs_b_super(0);

    if (zusb_open() < 0) {
        printf("ZUSB デバイスが見つかりません\n");
        exit(1);
    }

    if (devid < 0) {
        // devid の指定がなかったらMSCデバイス一覧を表示する
        printf("MSC devices\n");
        devid = 0;
        // MSC, SCSI transparent command set, Bulk only transport
        while ((devid = zusb_find_device_with_devclass(ZUSB_CLASS_MSC, 0x06, 0x50, devid))) {
            zusb->devid = devid;
            while (zusb_get_descriptor(zusbbuf) > 0) {
                char str[256];
                zusb_desc_device_t *ddev = (zusb_desc_device_t *)zusbbuf;
                if (ddev->bDescriptorType != ZUSB_DESC_DEVICE) {
                    break;
                }
                printf(" Device:%3d ", zusb->devid);
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

    // MSCデバイスに接続する

    zusb_endpoint_config_t epcfg[ZUSB_N_EP] = {
        { ZUSB_DIR_IN,  ZUSB_XFER_BULK, 0 },
        { ZUSB_DIR_OUT, ZUSB_XFER_BULK, 0 },
        { 0, 0, -1 },
    };

    if (zusb_connect_device(devid, 1, ZUSB_CLASS_MSC, 0x06, 0x50, epcfg) <= 0) {
        printf("USB MSCに接続できません\n");
        zusb_close();
        return 0;
    }

    void msc_test(int epin, int epout, int sector, int count);
    msc_test(0, 1, sector, count);

    zusb_disconnect_device();
    zusb_close();
    return 0;
}

//////////////////////////////////////////////////////////////////////////////

typedef struct __attribute__((packed)) zusb_msc_cbw  {
  ule32_t signature;
  ule32_t tag;
  ule32_t total_bytes;
  uint8_t dir;
  uint8_t lun;
  uint8_t cmd_len;
  uint8_t command[16];
} zusb_msc_cbw_t;

typedef struct __attribute__((packed)) zusb_msc_csw {
  ule32_t signature;
  ule32_t tag;
  ule32_t data_residue;
  uint8_t  status;
} zusb_msc_csw_t;

#define ZUSB_MSC_CBW_SIGNATURE      0x43425355      // 'CBSU'

// 指定したエンドポイントを使ってMSCにSCSIコマンドを送る
int msc_scsi_sendcmd(int epin, int epout, const void *cmd, int cmd_len, int dir, void *buf, int size)
{
    int res = 0;
    zusb_msc_cbw_t *cbw = (zusb_msc_cbw_t *)&zusbbuf[0];
    cbw->signature = zusb_htole32(ZUSB_MSC_CBW_SIGNATURE);
    cbw->tag = zusb_htole32(0x12345678);
    cbw->total_bytes = zusb_htole32(size);
    cbw->dir = dir;
    cbw->lun = 0;
    cbw->cmd_len = cmd_len;
    memcpy(cbw->command, cmd, cmd_len);

    zusb_set_ep_region(epout, cbw, sizeof(*cbw));
    zusb_send_cmd(ZUSB_CMD_SUBMITXFER(epout));
    while (!(zusb->stat & (1 << epout))) {
    }
    zusb->stat = (1 << epout);

    if (dir & 0x80) {
        // device to host
        zusb_set_ep_region(epin, &zusbbuf[0x100], size);
        zusb_send_cmd(ZUSB_CMD_SUBMITXFER(epin));
        while (!(zusb->stat & (1 << epin))) {
        }
        zusb->stat = (1 << epin);
        res = zusb->pcount[epin];
        memcpy(buf, &zusbbuf[0x100], res);
    } else {
        // host to device
        memcpy(&zusbbuf[0x100], buf, size);
        zusb_set_ep_region(epout, &zusbbuf[0x100], size);
        zusb_send_cmd(ZUSB_CMD_SUBMITXFER(epout));
        while (!(zusb->stat & (1 << epout))) {
        }
        zusb->stat = (1 << epout);
        res = zusb->pcount[epout];
    }

    zusb_msc_csw_t *csw = (zusb_msc_csw_t *)&zusbbuf[256];
    zusb_set_ep_region(epin, csw, sizeof(*csw));
    zusb_send_cmd(ZUSB_CMD_SUBMITXFER(epin));
    while (!(zusb->stat & (1 << epin))) {
    }
    zusb->stat = (1 << epin);

    return res;
}

//////////////////////////////////////////////////////////////////////////////

typedef struct __attribute__((packed)) scsi_inquiry {
  uint8_t cmd_code;     // 0x12
  uint8_t reserved1;
  uint8_t page_code;
  uint8_t reserved2;
  uint8_t alloc_length;
  uint8_t control;
} scsi_inquiry_t;

typedef struct __attribute__((packed)) scsi_inquiry_resp {
  uint8_t peripheral_qual_type;
  uint8_t is_removable;
  uint8_t version;
  uint8_t response_data_format;
  uint8_t additional_length;
  uint8_t flag_5;
  uint8_t flag_6;
  uint8_t flag_7;
  uint8_t vendor_id[8];
  uint8_t product_id[16];
  uint8_t product_rev[4];
} scsi_inquiry_resp_t;

typedef struct __attribute__((packed)) scsi_read_capacity10 {
  uint8_t  cmd_code;    // 0x25
  uint8_t  reserved1;
  uint32_t lba;
  uint16_t reserved2;
  uint8_t  partial_medium_indicator;
  uint8_t  control;
} scsi_read_capacity10_t;

typedef struct __attribute__((packed)) scsi_read_capacity10_resp {
  uint32_t last_lba;
  uint32_t block_size;
} scsi_read_capacity10_resp_t;

typedef struct __attribute__((packed)) scsi_read10 {
  uint8_t  cmd_code;    // 0x28
  uint8_t  reserved;
  uint32_t lba;
  uint8_t  reserved2;
  uint16_t block_count;
  uint8_t  control;
} scsi_read10_t;

void msc_test(int epin, int epout, int sector, int count)
{
    //////////////////////////////////////////////////
    // Inquiry test

    scsi_inquiry_t const cmd_inquiry = {
        .cmd_code     = 0x12,
        .alloc_length = sizeof(scsi_inquiry_resp_t)
    };
    scsi_inquiry_resp_t resp_inquiry;

    msc_scsi_sendcmd(epin, epout, &cmd_inquiry, sizeof(cmd_inquiry), ZUSB_DIR_IN, &resp_inquiry, sizeof(resp_inquiry));

    printf("Vendor ID: ");
    for (int i = 0; i < 8; i++) {
        printf("%c", resp_inquiry.vendor_id[i]);
    }
    printf("Product ID: ");
    for (int i = 0; i < 16; i++) {
        printf("%c", resp_inquiry.product_id[i]);
    }
    printf("Product Rev: ");
    for (int i = 0; i < 4; i++) {
        printf("%c", resp_inquiry.product_rev[i]);
    }
    printf("\n");

    //////////////////////////////////////////////////
    // Read capacity test

    scsi_read_capacity10_t const cmd_read_capacity = {
        .cmd_code     = 0x25,
    };
    scsi_read_capacity10_resp_t resp_read_capacity;

    msc_scsi_sendcmd(epin, epout, &cmd_read_capacity, sizeof(cmd_read_capacity), ZUSB_DIR_IN, &resp_read_capacity, sizeof(resp_read_capacity));

    printf("last_lba = 0x%lx  block_size = %lu\n", resp_read_capacity.last_lba, resp_read_capacity.block_size);

    //////////////////////////////////////////////////
    // Read test

    scsi_read10_t cmd_read10 = {
        .cmd_code     = 0x28,
        .lba          = 0,
        .block_count  = 1
    };

    int block_size = resp_read_capacity.block_size;

    if (sector < 0) {
        return;
    }
    if (count < 0) {
        count = 1;
    }

    uint8_t *block = malloc(block_size);
    if (block == NULL) {
        printf("メモリ確保エラー\n");
        return;
    }


    while (count-- > 0) {
        if (sector > resp_read_capacity.last_lba) {
            break;
        }

        cmd_read10.lba = sector++;
        msc_scsi_sendcmd(epin, epout, &cmd_read10, sizeof(cmd_read10), ZUSB_DIR_IN, block, block_size);
        printf("\nLBA=0x%08lx\n", cmd_read10.lba);
        int i;
        char ascii[17];
        ascii[16] = '\0';
        for (i = 0; i < block_size; i++) {
            if (i % 16 == 0) {
                printf("0x%03x: ", i);
            }
            printf("%02x ", block[i]);
            ascii[i % 16] = (block[i] >= 0x20 && block[i] < 0x7f) ? block[i] : '.';
            if (i % 16 == 15) {
                printf("  %s\n", ascii);
            }
        }
        printf("\n");
    }

    free(block);
}
