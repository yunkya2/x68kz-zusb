#ifndef _ZUSBSCSI_H_
#define _ZUSBSCSI_H_

#include <stdint.h>

//****************************************************************************
// Human68k structure definitions
//****************************************************************************

struct dos_req_header {
  uint8_t magic;       // +0x00.b  Constant (26)
  uint8_t unit;        // +0x01.b  Unit number
  uint8_t command;     // +0x02.b  Command code
  uint8_t errl;        // +0x03.b  Error code low
  uint8_t errh;        // +0x04.b  Error code high
  uint8_t reserved[8]; // +0x05 .. +0x0c  not used
  uint8_t attr;        // +0x0d.b  Attribute / Seek mode
  void *addr;          // +0x0e.l  Buffer address
  uint32_t status;     // +0x12.l  Bytes / Buffer / Result status
  void *fcb;           // +0x16.l  FCB
} __attribute__((packed, aligned(2)));

struct dos_bpb {
  uint16_t sectbytes;  // +0x00.b  Bytes per sector
  uint8_t sectclust;   // +0x02.b  Sectors per cluster
  uint8_t fatnum;      // +0x03.b  Number of FATs
  uint16_t resvsects;  // +0x04.w  Reserved sectors
  uint16_t rootent;    // +0x06.w  Root directory entries
  uint16_t sects;      // +0x08.w  Total sectors
  uint8_t mediabyte;   // +0x0a.b  Media byte
  uint8_t fatsects;    // +0x0b.b  Sectors per FAT
  uint32_t sectslong;  // +0x0c.l  Total sectors (long)
  uint32_t firstsect;  // +0x10.l  Partition first sector
};

//****************************************************************************
// Private structure definitions
//****************************************************************************

// ZUSBデバイスの機器情報
struct zusb_unit {        // sizeof(struct zusb_unit) = 8
  int8_t scsiid;          // この機器に割り当てたSCSI ID (-1なら使用しない)
  int8_t devid;           // 接続先のdevid (-1なら未接続)
  int8_t devtype;         // この機器のperipheral device type (5:CD-ROM 7:MO 0:どちらでも可)
  uint8_t iProduct;       // デバイス名のstring descriptor番号
  uint16_t vid;           // このデバイスのvendor ID (0ならVIDをチェックしない)
  uint16_t pid;           // このデバイスのproduct ID (0ならPIDをチェックしない)
};

#endif /* _ZUSBSCSI_H_ */
