# X68000 Z USB SCSI IOCS ドライバ zusbscsi.x

## 概要

X68000 Z に接続した USB MO ドライブや USB CD-ROM ドライブなどのマスストレージデバイスを SCSI IOCS コールから利用できるようにするためのデバイスドライバです。

このドライバを組み込むことで、X68000 Z のエミュレーション環境から USB マスストレージデバイスが組み込み時に指定した ID の SCSI デバイスが接続されているように見えます。
[susie.x](http://retropc.net/x68000/software/disk/scsi/susie/) のような SCSI デバイスドライバや CD-ROM ドライバを用いて、USB マスストレージデバイスにアクセスできるようになります。

## 使用方法

コマンドラインから以下のように実行します。

```
zusbscsi.x <オプション>...
```

または CONFIG.SYS に以下のように指定することで、起動時に組み込むこともできます。

```
DEVICE = zusbscsi.x <オプション>...
```

以下の `<オプション>` で、X68000 Z に接続した USB マスストレージのどのデバイスにどの SCSI ID を割り当てるかを指定します。

* `/id<SCSI ID>`\
  デバイスタイプが 5 (CD-ROM device) または 7 (Optical memory device - MOドライブなど) のデバイスに指定した SCSI ID を割り当てます。
* `/id<SCSI ID>:MO`\
  デバイスタイプが 7 (Optical memory device) のデバイスに指定した SCSI ID を割り当てます。
* `/id<SCSI ID>:CD`\
  デバイスタイプが 5 (CD-ROM device) のデバイスに指定した SCSI ID を割り当てます。
* `/id<SCSI ID>:<VID>:<PID>`\
  ベンダIDが `<VID>` 、プロダクトIDが `<PID>` のデバイスに指定した SCSI ID を割り当てます。

例えば、

```
zusbscsi.x /id5:MO /id6:CD
```

または CONFIG.SYS に

```
DEVICE = zusbscsi.x /id5:MO /id6:CD
```

のように指定すると、USB に MO ドライブが接続されている場合に SCSI ID 5 を、CD-ROM ドライブが接続されている場合には SCSI ID 6 を割り当てます。

コマンドラインから常駐した zusbscsi.x は `zusbscsi.x /r` で常駐解除できます。CONFIG.SYS から組み込んだ場合、別のドライバが SCSI IOCS ベクタを変更している場合や、susie.x が割り当て先の SCSI ID を使用している場合は解除できません。

## SCSI デバイスドライバによる利用

zusbscsi.x が常駐すると以下のようなメッセージが表示されて、表示された SCSI ID を用いた SCSI IOCS 呼び出しで対応する USB デバイスを利用できるようになります。

```
X68000 Z USB Pseudo SCSI IOCS driver version xxxxxxxx
以下のSCSI IDでSCSI IOCSからUSBマスストレージデバイスが利用可能です
ID5: 光磁気ディスク (xxxxxxx)
ID6: CD-ROMドライブ (xxxxxxx)
```

以下のようなドライバやコマンドを USB デバイスに対して使用できます。

 * Human68k 純正の FORMAT.X によるディスクのフォーマット
 * [SCSIデバイスドライバ susie.x (GORRY氏作)](http://retropc.net/x68000/software/disk/scsi/susie/)
 * CD-ROM ドライバ (CONFIG.SYSによってCD-ROM ドライバより先に zusbscsi.x が組み込まれている必要があります)
   * CDDEV.SYS - CD-ROM(ISO96600) DRIVER for X680x0 (計測技研製)
   * [CDDRV.SYS - キャッシュ内蔵 CD-ROM ドライバ (A.Yamazaki氏作)](https://www.vector.co.jp/soft/x68/hardware/se021968.html)
 * その他、SCSI IOCS を用いたディスクアクセスを行うプログラム全般

例えば SCSI ID 5 に MO ドライブ や CD-ROM ドライブを割り当てた場合、
[susie.x](http://retropc.net/x68000/software/disk/scsi/susie/)
を以下のように用いることで、そのドライブにドライブ名を割り当てることができます。

```
susie /id5 *:
```

## CD-DA 読み込み対応

初期の SCSI CD-ROM ドライブでは音楽 CD のオーディオデータ (CD-DA) の読み込みにメーカー固有のコマンドが必要でした(SONY系/TOSHIBA系)。
zusbscsi.x では CD-ROM ドライブに対する SONY系 CD-DA読み込みコマンドを、後に規格化された READ CD コマンドに変換して発行します。

これにより、[CD2PCMt.x (TNB製作所氏作)](http://retropc.net/x68000/software/disk/scsi/cd2pcmt/) などを用いたオーディオデータの読み込みが可能になります。
