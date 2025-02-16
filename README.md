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
  * zusb.x [-h][-v][-r][devid | vid:pid]
* オプション
  * -h : ヘルプを表示します
  * -v : ディスクリプタ情報を16進ダンプでも表示します
  * -r : HID デバイスのレポートディスクリプタの内容も表示します
  * devid : デバイス ID を指定します (省略すると全デバイスの一覧を表示します)
    * デバイスを VID:PID のように指定すると VID, PID が一致するデバイスを探します
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
  * zusbhid.x [-h] [devid | vid:pid] [time]
* オプション
  * -h : ヘルプを表示します
  * devid : デバイス ID を指定します (省略すると HID デバイスの一覧を表示します)
    * デバイスを VID:PID のように指定すると VID, PID が一致するデバイスを探します
  * time : テストを実行する秒数を指定します (デフォルトは 10 秒)
* 説明
  * devid を指定して起動すると、その機器に接続して HID report が来るたびにその内容を16進表示します。
  * USBキーボードのdevidを指定すると、終了するまでエミュレータに通常のキー入力が入らなくなるので注意が必要です。


### zusbmsc.x - USB MSC デバイスのテスト
* 使用方法
  * zusbmsc.x [-h] [devid | vid:pid] [sector] [count]
* オプション
  * -h : ヘルプを表示します
  * devid : デバイス ID を指定します (省略すると HID デバイスの一覧を表示します)
    * デバイスを VID:PID のように指定すると VID, PID が一致するデバイスを探します
  * sector : ダンプ開始セクタ番号を指定します
  * count : ダンプするセクタ数を指定します (デフォルトは 1)
* 説明
  * devid を指定して起動すると、その機器に接続して SCSI INQUIRY コマンドと READ CAPACITY コマンドを発行して情報を表示します
  * sector, countを指定すると、指定されたセクタ番号から指定されたセクタ数分をダンプ表示します。
  * MSC Bulk only transport (USB HDD や USB メモリ等) と CBI transport (USB FDD 等) に対応しています。


### zusbaudio - USB Audio デバイスのテスト
* 使用方法
  * zusbaudio.x [-h][-r\<sample rate\>] [-v\<volume\>] [devid | vid:pid] [filename]
* オプション
  * -h : ヘルプを表示します
  * -r\<sample rate\> : 再生データのサンプリングレートを指定します (デフォルトは 44100)
  * -v\<volume\> : 再生時の音量を指定します (127から-128)
  * devid : デバイス ID を指定します (省略すると UAC デバイスの一覧を表示します)
    * デバイスを VID:PID のように指定すると VID, PID が一致するデバイスを探します
  * filename : 再生するファイル名 (16bit Little-endian ストレート PCM 44100Hz/48000Hz のみ対応)
* 説明
  * devid、ファイル名を指定するとそのファイルを USB Audio デバイスで再生します
  * UAC クラスのデバイスであれば動作するはずですが、動作は UGREEN USB オーディオ 変換アダプタ でのみ確認しています。


### zusbvideo - USB Video デバイスのテスト
* 使用方法
  * zusbvideo.x [-h][-v][-m][-r\<resolution\>][-s\<video size\>] [devid | vid:pid] [frames]
* オプション
  * -h : ヘルプを表示します
  * -v : 取得した USB ビデオフレームパケットの情報を表示します
  * -m : 画像取得フォーマットを非圧縮から Motion JPEG に変更します
    * USB カメラが Motion JPEG に対応している必要があります
  * -r\<resolution\> : 再生時の解像度を指定します (0:表示なし 1:256×256 2:512×512)
  * -s\<video size\> : 取得する画像の解像度を指定します (0:160×120 1:320×240 2=640x480 3=800x600 4=1280x720)
    * 非圧縮の場合は 160x120 または 320x240 のみが選択できます
  * devid : デバイス ID を指定します (省略すると UAC デバイスの一覧を表示します)
    * デバイスを VID:PID のように指定すると VID, PID が一致するデバイスを探します
  * frames : 取得するフレーム数 (デフォルトは 20)
* 説明
  * devid を指定すると、カメラから画像を取得して画面に表示します。
  * カメラが Motion JPEG に対応している場合は -m オプションを指定すると画像を JPEG で取得し、 "videoNNN.jpg" というファイル名で保存します (NNN=000～999の数値)
  * 動作する USB Video デバイスは以下の仕様に限られます。
    * フレームフォーマットは非圧縮または Motion JPEG をサポートしていること
    * 非圧縮では 160x120 または 320x240 の解像度をサポートしていること
    * High-bandwidth isochronous transfer 非対応でも動作すること
      * (ビデオストリーム受信用のエンドポイントが最大パケットサイズ 1024 バイト以下の設定をサポートしていること)
  * 動作は以下のデバイスでのみ確認しています。
    * ELECOM UCAM-C0220FBBK (非圧縮のみ対応)
    * ELECOM UCAM-C310FBBK (非圧縮/Motion JPEG)


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


### zusbcdplay - USB CD-ROM ドライブと USB Audio デバイスを用いた音楽再生
* 使用方法
  * zusbcdplay.x [-h][-v\<volume\>][-i\<scsiid\>] [devid | vid:pid] [track]
* オプション
  * -h : ヘルプを表示します
  * -v\<volume\> : 再生時の音量を指定します (127から-128)
  * -i\<scsiid\> : CD-ROM ドライブに割り当てた SCSI ID を指定します (省略時は 6)
  * devid : デバイス ID を指定します (省略すると UAC デバイスの一覧を表示します)
    * デバイスを VID:PID のように指定すると VID, PID が一致するデバイスを探します
  * track : 再生するトラック番号 (省略すると CD のトラック番号一覧を表示します)
* 説明
  * [zusbscsi.sys](zusbscsi/README.md) で認識した CD-ROM ドライブに入れた音楽 CD のオーディオデータを取得して USB Audio デバイスで再生します。
  * 実行前に、zusbscsi.sys で CD-ROM ドライブに SCSI ID を割り当てておく必要があります。
