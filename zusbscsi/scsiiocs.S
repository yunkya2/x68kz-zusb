/*
 * Copyright (c) 2025 Yuichi Nakamura (@yunkya2)
 *
 * The MIT License (MIT)
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

    .text

    .global scsiiocs_org
scsiiocs_org:
    .long   0                   // 変更前のIOCS _SCSIDRV処理アドレス

    .global zusbscsi_mask
zusbscsi_mask:
    .byte   0                   // ZUSB SCSIのSCSI ID処理マスク
    .global zusb_selected
zusb_selected:
    .byte   0                   // ZUSB SCSIのIDが選択されているか

    .even

    .global scsiiocs_zusb
scsiiocs_zusb:
    tst.b   %d1                 // _S_RESET
    beq     scsiiocs_both

    cmpi.b  #0x03,%d1           // _S_SELECT, _S_SELECTA
    bcs     scsiiocs_select

    cmpi.b  #0x0a,%d1           // _S_LEVEL
    beq     scsiiocs_orgcmd

    cmpi.b  #0x20,%d1
    bcs     scsiiocs_low        // 0x03-0x1f
scsiiocs_command:
    moveq.l #1,%d0
    lsl.b   %d4,%d0
    and.b   %pc@(zusbscsi_mask),%d0
    beq     scsiiocs_orgcmd     // SCSI IDがZUSB SCSIのものでなければ変更前の処理を実行
scsiiocs_hook:
    movem.l %d1-%d5/%a1-%a3,%sp@-
    jsr     zusbscsi
    movem.l %sp@+,%d1-%d5/%a1-%a3
    rts

scsiiocs_both:                  // ZUSB SCSIと変更前のIOCS _SCSIDRVを両方実行
    movem.l %d1-%d5/%a1-%a3,%sp@-
    jsr     zusbscsi
    movem.l %sp@+,%d1-%d5/%a1-%a3
    move.l  %pc@(scsiiocs_org),%sp@-
    rts

scsiiocs_select:                // セレクションフェーズのターゲットがZUSB SCSIか確認
    moveq.l #1,%d0
    lsl.b   %d4,%d0
    and.b   %pc@(zusbscsi_mask),%d0
    sne.b   zusb_selected       // 後続のlow level commandをZUSB SCSIが処理するか
scsiiocs_low:                   // low level commandの実行
    tst.b   zusb_selected
    bne     scsiiocs_hook       // ZUSB SCSIが選択されている
scsiiocs_orgcmd:                // 変更前のIOCS _SCSIDRVを実行する
    move.l  %pc@(scsiiocs_org),%sp@-
    rts

    .end
