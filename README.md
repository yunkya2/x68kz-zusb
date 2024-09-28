# X68000 Z ZUSB ドライバ サンプルコード & 仕様ドキュメント

## 概要

このリポジトリは、X68000 Z エミュレータに機能追加する ZUSB ドライバのサンプルコードです。

HACKER'S EDITION 上で ZUSB 対応を有効にしたエミュレータを使用して
起動した X68000 システム上で実行することで、X68000 Z に接続したUSBデバイスを直接操作できます。

## 仕様

* [ZUSB レジスタ仕様](ZUSB-specs.md)
* [ZUSB API 仕様](ZUSB-api.md)

## ビルド方法

サンプルコードのビルドには [elf2x68k](https://github.com/yunkya2/elf2x68k) が必要です。
`src` ディレクトリ内で `make` を実行するとビルドできます。

ビルド済みバイナリと、このバイナリを含んだ起動可能な XDF イメージを [prebuilt](prebuilt/) ディレクトリに用意しています。

## サンプルの説明

### zusb.x - USB 機器の情報表示
* 使用方法
  * zusb.x [-h][-v][-r][devid]
* オプション
  * -h : ヘルプを表示します
  * -v : ディスクリプタ情報を16進ダンプでも表示します
  * -r : HID デバイスのレポートディスクリプタの内容も表示します
  * devid : デバイス ID を指定します (省略すると全デバイスの一覧を表示します)
* 使用例
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


### zusbhid - USB HID デバイスのテスト
* 使用方法
  * zusbhid.x [-h] [devid] [time]
* オプション
  * -h : ヘルプを表示します
  * devid : デバイス ID を指定します (省略すると HID デバイスの一覧を表示します)
  * time : テストを実行する秒数を指定します (デフォルトは 10 秒)
* 説明
  * devid を指定して起動すると、その機器に接続して HID report が来るたびにその内容を16進表示します。
  * USBキーボードのdevidを指定すると、終了するまでエミュレータに通常のキー入力が入らなくなるので注意が必要です。

### zusbmsc.x - USB MSC デバイスのテスト
* 使用方法
  * zusbmsc.x [-h] [devid] [sector] [count]
* オプション
  * -h : ヘルプを表示します
  * devid : デバイス ID を指定します (省略すると HID デバイスの一覧を表示します)
  * sector : ダンプ開始セクタ番号を指定します
  * count : ダンプするセクタ数を指定します (デフォルトは 1)
* 説明
  * devid を指定して起動すると、その機器に接続して SCSI INQUIRY コマンドと READ CAPACITY コマンドを発行して情報を表示します
  * sector, countを指定すると、指定されたセクタ番号から指定されたセクタ数分をダンプ表示します。

### zusbaudio - USB Audio デバイスのテスト
* 使用方法
  * zusbaudio.x [-h][-r\<sample rate\>] [-v\<volume\>] [devid] [filename]
* オプション
  * -h : ヘルプを表示します
  * -r\<sample rate\> : 再生データのサンプリングレートを指定します (デフォルトは 44100)
  * -v\<volume\> : 再生時の音量を指定します (127から-128)
  * devid : デバイス ID を指定します (省略すると UAC デバイスの一覧を表示します)
  * filename : 再生するファイル名 (16bit Little-endian ストレート PCM 44100Hz/48000Hz のみ対応)
* 説明
  * devid、ファイル名を指定するとそのファイルを USB Audio デバイスで再生します
  * UAC クラスのデバイスであれば動作するはずですが、動作は UGREEN USB オーディオ 変換アダプタ でのみ確認しています。

### zusbvideo - USB Video デバイスのテスト
* 使用方法
  * zusbvideo.x [-h][-v][-r\<resolution\>][-s\<video size\>] [devid] [frames]
* オプション
  * -h : ヘルプを表示します
  * -v : 取得した USB ビデオフレームパケットの情報を表示します
  * -r\<resolution\> : 再生時の解像度を指定します (0:表示なし 1:256×256 2:512×512)
  * -s\<video size\> : 取得する画像の解像度を指定します (0:160×120 1:320×240)
  * devid : デバイス ID を指定します (省略すると UAC デバイスの一覧を表示します)
  * frames : 取得するフレーム数 (デフォルトは 20)
* 説明
  * devid を指定すると、カメラから画像を取得して画面に表示します。
  * 動作は ELECOM UCAM-C0220FBBK でのみ確認していますが、UVC 準拠のカメラで YUV 非圧縮 160x120 または 320x240 をサポートしているものであれば動作するはずです。

### zusbjoyc - X68000 Z JOYCARD のテスト
* 使用方法
  * zusbjoyc.x [-s][-r]
* オプション
  * -s: 常駐します
  * -r: 常駐を解除します
* 説明
  * 実行すると ZUIKI X68000 Z JOYCARD が接続されるのを待ちます
    * Z JOYCARD (VID:0x33dd PID:0x0013) 専用です。他のコントローラは非対応です。
  * 接続すると、JOYCARD からの入力を 16進表示します。10 秒経つと終了します。
  * -s オプションを指定すると常駐して、ジョイカードの入力をキー入力に変換します。
    * 十字キー: カーソルキー
    * A, B ボタン : A, B
    * RIGHT, LEFT ボタン : R, L
    * START, SELECT ボタン : S, E
  * -r オプションを指定すると、常駐している zusbjoyc プロセスがいれば常駐解除します。
