# X-BASIC 外部関数 ZUSB.FNC ドキュメント

## 概要

ZUSB.FNC は X68000Z の ZUSB 機能を X-BASIC から利用するための外部関数です。

X-BASIC のあるディレクトリに ZUSB.FNC を置いて、コンフィグレーションファイル BASIC.CNF に

```
FUNC = ZUSB
```

という行を追加することで、使用できるようになります。

## 関数一覧

### zusb_open

* 書式
  * zusb_open([ch])
* 引数
  * char(ch) 省略可能
* 戻り値
  * int
* 機能
  * USB チャネルの利用を開始します。他の API に先立って実行する必要があります。
    * ch -- 使用したいチャネル番号 (0～7)
      * 通常は 0 を指定してください。省略すると 0 を指定したのと同じになります。
  * 戻り値として以下の値を返します。
    * 0 ～ 7: オープンできたチャネル番号
    * -1: エラー

### zusb_close

* 書式
  * zusb_close()
* 引数
  * なし
* 戻り値
  * int
* 機能
  * 利用中の USB チャネルをクローズします。
  * 戻り値として以下の値を返します。
    * 0: 正常終了
    * -1: エラー

### zusb_setch

* 書式
  * zusb_setch(ch)
* 引数
  * char(ch)
* 戻り値
  * int
* 機能
  * ZUSB 関数で使用する USB チャネルを選択します。
  * 指定するチャネル番号は、zusb_open() でオープンされたものである必要があります。
    * ch -- 使用したいチャネル番号 (0～7)
  * 戻り値として以下の値を返します。
    * 0: 正常終了
    * -1: エラー

### zusb_find

* 書式
  * zusb_find([devid], [vid], [pid], [mstr], [pstr], [sstr])
* 引数
  * int型変数 (devid, vid, pid) 省略可能
  * str型変数 (mstr, pstr, sstr) 省略可能
* 戻り値
  * int
* 機能
  * X68000 Z に接続されている USB デバイスを検索します。
    この関数を呼ぶたびに、各 USB デバイスの以下の情報を変数に返します。
    * devid -- USB デバイス ID
    * vid -- USB デバイスの Vendor ID
    * pid -- USB デバイスの Product ID
    * mstr -- USB デバイスの Manufacturer 文字列
    * pstr -- USB デバイスの Product 文字列
    * sstr -- USB デバイスの Serial 文字列
  * すべてのデバイスを検索し終えると 0 を返します。
    再度最初からデバイスの検索を行うには、zusb_rewind() を呼んでください。
  * 戻り値として以下の値を返します。
    * 1 以上の値: 見つかった USB デバイス ID
    * 0: これ以上 USB デバイスが見つからない
    * -1: エラー
* 用例
  ```
   10 int devid,vid,pid
   20 str pstr
   30 zusb_open()
   40 while zusb_find(devid,vid,pid,,pstr) > 0
   50   print devid,right$("000"+hex$(vid),4),right$("000"+hex$(pid),4),pstr
   60 endwhile
   70 zusb_close()
   80 end
  ```

### zusb_seek

* 書式
  * zusb_seek(devid)
* 引数
  * int(devid)
* 戻り値
  * int
* 機能
  * zusb_find() による USB デバイスの検索位置を指定したデバイス ID に移動します。
    * devid -- USB デバイス ID
  * 戻り値として以下の値を返します。
    * 1: 正常終了
    * 0: 指定したデバイス ID のデバイスが存在しない
    * -1: エラー

### zusb_rewind

* 書式
  * zusb_rewind()
* 引数
  * なし
* 戻り値
  * int
* 機能
  * zusb_find() による USB デバイスの検索を最初のデバイスに戻します。
  * 戻り値として以下の値を返します。
    * 0: 正常終了
    * -1: エラー

### zusb_getif

* 書式
  * zusb_getif([intf],[cls],[subc],[proto],[nep])
* 引数
  * int型変数 (intf,cls,subc,proto,nep) 省略可能
* 戻り値
  * int
* 機能
  * zusb_find() で検索した USB デバイスの持つインターフェースの情報を取得します
    この関数を呼ぶたびに、各インターフェースの以下の情報を変数に返します。
    * intf -- インターフェース番号
    * cls -- インターフェースのデバイスクラス
    * subc -- インターフェースのデバイスサブクラス
    * proto -- インターフェースのデバイスプロトコル
    * nep -- インターフェースの持つエンドポイント数
  * すべてのインターフェース情報を取得し終えると 0 を返します。
    再度最初からインターフェース情報の取得を行うには、zusb_seek() で USB デバイス ID を指定してください。
  * 戻り値として以下の値を返します。
    * 1: インターフェース情報を取得した
    * 0: すべてのインターフェース情報を取得し終えた
    * -1: エラー

### zusb_getep

* 書式
  * zusb_getep([epaddr],[dir],[xfer],[maxpkt])
* 引数
  * int型変数 (epaddr,dir,xfer,maxpkt) 省略可能
* 戻り値
  * int
* 機能
  * zusb_getif() で取得したインターフェースの持つエンドポイントの情報を取得します
    この関数を呼ぶたびに、各エンドポイントの以下の情報を変数に返します。
    * epaddr -- エンドポイントアドレス
    * dir -- エンドポイントの転送方向 (0:OUT 1:IN)
    * xfer -- エンドポイントの転送モード
      * 0:コントロール転送 1:アイソクロナス転送 2:バルク転送 3:インタラプト転送
    * maxpkt -- エンドポイントの最大パケットサイズ
  * すべてのエンドポイント情報を取得し終えると 0 を返します。
  * 戻り値として以下の値を返します。
    * 1 以上の値: エンドポイントアドレス
    * 0: すべてのエンドポイント情報を取得し終えた
    * -1: エラー

### zusb_connect

* 書式
  * zusb_connect(config,intf)
* 引数
  * int(connect,intf)
* 戻り値
  * int
* 機能
  * zusb_find() で検索した USB デバイスの指定したインターフェースに接続します。
    接続したデバイスにデータを読み書きするためには、zusb_bind() でエンドポイントをパイプに結び付ける必要があります。
    * config -- コンフィグレーション番号 (必ず 1 を指定してください)
    * intf -- インターフェース番号
  * 戻り値として以下の値を返します。
    * 0: 正常終了
    * -1: エラー

### zusb_disconnect

* 書式
  * zusb_disconnect()
* 引数
  * なし
* 戻り値
  * int
* 機能
  * 現在接続中の USB デバイスのすべてのインターフェースから切断します。
  * 戻り値として以下の値を返します。
    * 0: 正常終了
    * -1: エラー

### zusb_bind

* 書式
  * zusb_bind(epno,epaddr)
* 引数
  * char(epno)
  * int(epaddr)
* 戻り値
  * int
* 機能
  * zusb_connect() で接続したデバイスのエンドポイントをパイプに結び付けます。
    * epno -- パイプ番号 (0～7)
    * epaddr -- エンドポイントアドレス (zusb_getep() で得られる値)
  * 戻り値として以下の値を返します。
    * 0: 正常終了
    * -1: エラー

### zusb_control

* 書式
  * zusb_control(type,req,value,index,[len],[data])
* 引数
  * int(type,req,value,index)
  * int(len) 省略可能
  * 数値型一次元配列(data) 省略可能
* 戻り値
  * int
* 機能
  * zusb_find() で検索した USB デバイスにコントロール転送を発行します。
    * type --  リクエストタイプ (bmType)
    * req -- リクエスト番号 (bRequest)
    * value -- リクエスト値 (wValue)
    * index -- インデックス (wIndex)
    * len -- 転送するデータ長 (wLength: 省略時は0)
    * data -- 転送するデータを格納する数値型一次配列
  * 戻り値として以下の値を返します。
    * 0: 正常終了
    * -1: エラー
* 用例

### zusb_read

* 書式
  * zusb_read(data,len,epno,[pos])
* 引数
  * 数値型一次元配列(data)
  * int(len,pos)
  * char(epno)
* 戻り値
  * int
* 機能
  * パイプからデータを読み込みます。
    データが来るまで待ちます。
    * data -- 読み込んだデータを格納する数値型一次配列
    * len -- 読み込むデータ長
    * epno -- パイプ番号 (0～7)
    * pos -- データ読み込み時に使用する ZUSB バッファ領域内のオフセット
      * &h000～&H77F の値を指定します。省略すると 0 になります。
      * 複数のパイプに同時にデータを読み書きする場合は、それぞれのパイプが使用する ZUSB バッファが重ならないようにオフセットを指定してください。
  * 戻り値として以下の値を返します。
    * 0 以上の値: 正常終了 (実際に読み込んだデータ長)
    * -1: エラー

### zusb_write

* 書式
  * zusb_write(data,len,epno,[pos])
* 引数
  * 数値型一次元配列(data)
  * int(len,pos)
  * char(epno)
* 戻り値
  * int
* 機能
  * パイプにデータを書き込みます。
    書き込みが完了するまで待ちます。
    * data -- 書き込むデータが格納されている数値型一次配列
    * len -- 書き込むデータ長
    * epno -- パイプ番号 (0～7)
    * pos -- データ書き込み時に使用する ZUSB バッファ領域内のオフセット
      * &h000～&H77F の値を指定します。省略すると 0 になります。
      * 複数のパイプに同時にデータを読み書きする場合は、それぞれのパイプが使用する ZUSB バッファが重ならないようにオフセットを指定してください。
  * 戻り値として以下の値を返します。
    * 0 以上の値: 正常終了 (実際に書き込んだデータ長)
    * -1: エラー

### zusb_readasync

* 書式
  * zusb_readasync(data,len,epno,[pos])
* 引数
  * 数値型一次元配列(data)
  * int(len,pos)
  * char(epno)
* 戻り値
  * int
* 機能
  * パイプからデータを読み込みます。
    読み込み指示を出したらすぐに終了します。
  * 読み込んだデータは zusb_wait() を呼ぶと受け取ることができます。
    * data -- 読み込んだデータを格納する数値型一次配列
    * len -- 読み込むデータ長
    * epno -- パイプ番号 (0～7)
    * pos -- データ読み込み時に使用する ZUSB バッファ領域内のオフセット
      * &h000～&H77F の値を指定します。省略すると 0 になります。
      * 複数のパイプに同時にデータを読み書きする場合は、それぞれのパイプが使用する ZUSB バッファが重ならないようにオフセットを指定してください。
  * 戻り値として以下の値を返します。
    * 0: 正常終了
    * -1: エラー

### zusb_writeasync

* 書式
  * zusb_writeasync(data,len,epno,[pos])
* 引数
  * 数値型一次元配列(data)
  * int(len,pos)
  * char(epno)
* 戻り値
  * int
* 機能
  * パイプにデータを書き込みます。
    書き込み指示を出したらすぐに終了します。
  * zusb_wait() を呼ぶと書き込み処理が完了します。
    * data -- 書き込むデータが格納されている数値型一次配列
    * len -- 書き込むデータ長
    * epno -- パイプ番号 (0～7)
    * pos -- データ書き込み時に使用する ZUSB バッファ領域内のオフセット
      * &h000～&H77F の値を指定します。省略すると 0 になります。
      * 複数のパイプに同時にデータを読み書きする場合は、それぞれのパイプが使用する ZUSB バッファが重ならないようにオフセットを指定してください。
  * 戻り値として以下の値を返します。
    * 0: 正常終了
    * -1: エラー

### zusb_stat

* 書式
  * zusb_stat([epno])
* 引数
  * char(epno) 省略可能
* 戻り値
  * int
* 機能
  * zusb_readasync(), zusb_writeasync() による読み書きが終了したかどうかを調べます。
    * epno -- パイプ番号 (0～7)
  * 引数を省略すると、すべてのパイプの状態を bit0～bit7 に返します。
    bit0～bit7 が パイプ 0 ～ 7 に対応しています。それぞれのビットが 0 なら読み書き中、1 なら読み書き終了です。
  * zusb_stat() によって読み書きの終了を確認した後は、必ず zusb_wait() でその結果を受け取ってください。
  * 戻り値として以下の値を返します。
    * epnoを省略した場合
      * 0 以上の値: 各パイプの状態を示すバイト値
      * -1: エラー
    * epnoを指定した場合
      * 1: 指定したパイプの読み書きが完了した
      * 0: 指定したパイプは読み書き中
      * -1: エラー

### zusb_wait

* 書式
  * zusb_wait(epno)
* 引数
  * char(epno)
* 戻り値
  * int
* 機能
  * zusb_readasync(), zusb_writeasync() による読み書きの終了を待ってその結果を受け取ります。
    * epno -- パイプ番号 (0～7)
  * 戻り値として以下の値を返します。
    * 0 以上の値: 正常終了 (実際に読み書きしたデータ長)
    * -1: エラー
