# X68000 Z USB SCSI IOCS ドライバ zusbscsi.sys

## 概要

X68000 Z に接続した USB MO ドライブや USB CD-ROM ドライブなどのマスストレージデバイスを SCSI IOCS コールから利用できるようにするためのデバイスドライバです。

利用には HACKER'S EDITION 上で ZUSB 対応を有効にしたエミュレータが必要です。

## 使用方法

zusbscsi.sys を X68000 Z で使用するシステムドライブにコピーして、CONFIG.SYS に以下の行を追加します。

```
DEVICE = zusbscsi.sys <オプション>...
```

<オプション> には、X68000 Z に接続した USB マスストレージのどのデバイスにどの SCSI ID を割り当てるかを以下のように指定します。

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
DEVICE = zusbscsi.sys /id5:MO /id6:CD
```
のように指定すると、USB に MO ドライブが接続されている場合に SCSI ID 5 を、CD-ROM ドライブが接続されている場合には SCSI ID 6 を割り当てます。

CONFIG.SYS を設定して起動すると以下のようなメッセージが表示されて、表示された SCSI ID を用いた SCSI IOCS 呼び出しで対応する USB デバイスを利用できるようになります。

```
X68000 Z USB Pseudo SCSI IOCS driver version xxxxxxxx
以下のSCSI IDでSCSI IOCSからUSBマスストレージデバイスが利用可能です
ID5: 光磁気ディスク (xxxxxxx)
ID6: CD-ROMドライブ (xxxxxxx)
```

zusbscsi.sys 組み込み後は、以下のようなドライバやコマンドを USB デバイスに対して使用できるようになります。
 * Human68k 純正の FORMAT.X によるディスクのフォーマット
 * FORMAT.XによってMOディスクに書き込まれる、純正 SCSI ドライバを用いた MO ディスクアクセス
   * 後述の zusbmodrv.sys を使用します
 * CD-ROM ドライバ
   * 計測技研製 CDDEV.SYS
   * [キャッシュ内蔵 CD-ROM ドライバ CDDRV.SYS (A.Yamazaki氏作)](https://www.vector.co.jp/soft/x68/hardware/se021968.html)
 * [SCSIデバイスドライバ susie.x (GORRY氏作)](http://retropc.net/x68000/software/disk/scsi/susie/)
 * その他、SCSI IOCS を用いたディスクアクセスを行うプログラム全般

### CD-DA 読み込み対応

初期の SCSI CD-ROM ドライブでは音楽 CD のオーディオデータ (CD-DA) の読み込みにメーカー固有のコマンドが必要でした(SONY系/TOSHIBA系)。
zusbscsi.sys では CD-ROM ドライブに対する SONY系 CD-DA読み込みコマンドを、後に規格化された READ CD コマンドに変換して発行します。

これにより、[CD2PCMt.x (TNB製作所氏作)](http://retropc.net/x68000/software/disk/scsi/cd2pcmt/) などを用いたオーディオデータの読み込みが可能になります。

## USB MO ドライバ zusbmodrv.sys 概要

zusbmodrv.sys は、zusbscsi.sys 組み込み後に用いることで、USB MO ドライブに挿入されている MO ディスクの SCSI デバイスドライバをロードするためのドライバです。

zusbscsi.sys の組み込みだけでは SCSI IOCS から MO ドライブを利用できるだけで、MO ディスクにアクセスするためのドライバがロードされません。
susie.x を常駐させることで MO ディスクにアクセスできるようにすることもできますが、zusbmodrv.sys はフォーマット時に書き込まれる純正 SCSI ドライバをロードすることで MO ディスクにアクセスできるようにします

## 使用方法

CONFIG.SYS で zusbscsi.sys の後に以下の行を追加します。
```
DEVICE = zusbmodrv.sys [<オプション>]
```

以下の <オプション> が指定可能です。

* `/id<SCSI ID>`\
  指定した SCSI ID の USB MO ドライブに対して SCSI デバイスドライバを組み込みます。

オプション指定を省略すると、zusbscsi.sys で SCSI IOCS から利用できる USB MO ドライブのうち、まだ SCSI デバイスドライバが組み込まれていない SCSI ID を指定したのと同じ動作になります。

## ライセンス

zusbscsi.sys および zusbmodrv.sys は MIT ライセンスとします。
