#ifndef _ZUSBSCSI_H_
#define _ZUSBSCSI_H_

#include <stdint.h>

//****************************************************************************
// Driver interface
//****************************************************************************

#define ZUSBSCSI_NAME "/ZUSCSI/"
#define ZUSBSCSI_STATE_MAGIC 0x5a534354UL
#define ZUSBSCSI_MAX_DRIVE 4

struct zusb_unit;

struct zusbscsi_state {
  uint32_t magic;
  void *oldvector;
  void *newvector;
  int8_t channels[ZUSBSCSI_MAX_DRIVE];
  uint8_t mask;
  struct zusb_unit *units;
};

int zusbscsi_initialize(int argc, char **argv);

//****************************************************************************
// Private structure definitions
//****************************************************************************

// ZUSBデバイスの機器情報
struct zusb_unit {        // sizeof(struct zusb_unit) = 10 (head_scsi.S の定義と一致させること)
  int8_t scsiid;          // この機器に割り当てたSCSI ID (-1なら使用しない)
  int8_t ch;              // 接続先のチャネル番号 (-1なら未接続)
  int8_t devtype;         // この機器のperipheral device type (5:CD-ROM 7:MO 0:どちらでも可)
  uint8_t iProduct;       // デバイス名のstring descriptor番号
  uint8_t subclass;       // MSC subclass (0x06:SCSI transparent 0x02:ATAPI)
  uint8_t protocol;       // MSC protocol (0x50:BBB のみ対応)
  uint16_t vid;           // このデバイスのvendor ID (0ならVIDをチェックしない)
  uint16_t pid;           // このデバイスのproduct ID (0ならPIDをチェックしない)
};

#endif /* _ZUSBSCSI_H_ */
