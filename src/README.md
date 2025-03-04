# X68000 Z ZUSB サンプルアプリ

## 概要

X68000 Z ZUSB 用のサンプルアプリです。


## zusb.x - USB 機器の情報表示

### 使用方法

コマンドラインから以下のように実行します。

```
zusb.x [-h][-v][-r][devid | vid:pid]
```

以下のオプションを指定できます。

* -h\
  ヘルプを表示します
* -v\
  ディスクリプタ情報を16進ダンプでも表示します
* -r\
  HID デバイスのレポートディスクリプタの内容も表示します
* devid\
  デバイス ID を指定します (省略すると全デバイスの一覧を表示します)
  * デバイスを VID:PID のように指定すると VID, PID が一致するデバイスを探します

### 使用例
```
A> zusb
Device:262 ID:0xcafe-0x4002 X68000Z Remote Drive Mass Storage
Device:261 ID:0x0d8c-0x0014 C-Media Electronics Inc. USB Audio Device
Device:260 ID:0x056e-0x7016 Etron Technology, Inc. UCAM-C0220F
Device:259 ID:0x056e-0x0134 Gtech wireless dongle
```

```
A> zusb 259
Device:259
 Device: USB:110 class:0 subclass:0 protocol:0 maxpacket:64 VID:0x056e PID:0x0134 ver:120
        Manufacturer: Gtech
        Product:      wireless dongle
  Configuration: #1 MaxPower:98mA
   Interface:    #0 class:3 subclass:1 protocol:1
    HID:         version:110 country:0 (type:0x22 size:57)
    Endpoint:    0x81 Interrupt MaxPacket:8
   Interface:    #1 class:3 subclass:1 protocol:2
    HID:         version:110 country:0 (type:0x22 size:215)
    Endpoint:    0x82 Interrupt MaxPacket:8
```


## zusbhid - USB HID デバイスのテスト

### 使用方法

コマンドラインから以下のように実行します。

```
zusbhid.x [-h] [devid | vid:pid] [time]
```

以下のオプションを指定できます。

* -h\
  ヘルプを表示します
* devid\
  デバイス ID を指定します (省略すると HID デバイスの一覧を表示します)
  * デバイスを VID:PID のように指定すると VID, PID が一致するデバイスを探します
* time\
  テストを実行する秒数を指定します (デフォルトは 10 秒)

### 説明

* devid を指定して起動すると、その機器に接続して HID report が来るたびにその内容を16進表示します。
* USBキーボードのdevidを指定すると、終了するまでエミュレータに通常のキー入力が入らなくなるので注意が必要です。


## zusbmsc.x - USB MSC デバイスのテスト

### 使用方法

コマンドラインから以下のように実行します。

```
zusbmsc.x [-h] [devid | vid:pid] [sector] [count]
```

以下のオプションを指定できます。

* -h\
  ヘルプを表示します
* devid\
  デバイス ID を指定します (省略すると HID デバイスの一覧を表示します)
  * デバイスを VID:PID のように指定すると VID, PID が一致するデバイスを探します
* sector\
  ダンプ開始セクタ番号を指定します
* count\
  ダンプするセクタ数を指定します (デフォルトは 1)

### 説明

* devid を指定して起動すると、その機器に接続して SCSI INQUIRY コマンドと READ CAPACITY コマンドを発行して情報を表示します
* sector, countを指定すると、指定されたセクタ番号から指定されたセクタ数分をダンプ表示します。
* MSC Bulk only transport (USB HDD や USB メモリ等) と CBI transport (USB FDD 等) に対応しています。


## zusbaudio - USB Audio デバイスのテスト

### 使用方法

コマンドラインから以下のように実行します。

```
zusbaudio.x [-h][-r<sample rate>] [-v<volume>] [devid | vid:pid] [filename]
```

以下のオプションを指定できます。

* -h\
  ヘルプを表示します
* -r\<sample rate\>\
  再生データのサンプリングレートを指定します (デフォルトは 44100)
* -v\<volume\>\
  再生時の音量を指定します (127から-128)
* devid\
  デバイス ID を指定します (省略すると UAC デバイスの一覧を表示します)
  * デバイスを VID:PID のように指定すると VID, PID が一致するデバイスを探します
* filename\
  再生するファイル名 (16bit Little-endian ストレート PCM 44100Hz/48000Hz のみ対応)

### 説明

* devid、ファイル名を指定するとそのファイルを USB Audio デバイスで再生します
* 44100Hz 16bit ステレオ PCM に対応しているデバイスであれば動作するはずです。以下のデバイスで動作を確認しています。
  * UGREEN USB オーディオ 変換アダプタ
  * Roland UA-30


## zusbcdplay - USB CD-ROM ドライブと USB Audio デバイスを用いた音楽再生

### 使用方法

コマンドラインから以下のように実行します。

```
zusbcdplay.x [-h][-v<volume>][-i<scsiid>] [devid | vid:pid] [track]
```

以下のオプションを指定できます。

* -h\
  ヘルプを表示します
* -v\<volume\>\
  再生時の音量を指定します (127から-128)
* -i\<scsiid\>\
  CD-ROM ドライブに割り当てた SCSI ID を指定します (省略時は 6)
* devid\
  デバイス ID を指定します (省略すると UAC デバイスの一覧を表示します)
  * デバイスを VID:PID のように指定すると VID, PID が一致するデバイスを探します
* track\
  再生するトラック番号 (省略すると CD のトラック番号一覧を表示します)

### 説明

* [zusbscsi.sys](zusbscsi/README.md) で認識した CD-ROM ドライブに入れた音楽 CD のオーディオデータを取得して USB Audio デバイスで再生します。
* 実行前に、zusbscsi.sys で CD-ROM ドライブに SCSI ID を割り当てておく必要があります。
