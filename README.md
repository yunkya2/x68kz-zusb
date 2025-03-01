# X68000 Z ZUSB 関連ツール & 仕様ドキュメント

## 概要

これは X68000 Z エミュレータの ZUSB 機能を用いた関連ツールと ZUSB の仕様ドキュメントのリポジトリです。

HACKER'S EDITION 上で ZUSB 対応を有効にしたエミュレータを使用して
起動した X68000 システム上で実行することで、X68000 Z に接続したUSBデバイスを直接操作できます。

## ZUSB 仕様

* [ZUSB レジスタ仕様](ZUSB-specs.md)
* [ZUSB API 仕様](ZUSB-api.md)

## 関連ツール

* [ZUSB サンプルアプリ](src/README.md)
  * zusb.x - USB 機器の情報表示
  * zusbhid.x - USB HID デバイスのテスト
  * zusbmsc.x - USB MSC デバイスのテスト
  * zusbaudio.x - USB Audio デバイスのテスト
  * zusbcdplay.x - USB CD-ROM ドライブと USB Audio デバイスを用いた音楽再生
* [zusbvideo - USB Video デバイステストアプリ](zusbvideo/README.md)
* [zusbfddrv - USB FDD ドライバ](zusbfddrv/README.md)
* [zusbscsi - USB SCSI IOCS ドライバ](zusbscsi/README.md)
* [zusbether - USB LAN アダプタドライバ](zusbether/README.md)

## ビルド方法

サンプルコードのビルドには [elf2x68k](https://github.com/yunkya2/elf2x68k) が必要です。
リポジトリのトップディレクトリ内で `make` を実行するとビルドできます。

## ライセンス

本リポジトリに含まれるソースコードはすべて MIT ライセンスとします。

