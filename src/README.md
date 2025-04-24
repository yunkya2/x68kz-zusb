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

### 説明

* オプションを付けずに実行すると、X68000 Z に接続されている USB デバイスの一覧を表示します
  * 以下の情報が表示されます
    * 使用中のチャネル番号(常駐プロセスによって使用中のデバイスの場合)
    * デバイス ID
    * デバイスの VID, PID
    * デバイス名 (Product 文字列)
    * マニュファクチャ名 (Manufacturer 文字列が設定されている場合)
  * 実行例
    ```
    A>zusb
    #7 Device:262 0xcafe-0x4012 X68000 Z Remote Drive Device   (X68000 Z)
       Device:261 0x33dd-0x0011 ZUIKI X68000Z Keyboard         ( )
       Device:260 0x33dd-0x0013 X68000 Z JOYCARD(BLACK)
       Device:259 0x33dd-0x0012 ZUIKI X68000Z Mouse
    ```

* デバイス ID を指定すると、そのデバイスの詳細情報を表示します
  * 実行例
    ```
    A>zusb 261
    Device:261
     Device: USB:110 class:0 subclass:0 protocol:0 maxpacket:8 VID:0x33dd PID:0x0011 ver:6016
            Manufacturer:
            Product:      ZUIKI X68000Z Keyboard
      Configuration: #1 MaxPower:500mA
       Interface:    #0 class:3 subclass:1 protocol:1
        HID:         version:111 country:0 (type:0x22 size:67)
        Endpoint:    0x81 Interrupt MaxPacket:8
       Interface:    #1 class:3 subclass:0 protocol:0
        HID:         version:111 country:0 (type:0x22 size:125)
        Endpoint:    0x82 Interrupt MaxPacket:16
    ```

* `-v` オプションを付けると、ディスクリプタの内容を 16 進ダンプでも表示します
  * 実行例
    ```
    A>zusb -v 260
    ZUSB version:1.00
    Device:260
    12 01 00 02 00 00 00 40 dd 33 13 00 01 00 00 02 00 01
     Device: USB:200 class:0 subclass:0 protocol:0 maxpacket:64 VID:0x33dd PID:0x0013 ver:1
            Product:      X68000 Z JOYCARD(BLACK)
    09 02 29 00 01 01 00 80 fa
      Configuration: #1 MaxPower:500mA
    09 04 00 00 02 03 00 00 00
       Interface:    #0 class:3 subclass:0 protocol:0
    09 21 11 01 00 01 22 31 00
        HID:         version:111 country:0 (type:0x22 size:49)
    07 05 02 03 40 00 0a
        Endpoint:    0x02 Interrupt MaxPacket:64
    07 05 81 03 40 00 01
        Endpoint:    0x81 Interrupt MaxPacket:64
    ```

* `-r` オプションを付けると、HID デバイスのレポートディスクリプタの内容を表示します
  * レポートディスクリプタとは、HID デバイスがやり取りするデータのフォーマットを定義するデータです
  * zusb コマンドでは、レポートディスクリプタのうちデータの並びを定義している箇所のみを簡易的に表示します
    * `i` は入力、`o` は出力、`f` はフィーチャーレポート(デバイスの設定用)のそれぞれ1ビットのデータ
    * `II`、`OO`、`FF` は1バイトのデータを表します。
  * 実行例
    ```
    Device:260
     Device: USB:200 class:0 subclass:0 protocol:0 maxpacket:64 VID:0x33dd PID:0x0013 ver:1
            Product:      X68000 Z JOYCARD(BLACK)
      Configuration: #1 MaxPower:500mA
       Interface:    #0 class:3 subclass:0 protocol:0
        HID:         version:111 country:0 (type:0x22 size:49)
        Endpoint:    0x02 Interrupt MaxPacket:64
        Endpoint:    0x81 Interrupt MaxPacket:64
    
    HID Report
      Configuration:1 Interface:0 type:0x22 size:49
        ( 4 bytes) :iiiiiiii:----iiii:II:II
    ```
    * この例ではジョイカードが、
      * 1ビットのデータ × 8
      * 1ビットのデータ × 4 (上位4ビットは未使用)
      * 1バイトのデータ
      * 1バイトのデータ
    * といった構成のデータを送ってくることを示しています
    
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


## zusbjoyc - X68000 Z JOYCARD のテスト

###  使用方法

コマンドラインから以下のように実行します。

```
zusbjoyc.x [-s][-r]
```

以下のオプションを指定できます。

* -s\
  常駐します
* -r\
  常駐を解除します

### 説明

* 実行すると ZUIKI X68000 Z JOYCARD が接続されるのを待ちます
  * Z JOYCARD (VID:0x33dd PID:0x0013) 専用です。他のコントローラは非対応です。
* 接続すると、JOYCARD からの入力を 16進表示します。10 秒経つと終了します。
* -s オプションを指定すると常駐して、ジョイカードの入力をキー入力に変換します。
  * 十字キー: カーソルキー
  * A, B ボタン : A, B
  * RIGHT, LEFT ボタン : R, L
  * START, SELECT ボタン : S, E
* -r オプションを指定すると、常駐している zusbjoyc プロセスがいれば常駐解除します。
