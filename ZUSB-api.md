# ZUSB API ドキュメント

ZUSB による USB デバイス制御のための API について説明します。

`#include <zusb.h>` でヘッダをインクルードすることで利用できます。

## グローバル変数

* struct zusb_regs *zusb;
  * 説明
    * ZUSB レジスタ構造体へのポインタです。
    * zusb_init() または zusb_init_protected() で初期化されます。

* uint8_t *zusbbuf;
  * 説明
    * ZUSB の USB バッファ領域へのポインタです。
    * zusb_init() または zusb_init_protected() で初期化されます。

## チャネル初期化 API

* int zusb_init(void);
  * 説明
    * チャネルの利用を開始します。他の API に先立って実行する必要があります。
  * 引数
    * なし
  * 返り値
    * 0 - 3: オープンできたチャネル番号
    * -1: ZUSB デバイスが存在しない
    * -2: オープン可能な空きチャネルがない

* int zusb_init_protected(void);
  * 説明
    * チャネルを保護モードで利用開始します。常駐プログラムからの利用を想定しています。
  * 引数
    * なし
  * 返り値
    * 0 - 3: オープンできたチャネル番号
    * -1: ZUSB デバイスが存在しない
    * -2: オープン可能な空きチャネルがない

* void zusb_close(void)
  * 説明
    * チャネルの利用を終了します。
  * 引数
    * なし
  * 返り値
    * なし

* int zusb_version(void)
  * 説明
    * ZUSB のバージョン番号を取得します。
  * 引数
    * なし
  * 返り値
    * -1: ZUSB デバイスが存在しない
    * それ以外: バージョン番号

## デバイス検索 API

* int zusb_find_device_with_vid_pid(int vid, int pid, int pdev);
  * 説明
    * ベンダ ID vid、プロダクト ID pid に一致するデバイスを検索します。
    * 合致するデバイスが複数存在する場合、pdev で指定したデバイス ID 以降のデバイスを検索します。最初は pdev に 0 を指定して呼び出し、デバイスが見つからなくなる(返り値が0) になるまで繰り返して呼び出すことで、すべてのデバイス ID を取得できます。
  * 引数
    * vid: ベンダ ID
    * pid: プロダクト ID
    * pdev: 検索を開始するデバイス ID (最初から検索する場合は 0)
  * 返り値
    * -1: コマンド実行中にエラーが発生した
    * 0: 該当するデバイスが見つからなかった
    * それ以外: 見つかった USB デバイスのデバイス ID

* int zusb_find_device_with_devclass(int devclass, int subclass, int protocol, int pdev);
  * 説明
    * 指定したデバイスクラス devclass、サブクラス subclass、プロトコル protocol のインターフェースを持つデバイスを検索します。
    * 合致するデバイスが複数存在する場合、pdev で指定したデバイス ID 以降のデバイスを検索します。最初は pdev に 0 を指定して呼び出し、デバイスが見つからなくなる(返り値が0) になるまで繰り返して呼び出すことで、すべてのデバイス ID を取得できます。
  * 引数
    * devclass: デバイスクラス (-1 なら判定に利用しない)
    * subclass: サブクラス (-1 なら判定に利用しない)
    * protocol: プロトコル (-1 なら判定に利用しない)
    * pdev: 検索を開始するデバイス ID (最初から検索する場合は 0)
  * 返り値
    * -1: コマンド実行中にエラーが発生した
    * 0: 該当するデバイスが見つからなかった
    * それ以外: 見つかった USB デバイスのデバイス ID

* int zusb_find_device(zusb_match_func *fn, void *arg, int pdev);
  * 説明
    * 接続されているすべての USB デバイスについて、ディスクリプタを 1 つずつ取得して判定関数を呼びます。判定関数が 1 を返すと、そのディスクリプタを提供しているデバイスのデバイス ID を関数の返り値とします。
  * 引数
    * fn: デバイスの判定を行う以下の関数へのポインタ
      * int fn(int devid, int type, uint8_t *desc, void *arg);
        * 引数
          * devid: デバイス ID
          * type: ディスクリプタの種類
          * desc: ディスクリプタへのポインタ
          * arg: zusb_find_device() に渡した arg
        * 返り値
          * 0: デバイスが見つからない
          * 1: デバイスが見つかった
    * arg: 判定関数に渡す引数
    * pdev: 検索を開始するデバイス ID (最初から検索する場合は 0)
  * 返り値
    * -1: コマンド実行中にエラーが発生した
    * 0: 該当するデバイスが見つからなかった
    * それ以外: 見つかった USB デバイスのデバイス ID

## デバイス接続 API

* int zusb_connect_device(int devid, int config, int devclass, int subclass, int protocol, zusb_endpoint_config_t epcfg[ZUSB_N_EP]);
  * 説明
    * 指定したデバイス ID のデバイスが持つ特定のコンフィグレーション番号の、特定のデバイスクラス、サブクラス、プロトコルを持つインターフェースに接続します。
    * 接続後、接続したインターフェースが持つエンドポイントが利用できるように ZUSB のパイプコンフィグレーションレジスタを設定します。
  * 引数
    * devid: デバイス ID
    * config: コンフィグレーション番号 (現状、コンフィグレーション 1 以外は使用できないため 1 を指定してください)
    * devclass: デバイスクラス (-1 なら判定に利用しない)
    * subclass: サブクラス (-1 なら判定に利用しない)
    * protocol: プロトコル (-1 なら判定に利用しない)
    * epcfg: エンドポイント情報を格納する以下の構造体配列へのポインタ
      * zusb_endpoint_config_t epcfg[8];
      * zusb_endpoint_config_t 型は以下のメンバを持ちます。
        * uint8_t address: エンドポイントアドレス
        * uint8_t attribute: エンドポイント属性
        * uint16_t maxpacketsize: 最大パケットサイズ
  * 返り値
    * 接続したインターフェースの個数
  * 補足説明
    * エンドポイント情報は、0 から 7 の 8 つのエンドポイントのそれぞれについて、接続したインターフェースのどのエンドポイントと結びつけるのかを設定して渡します。
      * address にはエンドポイントの転送方向 ZUSB_DIR_IN または ZUSB_DIR_OUT のいずれかを指定しておきます
      * attribute にはエンドポイントの転送モード ZUSB_EP_TYPE_CONTROL, ZUSB_EP_TYPE_ISOCHRONOUS, ZUSB_EP_TYPE_BULK, ZUSB_EP_TYPE_INTERRUPT のいずれかを指定しておきます
      * maxpacketsize は 0 で初期化しておきます。必要なエンドポイントが 8 個より少ない場合は、maxpacketsize に -1 を設定するとそれ以降のエンドポイントは検索しません。
    * 呼び出し後は、実際に結びつけられたしたエンドポイントの情報が返ります。
      * address, attribute には実際のエンドポイントの情報が設定されます
      * maxpacketsize にはそのエンドポイントの最大パケットサイズが設定されます

* void zusb_disconnect_device(void);
  * 説明
    * USB デバイスのインターフェースへの接続をすべて切断します。
  * 引数
    * なし
  * 返り値
    * なし

## ユーティリティ API

* void zusb_set_region(void *buf, int count);
  * 説明
    * コントロール転送のために、バッファアドレスと長さをレジスタに設定します。
  * 引数
    * buf: データ転送を行うバッファのアドレス (USB バッファ領域内)
    * count: バッファの長さ
  * 返り値
    * なし

* void zusb_set_ep_region(int epno, void *buf, int count);
  * 説明
    * エンドポイントパイプのデータ転送のために、バッファアドレスと長さをレジスタに設定します。
  * 引数
    * epno: エンドポイントパイプ番号 (0 から 7)
    * buf: データ転送を行うバッファのアドレス
    * count: バッファの長さ
  * 返り値
    * なし

* void zusb_set_ep_region_isoc(int epno, void *buf, struct zusb_isoc_desc *desc, int count);
  * 説明
    * エンドポイントパイプのアイソクロナスデータ転送のために、バッファアドレスとアイソクロナスディスクリプタテーブルアドレス、ディスクリプタのエントリ数をレジスタに設定します。
  * 引数
    * epno: エンドポイントパイプ番号 (0 から 7)
    * buf: データ転送を行うバッファのアドレス
    * desc: アイソクロナスディスクリプタテーブルのアドレス
    * count: アイソクロナスディスクリプタテーブルのエントリ数
  * 返り値
    * なし

* int zusb_send_cmd(int cmd);
  * 説明
    * 使用中のチャネルにコマンドを送信します。
    * 同期コマンドの場合は実行終了まで待ちます。
  * 引数
    * cmd: コマンドコード
  * 返り値
    * 0: コマンド送信成功
    * -1: コマンドでエラーが発生した

* int zusb_send_control(int bmRequestType, int bRequest, int wValue, int wIndex, int wLength, void *data);
  * 説明
    * 使用中のチャネルにコントロール転送を行います。
  * 引数
    * bmRequestType: デバイスリクエストの bmRequestType
    * bRequest: デバイスリクエストの bRequest
    * wValue: デバイスリクエストの wValue
    * wIndex: デバイスリクエストの wIndex
    * wLength: デバイスリクエストの wLength
    * data: データ転送を行うバッファのアドレス
  * 返り値
    * -1: コマンドでエラーが発生した
    * その他: 転送したデータサイズ

* int zusb_get_descriptor(uint8_t *buf);
  * 説明
    * USB デバイスのディスクリプタを 1 つ取得します。
    * ディスクリプタは 長さ + データ本体で構成されるため、まず 1 バイトの長さを取得し、その後データ本体を取得します。
  * 引数
    * buf: ディスクリプタを格納するバッファ (USB バッファ領域内。最大 256 バイト使用します)
  * 返り値
    * 0: もうディスクリプタがない
    * -1: コマンドでエラーが発生した
    * それ以外: 取得できたディスクリプタの長さ

* void zusb_rewind_descriptor(void);
  * 説明
    * zusb_get_descriptor() で取得するディスクリプタを先頭に戻します。
    * zusb_get_descriptor() は呼び出すたびにディスクリプタを順次取得して行きますが、この API を呼ぶことでデバイスの最初のディスクリプタから再度取得するようになります。
  * 引数
    * なし
  * 返り値
    * なし

* int zusb_get_string_descriptor(char *str, int len, int index);
  * 説明
    * USB デバイスのストリングディスクリプタを取得します。
    * ストリングディスクリプタの文字列は Unicode (UTF-16LE) で格納されていますが、結果は char * 文字列に変換して返します。
    * ASCII の範囲内の文字コードのみに対応しています。ディスクリプタ取得時の Language ID は 0x0409 (English) に固定です。
  * 引数
    * str: 取得した文字列を格納するバッファ
    * len: バッファの長さ
    * index: ストリングディスクリプタのインデックス
  * 返り値
    * 0: 該当するインデックスのディスクリプタがない
    * -1: エラー
    * それ以外: 取得できたディスクリプタの長さ
