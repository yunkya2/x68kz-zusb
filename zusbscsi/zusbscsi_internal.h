#ifndef ZUSBSCSI_INTERNAL_H
#define ZUSBSCSI_INTERNAL_H

#include "zusbscsi.h"

// zusbscsi.c

extern struct zusb_unit zusb_unit[ZUSBSCSI_MAX_DRIVE];
extern struct zusbscsi_state state;
extern struct zusb_unit *zu;

int connect_msc(void);

// zusbscsi_main.c

int zusbscsi_initialize(int argc, char **argv);

// scsiiocs.S

extern void *scsiiocs_org;      // 変更前のIOCS _SCSIDRV処理アドレス
extern uint8_t zusbscsi_mask;   // ZUSB SCSIのSCSI ID処理マスク
extern uint8_t zusb_selected;   // ZUSB SCSIのIDが選択されているか

void scsiiocs_zusb(void);

#endif /* ZUSBSCSI_INTERNAL_H */
