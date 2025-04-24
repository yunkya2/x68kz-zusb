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
#include <ctype.h>
#include <errno.h>

#include <x68k/iocs.h>
#include <x68k/dos.h>

#include <zusb.h>

int16_t ch_devid[ZUSB_N_CH];

void disp_hid_descriptors(int devid, int subclass, int type, uint8_t *desc, void *arg);
void disp_uac_descriptors(int devid, int subclass, int type, uint8_t *desc, void *arg);
void disp_uvc_descriptors(int devid, int subclass, int type, uint8_t *desc, void *arg);

struct disp_descriptors_arg {
    int verbose;
    int devid;
    int current_config;
    int current_iface;
};

int disp_descriptors(int devid, int type, uint8_t *desc, void *arg)
{
    struct disp_descriptors_arg *a = (struct disp_descriptors_arg *)arg;
    char str[256];
    static int devclass = -1;
    static int subclass = -1;

    if (a->devid >= 0 && devid != a->devid) {
        return 0;
    }
    if (type == ZUSB_DESC_DEVICE) {
        int ch;
        printf("Device:%3d", devid);
        for (ch = 0; ch < ZUSB_N_CH; ch++) {
            if (ch_devid[ch] == devid) {
                break;
            }
        }
        if (ch >= ZUSB_N_CH) {
            printf("\n");
        } else {
            printf(" (ch.%d)\n", ch);
        }
    }

    if (a->verbose) {
        for (int i = 0; i < desc[0]; i++) {
            printf("%02x ", desc[i]);
        }
        printf("\n");
    }

    switch (desc[1]) {
    case ZUSB_DESC_DEVICE:
        zusb_desc_device_t *ddev = (zusb_desc_device_t *)desc;

        printf(" Device:");
        printf(" USB:%x", zusb_le16toh(ddev->bcdUSB));
        printf(" class:%d", ddev->bDeviceClass);
        printf(" subclass:%d", ddev->bDeviceSubClass);
        printf(" protocol:%d", ddev->bDeviceProtocol);
        printf(" maxpacket:%d", ddev->bMaxPacketSize0);
        printf(" VID:0x%04x", zusb_le16toh(ddev->idVendor));
        printf(" PID:0x%04x", zusb_le16toh(ddev->idProduct));
        printf(" ver:%x", zusb_le16toh(ddev->bcdDevice));
        printf("\n");
        if (ddev->iManufacturer &&
            zusb_get_string_descriptor(str, sizeof(str), ddev->iManufacturer) > 0) {
            printf("\tManufacturer: %s\n", str);
        }
        if (ddev->iProduct &&
            zusb_get_string_descriptor(str, sizeof(str), ddev->iProduct) > 0) {
            printf("\tProduct:      %s\n", str);
        }
        if (ddev->iSerialNumber &&
            zusb_get_string_descriptor(str, sizeof(str), ddev->iSerialNumber) > 0) {
            printf("\tSerial:       %s\n", str);
        }
        break;

    case ZUSB_DESC_CONFIGURATION:
        zusb_desc_configuration_t *dconf = (zusb_desc_configuration_t *)desc;

        printf("  Configuration:");
        printf(" #%d", dconf->bConfigurationValue);
        a->current_config = dconf->bConfigurationValue;
        if (dconf->iConfiguration &&
            zusb_get_string_descriptor(str, sizeof(str), dconf->iConfiguration) > 0) {
            printf(" name:%s", str);
        }
        printf(" MaxPower:%dmA", dconf->bMaxPower * 2);
        printf("\n");
        break;

    case ZUSB_DESC_INTERFACE:
        zusb_desc_interface_t *dintf = (zusb_desc_interface_t *)desc;

        printf("   Interface:\t");
        printf(" #%d", dintf->bInterfaceNumber);
        if (dintf->bAlternateSetting) {
            printf("/%d", dintf->bAlternateSetting);
        }
        a->current_iface = dintf->bInterfaceNumber;
        printf(" class:%d", dintf->bInterfaceClass);
        printf(" subclass:%d", dintf->bInterfaceSubClass);
        printf(" protocol:%d", dintf->bInterfaceProtocol);
        if (dintf->iInterface &&
            zusb_get_string_descriptor(str, sizeof(str), dintf->iInterface) > 0) {
            printf(" name:%s", str);
        }
        printf("\n");
        devclass = dintf->bInterfaceClass;
        subclass = dintf->bInterfaceSubClass;
        break;

    case ZUSB_DESC_ENDPOINT:
        zusb_desc_endpoint_t *dendp = (zusb_desc_endpoint_t *)desc;

        printf("    Endpoint:\t");
        printf(" 0x%02x", dendp->bEndpointAddress);
        switch (dendp->bmAttributes & 3) {
        case 0:
            printf(" Control");
            break;
        case 1:
            printf(" Isochronous");
            break;
        case 2:
            printf(" Bulk");
            break;
        case 3:
            printf(" Interrupt");
            break;
        }
        uint16_t maxpacket = zusb_le16toh(dendp->wMaxPacketSize);
        uint16_t packetmul = ((maxpacket >> 11) & 3) + 1;
        maxpacket &= 0x7ff;
        printf(" MaxPacket:%d", maxpacket);
        if (packetmul > 1) {
            printf("*%d=%d", packetmul, maxpacket * packetmul);
        }
        printf("\n");
        break;

    case ZUSB_DESC_CS_DEVICE:
    case ZUSB_DESC_CS_INTERFACE:
    case ZUSB_DESC_CS_ENDPOINT:
        switch (devclass) {
        case ZUSB_CLASS_HID:
            disp_hid_descriptors(devid, subclass, type, desc, arg);
            break;
        case ZUSB_CLASS_AUDIO:
            disp_uac_descriptors(devid, subclass, type, desc, arg);
            break;
        case ZUSB_CLASS_VIDEO:
            disp_uvc_descriptors(devid, subclass, type, desc, arg);
            break;
        default:
            break;
        }
        break;
    }

    return 0;
}

int disp_device_descriptor(int devid, int type, uint8_t *desc, void *arg)
{
    struct disp_descriptors_arg *a = (struct disp_descriptors_arg *)arg;
    zusb_desc_device_t *ddev = (zusb_desc_device_t *)desc;
    char str[256];
    int ch;

    if (a->devid >= 0 && devid != a->devid) {
        return 0;
    }
    if (type != ZUSB_DESC_DEVICE || ddev->bLength != sizeof(zusb_desc_device_t)) {
        return 0;
    }
 
    if (a->verbose) {
        for (int i = 0; i < desc[0]; i++) {
            printf("%02x ", desc[i]);
        }
        printf("\n");
    }

    for (ch = 0; ch < ZUSB_N_CH; ch++) {
        if (ch_devid[ch] == devid) {
            break;
        }
    }
    if (ch >= ZUSB_N_CH) {
        printf("  ");
    } else {
        printf("#%d", ch);
    }

    printf(" Device:%3d ", devid);
    printf("0x%04x-0x%04x", zusb_le16toh(ddev->idVendor), zusb_le16toh(ddev->idProduct));
    if (ddev->iProduct &&
        zusb_get_string_descriptor(str, sizeof(str), ddev->iProduct) > 0) {
        printf(" %-30s", str);
    }
    if (ddev->iManufacturer &&
        zusb_get_string_descriptor(str, sizeof(str), ddev->iManufacturer) > 0) {
        printf(" (%s)", str);
    }
    printf("\n");
    return 0;
}

//////////////////////////////////////////////////////////////////////////////

typedef struct __attribute__((packed)) hid_desc {
  uint8_t bLength;
  uint8_t bDescriptorType;
  uint_le16_t bcdHID;
  uint8_t bCountryCode;
  uint8_t bNumDescriptors;
  uint8_t bData[];
} hid_desc_t;

static struct {
    int config;
    int interface;
    int type;
    int size;
} hid_reports[8];
int n_hid_reports = 0;

void disp_hid_descriptors(int devid, int subclass, int type, uint8_t *desc, void *arg)
{
    struct disp_descriptors_arg *a = (struct disp_descriptors_arg *)arg;
    switch (desc[1]) {
    case ZUSB_DESC_CS_DEVICE:
        hid_desc_t *hd = (hid_desc_t *)desc;
        printf("    HID:\t");
        printf(" version:%x", zusb_le16toh(hd->bcdHID));
        printf(" country:%d", hd->bCountryCode);
        for (int i = 0; i < hd->bNumDescriptors; i++) {
            printf(" (type:0x%02x", hd->bData[i * 3]);
            printf(" size:%d)", hd->bData[i * 3 + 1] | (hd->bData[i * 3 + 2] << 8));
            if (n_hid_reports < sizeof(hid_reports) / sizeof(hid_reports[0])) {
                hid_reports[n_hid_reports].config = a->current_config;
                hid_reports[n_hid_reports].interface = a->current_iface;
                hid_reports[n_hid_reports].type = hd->bData[i * 3];
                hid_reports[n_hid_reports].size = hd->bData[i * 3 + 1] | (hd->bData[i * 3 + 2] << 8);
                n_hid_reports++;
            }
        }
        printf("\n");
        break;
    }
}

static char rptbuf[3][256];
static int rptsize[3];
static int rptremain[3];
static char *rptptr[3];
static void report_string_reset(void)
{
    for (int i = 0; i < 3; i++) {
        rptptr[i] = rptbuf[i];
        *rptptr[i] = '\0';
        rptsize[i] = 0;
        rptremain[i] = sizeof(rptbuf[i]) - 1;
    }
}
static int report_string_disp(int id, int verbose)
{
    int i;
    for (i = 0; i < 3; i++) {
        if (rptsize[i] > 0)
           break;
    }
    if (i >= 3)
        return false;

    if (verbose) printf("\n");
    for (i = 0; i < 3; i++) {
        *rptptr[i] = '\0';
        if (rptsize[i] > 0) {
            if (id > 0) {
                printf("    (%2d bytes) [%02x]%s\n", 1 + (rptsize[i] / 8), id, rptbuf[i]);
            } else {
                printf("    (%2d bytes) %s\n", rptsize[i] / 8 , rptbuf[i]);
            }
        }
    }
    if (verbose) printf("\n");
    report_string_reset();
    return true;
}

struct report_verbose_string { int key; char *value; };

static char *report_find_verbose_string(int value, struct report_verbose_string *tbl)
{
    while (tbl->key > 0) {
        if (tbl->key == value) {
            return tbl->value;
        }
        tbl++;
    }
    return NULL;
}

//  HID Usage Tables Version 1.6
//  (https://usb.org/sites/default/files/hut1_6.pdf)

static struct report_verbose_string report_usage_page[] = {
    { 0x01, "Generic Desktop" },
    { 0x02, "Simulation Controls" },
    { 0x03, "VR Controls" },
    { 0x04, "Sport Controls" },
    { 0x05, "Game Controls" },
    { 0x06, "Generic Device Controls" },
    { 0x07, "Keyboard/Keypad" },
    { 0x08, "LED" },
    { 0x09, "Button" },
    { 0x0a, "Ordinal" },
    { 0x0b, "Telephoyny Device" },
    { 0x0c, "Consumer" },
    { 0x0d, "Digitizer" },
    { 0x0e, "Haptics" },
    { 0x0f, "Physical Input Device" },
    { 0x10, "Unicode" },
    { 0x11, "SoC" },
    { 0x12, "Eye and Head Trackers" },
    { 0x14, "Auxiliary Display" },
    { 0x20, "Sensors" },
    { 0x40, "Medical Instrument" },
    { 0x41, "Braille Display" },
    { 0x59, "Lightning and Illumination" },
    { 0x80, "Monitor" },
    { 0x81, "Monitor Enumerated" },
    { 0x82, "VESA Virtual Controls" },
    { 0x84, "Power" },
    { 0x85, "Battery System" },
    { 0x8c, "Barode Scanner" },
    { 0x8d, "Scales" },
    { 0x8e, "Magnetic Stripe Reader" },
    { 0x90, "Camera" },
    { 0x92, "Gaming Device" },
    { 0xf1d0, "FIDO Alliance" },
    { -1, NULL },
};
static struct report_verbose_string report_usage_0x01[] = {
    { 0x01, "Pointer" },
    { 0x02, "Mouse" },
    { 0x04, "Joystick" },
    { 0x05, "Gamepad" },
    { 0x06, "Keyboard" },
    { 0x07, "Keypad" },
    { 0x30, "X" },
    { 0x31, "Y" },
    { 0x32, "Z" },
    { 0x33, "Rx" },
    { 0x34, "Ry" },
    { 0x35, "Rz" },
    { 0x36, "Slider" },
    { 0x37, "Dial" },
    { 0x38, "Wheel" },
    { 0x39, "Hat Switch" },
    { 0x3d, "Start" },
    { 0x3e, "Select" },
    { 0x90, "D-pad Up" },
    { 0x91, "D-pad Down" },
    { 0x92, "D-pad Right" },
    { 0x93, "D-pad Left" },
    { -1, NULL },
};

void disp_hid_report_detail(uint8_t *buf, int len, int verbose)
{
    int rsize = 0;
    int rcount = 0;
    int nest = 0;
    int id = -1;
    int upage = 0;
    int ch;

    report_string_reset();
    while (len > 0) {
        bool flash = false;
        ch = *buf++;
        len--;
        int tag = (ch >> 4) & 0xf;
        int type = (ch >> 2) & 0x3;
        int size = (ch >> 0) & 0x3;
        uint32_t value;
        int32_t svalue;

        switch (size) {
            case 0:
                value = 0;
                svalue = 0;
                break;
            case 1:
                value = buf[0];
                svalue = (int8_t)value;
                break;
            case 2:
                value = buf[0] | (buf[1] << 8);
                svalue = (int16_t)value;
                break;
            case 3:
                value = buf[0] | (buf[1] << 8) | (buf[2] << 16) | (buf[3] << 24);
                svalue = (int32_t)value;
                buf++;
                len--;
                break;
        }
        buf += size;
        len -= size;

        if (type == 0 && tag == 0x0c) {     // End Collection
            nest--;
        }
        if (type == 1 && tag == 0x08) {     // Report ID
            report_string_disp(id, verbose);
        }
        if (verbose) {
            printf("0x%02x (tag=%d type=%d size=%d) value=0x%x\t", ch, tag, type, size, value);
            for (int i = 0; i < nest; i++) {
                printf("  ");
            }
        }

        char ty;
        int sel;
        switch (type) {
        case 0:     // Main
            ty = ' ';
            sel = -1;
            switch (tag) {
            case 0x0a:      // Collection
                if (verbose) {
                    printf("Collection (");
                    switch (value) {
                    case 0: printf("Physical"); break;
                    case 1: printf("Application"); break;
                    case 2: printf("Logical"); break;
                    }
                    printf(")");
                }
                nest++;
                break;
            case 0x0c:     // End Collection
                if (verbose) printf("End Collection");
                flash = (nest == 0);
                break;
            case 0x08:     //Input
            case 0x09:     //Output
            case 0x0b:     //Feature
                switch (tag) {
                case 8:     //Input
                    if (verbose) printf("Input");
                    ty = 'i';
                    sel = 0;
                    break;
                case 9:     //Output
                    if (verbose) printf("Output");
                    ty = 'o';
                    sel = 1;
                    break;
                case 0x0b:  //Feature
                    if (verbose) printf("Feature");
                    ty = 'f';
                    sel = 2;
                    break;
                }
                if (value & 1) {
                    ty = '-';
                }
                if (verbose) {
                    printf(" (%s,", (value & 1) ? "Const" : "Data");
                    printf("%s,", (value & 2) ? "Variable" : "Array");
                    printf("%s)", (value & 4) ? "Relative" : "Absolute");
                }

                if ((rsize % 8) == 0) {
                    for (int i = 0; i < rcount; i++) {
                        if (rptremain[sel] < 1)
                            break;
                        *rptptr[sel]++ = ':';
                        rptremain[sel]--;
                        for (int j = 0; j < rsize; j += 8) {
                            if (rptremain[sel] < 2)
                                break;
                            *rptptr[sel]++ = toupper(ty);
                            *rptptr[sel]++ = toupper(ty);
                            rptsize[sel] += 8;
                            rptremain[sel] -= 2;
                        }
                        if (rcount > 16) {
                            char buf[20];
                            snprintf(buf, sizeof(buf), " x %u", rcount);
                            int buflen = strlen(buf);
                            if (rptremain[sel] < buflen)
                                break;
                            memcpy(rptptr[sel], buf, buflen);
                            rptptr[sel] += buflen;
                            rptsize[sel] += rsize * (rcount - 1);
                            rptremain[sel] -= buflen;
                            break;
                        }
                    }
                } else {
                    for (int i = 0; i < rsize * rcount; i++) {
                        if ((rptsize[sel] % 8) == 0) {
                            if (rptremain[sel] < 9)
                                break;
                            strcpy(rptptr[sel], ":        ");
                            rptptr[sel] += 9;
                            rptremain[sel] -= 9;
                        }
                        rptptr[sel][-1 - (rptsize[sel] % 8)] = ty;
                        rptsize[sel]++;
                    }
                }
                break;
            }
            break;

        case 1:     // Global
            switch (tag) {
            case 0:
                upage = value;
                if (verbose) { 
                    printf("Usage Page ");
                    char *s = report_find_verbose_string(value, report_usage_page);
                    if (s) printf("(%s)", s); else printf("(0x%x)", value);
                }
                break;
            case 1:
                if (verbose) printf("Logical Min (%d)", svalue);
                break;
            case 2:
                if (verbose) printf("Logical Max (%d)", svalue);
                break;
            case 3:
                if (verbose) printf("Physical Min (%d)", svalue);
                break;
            case 4:
                if (verbose) printf("Physical Max (%d)", svalue);
                break;
            case 5:
                if (verbose) printf("Unit Exponent (%d)", (value & 7) - ((value & 8) ? 8 : 0));
                break;
            case 6:
                if (verbose) printf("Unit (0x%x)", value);
                break;
            case 7:
                if (verbose) printf("Report Size (%u)", value);
                rsize = value;
                break;
            case 8:
                if (verbose) printf("Report ID (%u)", value);
                id = value;
                break;
            case 9:
                if (verbose) printf("Report Count (%u)", value);
                rcount = value;
                break;
            }
            break;

        case 2:     // Local
            switch (tag) {
                case 0:
                    if (verbose) {
                        printf("Usage ");
                        char *s = NULL;
                        switch (upage) {
                        case 0x01: // Generic Desktop
                            s = report_find_verbose_string(value, report_usage_0x01);
                            break;
                        }
                        if (s) printf("(%s)", s); else printf("(0x%x)", value);
                    }
                    break;
                case 1:
                    if (verbose) printf("Usage Min (%u)", value);
                    break;
                case 2:
                    if (verbose) printf("Usage Max (%u)", value);
                    break;
                }
            break;
        }

        if (verbose) printf("\n");
        if (flash) {
            report_string_disp(id, verbose);
        }
    }
}

void disp_hid_report(int devid, int verbose, int hid_detail)
{
    if (n_hid_reports == 0) {
        return;
    }

    printf("\nHID Report\n");
    for (int i = 0; i < n_hid_reports; i++) {
        printf("  Configuration:%d Interface:%d type:0x%02x size:%d\n",
               hid_reports[i].config, hid_reports[i].interface,
               hid_reports[i].type, hid_reports[i].size);

        zusb->devid = devid;
        zusb->param = (hid_reports[i].config << 8) | hid_reports[i].interface;
        if (zusb_send_cmd(ZUSB_CMD_CONNECT) < 0) {
            break;
        }

        zusb_send_control(ZUSB_REQ_DIR_IN|ZUSB_REQ_RCPT_INTERFACE, ZUSB_REQ_GET_DESCRIPTOR,
                          hid_reports[i].type << 8, hid_reports[i].interface,
                          hid_reports[i].size, zusbbuf);

        if (verbose) {
            for (int j = 0; j < zusb->ccount; j++) {
                printf("%02x ", zusbbuf[j]);
                if (j % 16 == 15) {
                    printf("\n");
                }
            }
            if (zusb->ccount % 16) {
                printf("\n");
            }
        }

        switch (hid_reports[i].type) {
        case 0x22:
            disp_hid_report_detail(zusbbuf, zusb->ccount, hid_detail);
            break;
        }

        zusb_send_cmd(ZUSB_CMD_DISCONNECT);
    }
}

//////////////////////////////////////////////////////////////////////////////

typedef struct __attribute__((packed)) uac_desc_ac_header {
  uint8_t bLength;
  uint8_t bDescriptorType;
  uint8_t bDescriptorSubtype;
  uint_le16_t bcdADC;
  uint_le16_t wTotalLength;
  uint8_t bInCollection;
  uint8_t baInterfaceNr[];
} uac_desc_ac_header_t;

typedef struct __attribute__((packed)) uac_desc_ac_input_terminal {
  uint8_t bLength;
  uint8_t bDescriptorType;
  uint8_t bDescriptorSubtype;
  uint8_t bTerminalID;
  uint_le16_t wTerminalType;
  uint8_t bAssocTerminal;
  uint8_t bNrChannels;
  uint_le16_t wChannelConfig;
  uint8_t iChannelNames;
  uint8_t iTerminal;
} uac_desc_ac_input_terminal_t;

typedef struct __attribute__((packed)) uac_desc_ac_output_terminal {
  uint8_t bLength;
  uint8_t bDescriptorType;
  uint8_t bDescriptorSubtype;
  uint8_t bTerminalID;
  uint_le16_t wTerminalType;
  uint8_t bAssocTerminal;
  uint8_t bSourceID;
  uint8_t iTerminal;
} uac_desc_ac_output_terminal_t;    

typedef struct __attribute__((packed)) uac_desc_ac_mixer_unit {
  uint8_t bLength;
  uint8_t bDescriptorType;
  uint8_t bDescriptorSubtype;
  uint8_t bUnitID;
  uint8_t bNrInPins;
  uint8_t baSourceID[];
} uac_desc_ac_mixer_unit_t;

typedef struct __attribute__((packed)) uac_desc_ac_selector_unit {
  uint8_t bLength;
  uint8_t bDescriptorType;
  uint8_t bDescriptorSubtype;
  uint8_t bUnitID;
  uint8_t bNrInPins;
  uint8_t baSourceID[];
} uac_desc_ac_selector_unit_t;

typedef struct __attribute__((packed)) uac_desc_ac_feature_unit {
  uint8_t bLength;
  uint8_t bDescriptorType;
  uint8_t bDescriptorSubtype;
  uint8_t bUnitID;
  uint8_t bSourceID;
  uint8_t bControlSize;
  uint8_t bmaControls[];
} uac_desc_ac_feature_unit_t;

typedef struct __attribute__((packed)) uac_desc_as_interface {
  uint8_t bLength;
  uint8_t bDescriptorType;
  uint8_t bDescriptorSubtype;
  uint8_t bTerminalLink;
  uint8_t bDelay;
  uint_le16_t wFormatTag;
} uac_desc_as_interface_t;

typedef struct __attribute__((packed)) uac_desc_as_format_type_i {
  uint8_t bLength;
  uint8_t bDescriptorType;
  uint8_t bDescriptorSubtype;
  uint8_t bFormatType;
  uint8_t bNrChannels;
  uint8_t bSubframeSize;
  uint8_t bBitResolution;
  uint8_t bSamFreqType;
  uint8_t tSamFreq[];
} uac_desc_as_format_type_i_t;

void disp_uac_descriptors(int devid, int subclass, int type, uint8_t *desc, void *arg)
{
    char str[256];

    switch (desc[1]) {
    case ZUSB_DESC_CS_INTERFACE:
        int p;
        switch (subclass) {
        case 1:     // Audio Control
            printf("    AC_INTERFACE: ");
            switch (desc[2]) {
            case 0x01:
                uac_desc_ac_header_t *dach = (uac_desc_ac_header_t *)desc;
                printf("HEADER:");
                printf(" rev:%x", zusb_le16toh(dach->bcdADC));
                printf(" len:%d", zusb_le16toh(dach->wTotalLength));
                printf(" if:");
                for (int i = 0; i < dach->bInCollection; i++) {
                    printf(" %d", dach->baInterfaceNr[i]);
                }
                break;
            case 0x02:
                uac_desc_ac_input_terminal_t *dit = (uac_desc_ac_input_terminal_t *)desc;
                printf("INPUT_TERMINAL:");
                printf(" id:%d", dit->bTerminalID);
                printf(" type:0x%03x", zusb_le16toh(dit->wTerminalType));
                printf(" assoc:%d", dit->bAssocTerminal);
                printf(" ch:%d", dit->bNrChannels);
                printf(" config:0x%04x", zusb_le16toh(dit->wChannelConfig));
                if (dit->iChannelNames &&
                    zusb_get_string_descriptor(str, sizeof(str), dit->iChannelNames) > 0) {
                    printf(" chname:%s", str);
                }
                if (dit->iTerminal &&
                    zusb_get_string_descriptor(str, sizeof(str), dit->iTerminal) > 0) {
                    printf(" name:%s", str);
                }
                break;
            case 0x03:
                uac_desc_ac_output_terminal_t *dot = (uac_desc_ac_output_terminal_t *)desc;
                printf("OUTPUT_TERMINAL:");
                printf(" id:%d", dot->bTerminalID);
                printf(" type:0x%03x", zusb_le16toh(dot->wTerminalType));
                printf(" assoc:%d", dot->bAssocTerminal);
                printf(" src:%d", dot->bSourceID);
                if (dot->iTerminal &&
                    zusb_get_string_descriptor(str, sizeof(str), dot->iTerminal) > 0) {
                    printf(" name:%s", str);
                }
                break;
            case 0x04:
                uac_desc_ac_mixer_unit_t *dmix = (uac_desc_ac_mixer_unit_t *)desc;
                printf("MIXER_UNIT:");
                printf(" id:%d", dmix->bUnitID);
                printf(" source");
                p = dmix->bNrInPins;
                for (int i = 0; i < p; i++) {
                    printf("%c%d", i == 0 ? ':' : ',', dmix->baSourceID[i]);
                }
                printf(" ch:%d", dmix->baSourceID[p]);
                printf(" config:0x%04x", dmix->baSourceID[p + 1] + (dmix->baSourceID[p + 2] << 8));
                if (dmix->baSourceID[p + 3] &&
                    zusb_get_string_descriptor(str, sizeof(str), dmix->baSourceID[p + 3]) > 0) {
                    printf(" name:%s", str);
                }
                break;
            case 0x05:
                uac_desc_ac_selector_unit_t *dsel = (uac_desc_ac_selector_unit_t *)desc;
                printf("SELECTOR_UNIT:");
                printf(" id:%d", dsel->bUnitID);
                printf(" source");
                p = dsel->bNrInPins;
                for (int i = 0; i < p; i++) {
                    printf("%c%d", i == 0 ? ':' : ',', dsel->baSourceID[i]);
                }
                if (dsel->baSourceID[p] && 
                    zusb_get_string_descriptor(str, sizeof(str), dsel->baSourceID[p]) > 0) {
                    printf(" name:%s", str);
                }
                break;
            case 0x06:
                uac_desc_ac_feature_unit_t *dfea = (uac_desc_ac_feature_unit_t *)desc;
                printf("FEATURE_UNIT:");
                printf(" id:%d", dfea->bUnitID);
                printf(" src:%d", dfea->bSourceID);
                printf(" size:%d", dfea->bControlSize);
                break;
            case 0x07:
                printf("PROCESSING_UNIT:");
                break;
            case 0x08:
                printf("EXTENSION_UNIT:");
                break;
            }
            printf("\n");
            break;
        case 2:     // Audio Streaming
            printf("    AS_INTERFACE: ");
            switch (desc[2]) {
            case 0x01:
                uac_desc_as_interface_t *dasi = (uac_desc_as_interface_t *)desc;
                printf("AS_GENERAL:");
                printf(" link:%d", dasi->bTerminalLink);
                printf(" delay:%d", dasi->bDelay);
                printf(" tag:0x%04x", zusb_le16toh(dasi->wFormatTag));
                break;
            case 0x02:
                uac_desc_as_format_type_i_t *dasfi = (uac_desc_as_format_type_i_t *)desc;
                printf("FORMAT_TYPE:");
                printf(" type:%d", dasfi->bFormatType);
                printf(" ch:%d", dasfi->bNrChannels);
                printf(" size:%d", dasfi->bSubframeSize);
                printf(" bit:%d", dasfi->bBitResolution);
                printf(" freq");
                if (dasfi->bSamFreqType == 0) {
                    printf(":%d-%d",
                           dasfi->tSamFreq[0] + (dasfi->tSamFreq[1] << 8) + (dasfi->tSamFreq[2] << 16),
                           dasfi->tSamFreq[3] + (dasfi->tSamFreq[4] << 8) + (dasfi->tSamFreq[5] << 16));
                } else {
                    for (int i = 0; i < dasfi->bSamFreqType; i++) {
                        printf("%c%d", i == 0 ? ':' : ',',
                               dasfi->tSamFreq[i * 3] + (dasfi->tSamFreq[i * 3 + 1] << 8) + (dasfi->tSamFreq[i * 3 + 2] << 16));
                    }
                }
                break;
            case 0x03:
                printf("FORMAT_SPECIFIC:");
                break;
            }
            printf("\n");
            break;
        }
        break;
    }
}

//////////////////////////////////////////////////////////////////////////////

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

typedef struct __attribute__((packed)) uvc_desc_vc_input_terminal {
  uint8_t bLength;
  uint8_t bDescriptorType;
  uint8_t bDescriptorSubtype;
  uint8_t bTerminalID;
  uint_le16_t wTerminalType;
  uint8_t bAssocTerminal;
  uint8_t iTerminal;
} uvc_desc_vc_input_terminal_t;

typedef struct __attribute__((packed)) uvc_desc_vc_output_terminal {
  uint8_t bLength;
  uint8_t bDescriptorType;
  uint8_t bDescriptorSubtype;
  uint8_t bTerminalID;
  uint_le16_t wTerminalType;
  uint8_t bAssocTerminal;
  uint8_t bSourceID;
  uint8_t iTerminal;
} uvc_desc_vc_output_terminal_t;

typedef struct __attribute__((packed)) uvc_desc_vc_selector_unit {
  uint8_t bLength;
  uint8_t bDescriptorType;
  uint8_t bDescriptorSubtype;
  uint8_t bUnitID;
  uint8_t bNrInPins;
  uint8_t baSourceID[];
} uvc_desc_vc_selector_unit_t;

typedef struct __attribute__((packed)) uvc_desc_vc_processing_unit {
  uint8_t bLength;
  uint8_t bDescriptorType;
  uint8_t bDescriptorSubtype;
  uint8_t bUnitID;
  uint8_t bSourceID;
  uint_le16_t wMaxMultiplier;
  uint_le16_t wControlSize;
  uint8_t bmControls[];
} uvc_desc_vc_processing_unit_t;

typedef struct __attribute__((packed)) uvc_desc_vc_extension_unit {
  uint8_t bLength;
  uint8_t bDescriptorType;
  uint8_t bDescriptorSubtype;
  uint8_t bUnitID;
  uint8_t guidExtensionCode[16];
  uint8_t bNumControls;
  uint8_t bNrInPins;
  uint8_t baSourceID[];
} uvc_desc_vc_extension_unit_t;

typedef struct __attribute__((packed)) uvc_desc_vs_input_header {
  uint8_t bLength;
  uint8_t bDescriptorType;
  uint8_t bDescriptorSubtype;
  uint8_t bNumFormats;
  uint_le16_t wTotalLength;
  uint8_t bEndpointAddress;
  uint8_t bmInfo;
  uint8_t bTerminalLink;
  uint8_t bStillCaptureMethod;
  uint8_t bTriggerSupport;
  uint8_t bTriggerUsage;
  uint8_t bControlSize;
  uint8_t bmaControls[];
} uvc_desc_vs_input_header_t;

typedef struct __attribute__((packed)) uvc_desc_vs_output_header {
  uint8_t bLength;
  uint8_t bDescriptorType;
  uint8_t bDescriptorSubtype;
  uint8_t bNumFormats;
  uint_le16_t wTotalLength;
  uint8_t bEndpointAddress;
  uint8_t bTerminalLink;
  uint8_t bControlSize;
  uint8_t bmaControls[];
} uvc_desc_vs_output_header_t;

typedef struct __attribute__((packed)) uvc_desc_vs_still_image {
  uint8_t bLength;
  uint8_t bDescriptorType;
  uint8_t bDescriptorSubtype;
  uint8_t bEndpointAddress;
  uint8_t bNumImageSizePatterns;
  uint8_t baData[];
} uvc_desc_vs_still_image_t;

typedef struct __attribute__((packed)) uvc_desc_vs_format_uncompressed {
  uint8_t bLength;
  uint8_t bDescriptorType;
  uint8_t bDescriptorSubtype;
  uint8_t bFormatIndex;
  uint8_t bNumFrameDescriptors;
  uint8_t guidFormat[16];
  uint8_t bBitsPerPixel;
  uint8_t bDefaultFrameIndex;
  uint8_t bAspectRatioX;
  uint8_t bAspectRatioY;
  uint8_t bmInterlaceFlags;
  uint8_t bCopyProtect;
} uvc_desc_vs_format_uncompressed_t;

typedef struct __attribute__((packed)) uvc_desc_vs_frame_uncompressed {
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

typedef struct __attribute__((packed)) uvc_desc_vs_color_matching {
  uint8_t bLength;
  uint8_t bDescriptorType;
  uint8_t bDescriptorSubtype;
  uint8_t bColorPrimaries;
  uint8_t bTransferCharacteristics;
  uint8_t bMatrixCoefficients;
} uvc_desc_vs_color_matching_t;

void disp_uvc_descriptors(int devid, int subclass, int type, uint8_t *desc, void *arg)
{
    char str[256];

    switch (desc[1]) {
    case ZUSB_DESC_CS_INTERFACE:
        switch (subclass) {
        case 1:     // Video Control
            printf("    CS_INTERFACE: ");
            switch (desc[2]) {
            case 0x01:
                uvc_desc_vc_header_t *dvch = (uvc_desc_vc_header_t *)desc;
                printf("VC_HEADER:");
                printf(" rev:%x", zusb_le16toh(dvch->bcdUVC));
                printf(" len:%d", zusb_le16toh(dvch->wTotalLength));
                printf(" freq:%ld", zusb_le32toh(dvch->dwClockFrequency));
                printf(" if");
                for (int i = 0; i < dvch->bInCollection; i++) {
                    printf("%c%d", i == 0 ? ':' : ',', dvch->baInterfaceNr[i]);
                }
                break;
            case 0x02:
                uvc_desc_vc_input_terminal_t *dvit = (uvc_desc_vc_input_terminal_t *)desc;
                printf("VC_INPUT_TERMINAL:");
                printf(" id:%d", dvit->bTerminalID);
                printf(" type:0x%03x", zusb_le16toh(dvit->wTerminalType));
                printf(" assoc:%d", dvit->bAssocTerminal);
                if (dvit->iTerminal &&
                    zusb_get_string_descriptor(str, sizeof(str), dvit->iTerminal) > 0) {
                    printf(" name:%s", str);
                }
                break;
            case 0x03:
                uvc_desc_vc_output_terminal_t *dvot = (uvc_desc_vc_output_terminal_t *)desc;
                printf("VC_OUTPUT_TERMINAL:");
                printf(" id:%d", dvot->bTerminalID);
                printf(" type:0x%03x", zusb_le16toh(dvot->wTerminalType));
                printf(" assoc:%d", dvot->bAssocTerminal);
                printf(" src:%d", dvot->bSourceID);
                if (dvot->iTerminal &&
                    zusb_get_string_descriptor(str, sizeof(str), dvot->iTerminal) > 0) {
                    printf(" name:%s", str);
                }
                break;
            case 0x04:
                uvc_desc_vc_selector_unit_t *dvsu = (uvc_desc_vc_selector_unit_t *)desc;
                printf("VC_SELECTOR_UNIT:");
                printf(" id:%d", dvsu->bUnitID);
                printf(" src");
                for (int i = 0; i < dvsu->bNrInPins; i++) {
                    printf("%c%d", i == 0 ? ':' : ',', dvsu->baSourceID[i]);
                }
                break;
            case 0x05:
                uvc_desc_vc_processing_unit_t *dvpu = (uvc_desc_vc_processing_unit_t *)desc;
                printf("VC_PROCESSING_UNIT:");
                printf(" id:%d", dvpu->bUnitID);
                printf(" src:%d", dvpu->bSourceID);
                break;
            case 0x06:
                uvc_desc_vc_extension_unit_t *dvex = (uvc_desc_vc_extension_unit_t *)desc;
                printf("VC_EXTENSION_UNIT:");
                printf(" id:%d", dvex->bUnitID);
                printf(" src");
                for (int i = 0; i < dvex->bNrInPins; i++) {
                    printf("%c%d", i == 0 ? ':' : ',', dvex->baSourceID[i]);
                }
                break;
            }
            printf("\n");
            break;
        case 2:     // Video Streaming
            printf("    CS_INTERFACE: ");
            switch (desc[2]) {
            case 0x01:
                uvc_desc_vs_input_header_t *dvsih = (uvc_desc_vs_input_header_t *)desc;
                printf("VS_INPUT_HEADER:");
                printf(" fmt:%d", dvsih->bNumFormats);
                printf(" len:%d", zusb_le16toh(dvsih->wTotalLength));
                printf(" ep:0x%02x", dvsih->bEndpointAddress);
                printf(" info:0x%02x", dvsih->bmInfo);
                printf(" link:%d", dvsih->bTerminalLink);
                printf(" still:%d", dvsih->bStillCaptureMethod);
                printf(" trigger:%d", dvsih->bTriggerSupport);
                printf(" usage:%d", dvsih->bTriggerUsage);
                printf(" size:%d", dvsih->bControlSize);
                break;
            case 0x02:
                uvc_desc_vs_output_header_t *dvsoh = (uvc_desc_vs_output_header_t *)desc;
                printf("VS_OUTPUT_HEADER:");
                printf(" fmt:%d", dvsoh->bNumFormats);
                printf(" len:%d", zusb_le16toh(dvsoh->wTotalLength));
                printf(" ep:0x%02x", dvsoh->bEndpointAddress);
                printf(" link:%d", dvsoh->bTerminalLink);
                printf(" size:%d", dvsoh->bControlSize);
                break;
            case 0x03:
                uvc_desc_vs_still_image_t *dvsim = (uvc_desc_vs_still_image_t *)desc;
                printf("VS_STILL_IMAGE_FRAME:");
                printf(" ep:0x%02x", dvsim->bEndpointAddress);
                printf(" size");
                for (int i = 0; i < dvsim->bNumImageSizePatterns; i++) {
                    printf("%c(%dx%d)", i == 0 ? ':' : ',',
                           dvsim->baData[i * 4] + (dvsim->baData[i * 4 + 1] << 8),
                           dvsim->baData[i * 4 + 2] + (dvsim->baData[i * 4 + 3] << 8));
                }
                break;
            case 0x04:
                uvc_desc_vs_format_uncompressed_t *dvsfu = (uvc_desc_vs_format_uncompressed_t *)desc;
                printf("VS_FORMAT_UNCOMPRESSED:");
                printf(" idx:%d", dvsfu->bFormatIndex);
                printf(" frames:%d", dvsfu->bNumFrameDescriptors);
                printf(" bpp:%d", dvsfu->bBitsPerPixel);
                printf(" def:%d", dvsfu->bDefaultFrameIndex);
                printf(" aspect:%d:%d", dvsfu->bAspectRatioX, dvsfu->bAspectRatioY);
                printf(" interlace:0x%02x", dvsfu->bmInterlaceFlags);
                printf(" protect:%d", dvsfu->bCopyProtect);
                break;
            case 0x05:
                uvc_desc_vs_frame_uncompressed_t *dvsfr = (uvc_desc_vs_frame_uncompressed_t *)desc;
                printf("VS_FRAME_UNCOMPRESSED:");
                printf(" idx:%d", dvsfr->bFrameIndex);
                printf(" cap:0x%02x", dvsfr->bmCapabilities);
                printf(" size:%dx%d", zusb_le16toh(dvsfr->wWidth), zusb_le16toh(dvsfr->wHeight));
                printf(" bitrate:%ld-%ld", zusb_le32toh(dvsfr->dwMinBitRate), zusb_le32toh(dvsfr->dwMaxBitRate));
                printf(" bufsize:%ld", zusb_le32toh(dvsfr->dwMaxVideoFrameBufferSize));
                printf(" interval:%ld", zusb_le32toh(dvsfr->dwDefaultFrameInterval));
                printf(" type:%d", dvsfr->bFrameIntervalType);
                break;
            case 0x06:
                uvc_desc_vs_format_mjpeg_t *dvsfm = (uvc_desc_vs_format_mjpeg_t *)desc;
                printf("VS_FORMAT_MJPEG:");
                printf(" idx:%d", dvsfm->bFormatIndex);
                printf(" frames:%d", dvsfm->bNumFrameDescriptors);
                printf(" flag:0x%x", dvsfm->bmFlags);
                printf(" def:%d", dvsfm->bDefaultFrameIndex);
                printf(" aspect:%d:%d", dvsfm->bAspectRatioX, dvsfm->bAspectRatioY);
                printf(" interlace:0x%02x", dvsfm->bmInterlaceFlags);
                printf(" protect:%d", dvsfm->bCopyProtect);
                break;
                break;
            case 0x07:
                uvc_desc_vs_frame_mjpeg_t *dvsfrm = (uvc_desc_vs_frame_mjpeg_t *)desc;
                printf("VS_FRAME_MJPEG:");
                printf(" idx:%d", dvsfrm->bFrameIndex);
                printf(" cap:0x%02x", dvsfrm->bmCapabilities);
                printf(" size:%dx%d", zusb_le16toh(dvsfrm->wWidth), zusb_le16toh(dvsfrm->wHeight));
                printf(" bitrate:%ld-%ld", zusb_le32toh(dvsfrm->dwMinBitRate), zusb_le32toh(dvsfrm->dwMaxBitRate));
                printf(" bufsize:%ld", zusb_le32toh(dvsfrm->dwMaxVideoFrameBufferSize));
                printf(" interval:%ld", zusb_le32toh(dvsfrm->dwDefaultFrameInterval));
                printf(" type:%d", dvsfrm->bFrameIntervalType);
                break;
                break;
            case 0x0a:
                printf("VS_FORMAT_MPEGTS:");
                break;
            case 0x0c:
                printf("VS_FORMAT_DV:");
                break;
            case 0x0d:
                uvc_desc_vs_color_matching_t *dvscm = (uvc_desc_vs_color_matching_t *)desc;
                printf("VS_COLORFOMRAT:");
                printf(" prim:%d", dvscm->bColorPrimaries);
                printf(" char:%d", dvscm->bTransferCharacteristics);
                printf(" coeff:%d", dvscm->bMatrixCoefficients);
                break;
            case 0x10:
                printf("VS_FORMAT_FRAME_BASED:");
                break;
            case 0x11:
                printf("VS_FRAME_FRAME_BASED:");
                break;
            case 0x12:
                printf("VS_FRAME_STREAM_BASED:");
                break;
            }
            printf("\n");
            break;
        }
    case ZUSB_DESC_CS_ENDPOINT:
    }
}

//////////////////////////////////////////////////////////////////////////////

int main(int argc, char **argv)
{
    struct disp_descriptors_arg arg = {
        .verbose = false,
        .devid = -1,
        .current_config = -1,
        .current_iface = -1,
    };
    int hid_report = 0;
    int devvid = -1;
    int devpid = -1;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-h") == 0) {
            printf("Usage: %s [-h][-v][-r] [devid | vid:pid]\n", argv[0]);
            printf(" -v: verbose (dump descriptor data)\n");
            printf(" -r: show HID report descriptor\n");
            return 0;
        } else if (strcmp(argv[i], "-v") == 0) {
            arg.verbose = true;
        } else if (strcmp(argv[i], "-r") == 0) {
            hid_report++;
        } else if (strchr(argv[i], ':') && ((devvid < 0) || (devpid < 0))) {
            devvid = strtol(argv[i], NULL, 16);
            devpid = strtol(strchr(argv[i], ':') + 1, NULL, 16);
        } else if (arg.devid < 0 && devvid < 0 && devpid < 0) {
            arg.devid = strtol(argv[i], NULL, 0);
        }
    }

    _iocs_b_super(0);

    int ch;
    if ((ch = zusb_open(0)) < 0) {
        printf("ZUSB デバイスが見つかりません\n");
        exit(1);
    }

    for (int i = 0; i < ZUSB_N_CH; i++) {
        zusb_set_channel(i);
        ch_devid[i] = -1;
        if (zusb->stat & ZUSB_STAT_INUSE) {
            ch_devid[i] = zusb->devid;
        }
    }
    zusb_set_channel(ch);

    if (arg.verbose) {
        int version = zusb_version();
        printf("ZUSB version:%x.%02x\n", version >> 8, version & 0xff);
    }

    if (devvid >= 0 && devpid >= 0) {
        arg.devid = zusb_find_device_with_vid_pid(devvid, devpid, 0);
    }

    if (arg.devid < 0) {
        zusb_find_device(disp_device_descriptor, &arg, 0);
    } else {
        zusb_find_device(disp_descriptors, &arg, 0);
        if (hid_report) {
            disp_hid_report(arg.devid, arg.verbose, hid_report > 1);
        }
    }

    zusb_close();

    return 0;
}
