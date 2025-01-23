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
#include <scsi_cmd.h>

void msc_test(int epin, int epout, int epint, int sector, int count);

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

    if (zusb_open(0) < 0) {
        printf("ZUSB デバイスが見つかりません\n");
        exit(1);
    }

    if (devid < 0) {
        // devid の指定がなかったらMSCデバイス一覧を表示する
        printf("MSC devices\n");
        devid = 0;
        while ((devid = zusb_find_device_with_devclass(ZUSB_CLASS_MSC, -1, -1, devid))) {
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
    zusb_close();

    // MSCデバイスに接続する

    {
        zusb_open(0);
        zusb_endpoint_config_t epcfg[ZUSB_N_EP] = {
            { ZUSB_DIR_IN,  ZUSB_XFER_BULK, 0 },
            { ZUSB_DIR_OUT, ZUSB_XFER_BULK, 0 },
            { 0, 0, -1 },
        };
        if (zusb_connect_device(devid, 1, ZUSB_CLASS_MSC, 0x06, 0x50, epcfg) > 0) {
            // MSC, SCSI transparent command set, Bulk only transport
            msc_test(0, 1, -1, sector, count);
            zusb_disconnect_device();
            zusb_close();
            return 0;
        } else {
            zusb_close();
        }
    }
    {
        zusb_open(0);
        zusb_endpoint_config_t epcfg[ZUSB_N_EP] = {
            { ZUSB_DIR_IN,  ZUSB_XFER_BULK, 0 },
            { ZUSB_DIR_OUT, ZUSB_XFER_BULK, 0 },
            { ZUSB_DIR_IN,  ZUSB_XFER_INTERRUPT, 0 },
            { 0, 0, -1 },
        };
        if (zusb_connect_device(devid, 1, ZUSB_CLASS_MSC, 0x04, 0x00, epcfg) > 0) {
            // MSC, UFI command set, CBI transport
            msc_test(0, 1, 2, sector, count);
            zusb_disconnect_device();
            zusb_close();
            return 0;
        } else {
            zusb_close();
        }
    }

    printf("USB MSCに接続できません\n");
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

// 指定したエンドポイントを使ってMSCにSCSIコマンドを送る (Bulk only transport)
int msc_scsi_sendcmd_bbb(int epin, int epout, const void *cmd, int cmd_len, int dir, void *buf, int size)
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

    if (size > 0) {
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
    }

    zusb_msc_csw_t *csw = (zusb_msc_csw_t *)&zusbbuf[256];
    zusb_set_ep_region(epin, csw, sizeof(*csw));
    zusb_send_cmd(ZUSB_CMD_SUBMITXFER(epin));
    while (!(zusb->stat & (1 << epin))) {
    }
    zusb->stat = (1 << epin);

    return res;
}

// 指定したエンドポイントを使ってMSCにSCSIコマンドを送る (CBI transport)
int msc_scsi_sendcmd_cbi(int epin, int epout, int epint, const void *cmd, int cmd_len, int dir, void *buf, int size)
{
    int res = 0;

    memset(&zusbbuf[0], 0, 12);
    memcpy(&zusbbuf[0], cmd, cmd_len);
    if (zusb_send_control(ZUSB_REQ_CS_IF_OUT, 0, 0, 0x00, 12, &zusbbuf[0]) < 0) {
        return -1;
    }

    if (size > 0) {
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
    }

    zusb_set_ep_region(epint, &zusbbuf[0], 2);
    zusb_send_cmd(ZUSB_CMD_SUBMITXFER(epint));
    while (!(zusb->stat & (1 << epint))) {
    }
    zusb->stat = (1 << epint);

    return res;
}


int msc_scsi_sendcmd(int epin, int epout, int epint, const void *cmd, int cmd_len, int dir, void *buf, int size)
{
    if (epint < 0) {
        return msc_scsi_sendcmd_bbb(epin, epout, cmd, cmd_len, dir, buf, size);
    } else {
        return msc_scsi_sendcmd_cbi(epin, epout, epint, cmd, cmd_len, dir, buf, size);
    }
}

//////////////////////////////////////////////////////////////////////////////

void msc_test(int epin, int epout, int epint, int sector, int count)
{
    //////////////////////////////////////////////////
    // Test unit ready test

    scsi_test_unit_ready_t const cmd_test_unit_ready = {
        .cmd_code     = SCSI_CMD_TEST_UNIT_READY
    };

    msc_scsi_sendcmd(epin, epout, epint, &cmd_test_unit_ready, sizeof(cmd_test_unit_ready), ZUSB_DIR_IN, NULL, 0);

    //////////////////////////////////////////////////
    // Inquiry test

    scsi_inquiry_t const cmd_inquiry = {
        .cmd_code     = SCSI_CMD_INQUIRY,
        .alloc_length = sizeof(scsi_inquiry_resp_t)
    };
    scsi_inquiry_resp_t resp_inquiry;

    msc_scsi_sendcmd(epin, epout, epint, &cmd_inquiry, sizeof(cmd_inquiry), ZUSB_DIR_IN, &resp_inquiry, sizeof(resp_inquiry));

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
        .cmd_code     = SCSI_CMD_READ_CAPACITY_10,
    };
    scsi_read_capacity10_resp_t resp_read_capacity;

    msc_scsi_sendcmd(epin, epout, epint, &cmd_read_capacity, sizeof(cmd_read_capacity), ZUSB_DIR_IN, &resp_read_capacity, sizeof(resp_read_capacity));

    printf("last_lba = 0x%lx  block_size = %lu\n", resp_read_capacity.last_lba, resp_read_capacity.block_size);

    //////////////////////////////////////////////////
    // Read format capacities test (UFI only)

    if (epint >= 0) {
        uint32_t buf[256 / 4];
        scsi_read_format_capacities_t const cmd_read_format_capacities = {
            .cmd_code       = SCSI_CMD_READ_FORMAT_CAPACITIES,
            .alloc_length   = sizeof(buf)
        };
        scsi_read_format_capacities_resp_t *resp = (scsi_read_format_capacities_resp_t *)&buf;

        int r = msc_scsi_sendcmd(epin, epout, epint,
                         &cmd_read_format_capacities, sizeof(cmd_read_format_capacities),
                         ZUSB_DIR_IN,
                         buf, sizeof(buf));

        printf("capacity list length = %d\n", r);
        if (r > 0) {
            printf(" %s capacity: blocks = %lu  block_size = %u\n",
                   resp->descriptor_type == 2 ? "formatted" : "maximum",
                   resp->block_num, resp->block_size);
            printf(" formattable capacities:\n");
            for (int i = 1; i < r / 8; i++) {
                printf("  blocks = %lu  block_size = %lu\n", buf[1 + i * 2], buf[2 + i * 2]);
            }
        }
    }

    //////////////////////////////////////////////////
    // Read test

    scsi_read10_t cmd_read10 = {
        .cmd_code     = SCSI_CMD_READ_10,
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
        msc_scsi_sendcmd(epin, epout, epint, &cmd_read10, sizeof(cmd_read10), ZUSB_DIR_IN, block, block_size);

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
