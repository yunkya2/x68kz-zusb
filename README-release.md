# X68000 Z ZUSB 関連ツール & 仕様ドキュメント (GIT_REPO_VERSION)

Copyright (c) 2025 Yuichi Nakamura (@yunkya2)

URL: https://github.com/yunkya2/x68kz-zusb

## 概要

これは X68000 Z の ZUSB 機能を用いた関連ツールと ZUSB の仕様ドキュメントです。

ZUSB は X68000 Z の USB 端子に接続されている USB デバイスを X68000 エミュレータ上から扱うための仮想的な USB デバイスコントローラです。

通常の X68000 Z では、キーボード、マウス、ジョイパッド、マスストレージ(USBメモリ) といったエミュレータで対応している USB デバイスのみが利用可能ですが、ZUSB を用いるとエミュレートされているX68000 側から USB デバイスが直接見えるようになるので、ドライバさえ用意できればどんな USB デバイスも利用できるようになります。

HACKER'S EDITION 上で ZUSB 対応を有効にしたエミュレータを使用して起動した X68000 システム上で実行することで、X68000 Z に接続したUSBデバイスを直接操作できます。


## ディレクトリ構成

* README.txt -- このファイル
* bin/ -- ZUSB 関連ツール
  * zusb.x -- USB 機器の情報表示
  * zusbaudio.x -- USB Audio デバイスのテスト
  * zusbcdplay.x -- USB CD-ROM + USB Audio による音楽再生
  * zusbfdformat.x -- USB FDD フォーマッタ
  * zusbhid.x -- USB HID デバイスのテスト
  * zusbjoyc -- X68000 Z JOYCARD のテスト
  * zusbmsc.x -- USB MSC デバイスのテスト
  * zusbvideo.x -- USB Video デバイスのテスト
* sys/ -- ZUSB 関連デバイスドライバ
  * zusbether.x -- USB LAN アダプタドライバ
  * zusbfddrv.sys -- USB FDD ドライバ
  * zusbmodrv.sys -- USB MO ドライバ
  * zusbscsi.sys -- USB SCSI IOCS ドライバ
* doc/ -- ツールやデバイスドライバのドキュメント
  * zusbtools.txt
  * zusbether.txt
  * zusbfddrv.txt
  * zusbscsi.txt
  * zusbvideo.txt
* sdk/ -- ZUSB 対応アプリケーション開発用ファイル & サンプル
  * doc/ -- ZUSB 仕様ドキュメント
    * ZUSB-api.txt -- ZUSB API 仕様
    * ZUSB-specs.txt -- ZUSB レジスタ仕様
    * ZUSB-basic.txt -- X-BASIC 用 ZUSB 外部関数仕様
  * cross/ -- クロス開発環境 [elf2x68k](https://github.com/yunkya2/elf2x68k) 用ヘッダファイル & サンプル
    * include/
  * xc/ -- XC 用ヘッダファイル、ライブラリ & サンプル
    * include/
    * lib/
  * basic/ -- X-BASIC 用外部関数、サンプル


## 対応デバイス

現在、ZUSB は以下のような USB デバイスに対応しています。

* HID (ヒューマンインターフェースデバイス)
  * キーボード/マウス/ジョイパッド 等
* MSC (マスストレージクラスデバイス)
  * USB FDドライブ   ※コピープロテクトのかかったメディアには非対応
  * USB MOドライブ
  * USB CD-ROMドライブ
* UAC (USBオーディオクラスデバイス)
  * USBオーディオアダプタ  (44.1k/48kHz 16bit stereo PCM再生)
* UVC (USBビデオクラスデバイス)
  * QQVGA(160×120), QVGA(320×240) が扱えるUSBカメラ
  * 非圧縮と MotionJPEG に対応
  * (ELECOM UCAM-C0220FBBK, UCAM-C310FBBKでのみ動作を確認)
* USB LANアダプタ
  * BUFFALO LUA3-U2-ATX 専用
* リモートドライブ
  * Raspberry Pi Pico Wを使用してSMBのネットワーク共有ドライブに接続 ([x68kzremotedrv](https://github.com/yunkya2/x68kzremotedrv/))


## USB デバイス接続時の注意点

X68000 Z の USB ポートにデバイスを接続する場合、以下のような点に注意してください。
接続したデバイスが認識されなかったり正常動作しなかったりする際は、接続のやり方を変えることで状況が改善されることがあります。

* X68000 Z の USB ポートからはあまり大きな電力を取ることができないので、消費電力の大きな USB デバイス (USB CD-ROMドライブなど) をバスパワーで動かすと正常動作しない可能性があります。
   そのような機器を使用する場合、別途電源供給用端子ががある場合は極力それを使用するか、セルフパワーの USB ハブを繋いでその先にデバイスを繋ぐようにしてください。
* ハブの先に更にハブを繋いで接続機器を増やすような使い方(カスケード接続)をすると、X68000 Z の USB ポートで機器を正常に認識できない場合があるようです。特に複数の機能を持つ USB 機器は内部的に USB ハブ機能を持っていることがあるため、多段接続するつもりがなくてもそうなってしまう場合があります。
   こうした機器は、ハブを介さずに本体の USB ポートに直接接続するようにしてください (前項と矛盾してますが…)。
