# ZUSB レジスタ仕様ドキュメント

## 概要

ZUSB は X68000 Z の USB 端子に接続されている USB デバイスを X68000 エミュレータ上から扱うための仮想的な USB デバイスコントローラです。

通常の X68000 Z では、キーボード、マウス、ジョイパッド、マスストレージ(USBメモリ) といったエミュレータで対応している USB デバイスのみが利用可能ですが、ZUSB を用いるとエミュレートされているX68000 側から USB デバイスが直接見えるようになるので、ドライバさえ用意できればどんな USB デバイスも利用できるようになります。

## 用語

#### チャネル
  ZUSB が USB デバイス との接続を行う単位をチャネルと呼びます。\
  ZUSB は 0～7 の 8 個のチャネルを持ち、それぞれのチャネルは独立して動作します。

#### デバイスID
   X68000 Z に接続されている個々の USB デバイスを識別するための ID です (16bit 値)。\
   USB ポート位置などには依存しません。 USB デバイスを X68000 Z に接続するたびに新たな ID が割り当てられます。

#### (エンドポイント)パイプ
  ZUSB が USB デバイスが持つエンドポイントに対してデータの送受信を行うインターフェースを(エンドポイント)パイプと呼びます。\
  ZUSB は各チャネルごとに 0～7 の 8 個のパイプを持ちます。\
  USB デバイスはデバイスごとに IN 16個、OUT 16個の最大 32 個のエンドポイントを持つことができますが、ZUSB ではその中から 8 個を選択してパイプに割り当て、そのパイプが X68000 のメモリとの間でデータのやり取りを行います。\
  USB でコントロールパイプとして扱われるエンドポイント 0 は、パイプを使わずに直接データを送受信することもできます。

#### USB バッファ領域
  ZUSB のアドレス空間上に割り当てられた USB 通信専用のバッファ領域です。\
  各チャネルごとに 4kB - 128 = 3968 バイトの領域を持ちます。\
  USB デバイス接続時に行うディスクリプタの読み出し、コントロール/インタラプト/バルク転送によるエンドポイントとの通信には USB バッファ領域を使用します。\
  USB バッファ領域上のアドレスは、該当チャネルのアドレス領域先頭からのオフセットで表します (16bit 値)。\
  チャネルの先頭 128 バイトにはレジスタ領域が割り当てられているため、アドレスとして有効な値の範囲は $0080～$0FFF (128～4095) となります。

#### 拡張アドレス領域
  ZUSB から見た X68000 のメインRAM領域(アドレス $000000～$BFFFFF)を拡張アドレス領域と呼びます。\
  USB のアイソクロナス転送では、データの転送先として拡張アドレス領域を使用します。\
  X68000 エミュレータの仕様により、USB デバイスと拡張アドレス領域との間でデータをやり取りすると 16 ビット単位でデータのエンディアンが逆転することに注意が必要です。
  * X68000 メイン RAM に置かれた $00 $01 $02 $03 というデータは、USB デバイスには $01 $00 $03 $02 というデータとして送信されます。USB デバイスからのデータ受信時にも同様にエンディアンが逆転します。
  * USB バッファ領域との間のデータ転送では、このようなエンディアン逆転は発生しません。

#### アイソクロナスディスクリプタテーブル
  ZUSB がアイソクロナス転送を行う際に、USBの 1 フレーム(1ms) (ハイスピード以上のデバイスでは 1 マイクロフレーム(125us)) ごとに送受信するデータ量を記述したテーブルをアイソクロナスディスクリプタテーブルと呼びます。\
  テーブルは 1 エントリあたり 4 バイトから構成され、以下のような構造を持ちます。

  オフセット | データ
  ----------|---------
  +0.w      | 1 フレーム(マイクロフレーム) 中に送受信するデータ長 (バイト数)
  +2.w      | 実際に送受信したデータ長 (バイト数)

  (ここで指定する値は、X68000 から見た通常の16bit値(ビッグエンディアン)となります)\
  ユーザは送受信開始前に各エントリのオフセット +0 の 1 ワードを設定しておくと、終了後に各エントリのオフセット +2 の 1 ワードに実際に送受信したデータのバイト数が書き込まれます。\
  他の転送モードとは異なり、アイソクロナス転送でエンドポイントパイプのデータ転送を行う際には、事前に拡張アドレス領域に用意したアイソクロナスディスクリプタテーブルの先頭アドレスとそのテーブルのエントリ数を指定します。\
  実際に送受信されるデータの先頭アドレスはパイプデータアドレスレジスタで設定します。

#### 同期コマンド 
  ZUSB の各チャネルの制御は、各チャネルの持つコマンドレジスタにコマンドコードを書き込むことで行われます。このコマンドには同期コマンドと非同期コマンドがあります。\
  同期コマンドは、コマンドコードの bit 7 が 0 のコマンドで、コマンド発行ごとにその実行完了を待つ必要があります。\
  コマンドの実行完了はステータスレジスタのBUSYビットによって知ることができます。\
  このビットが 1 の間は送られたコマンドを実行中で、0 になるまで次のコマンドを実行することはできません。\
  コマンドの実行完了はステータスレジスタのCOMPLETEビットで知ることもできます。\
  このビットはコマンドが実行完了するごとに 0->1 と値が変わるため、割り込みイネーブルレジスタでこのビットの割り込みを有効にすることで、コマンド実行完了時に割り込みが発生するようになります。

#### 非同期コマンド 
  非同期コマンドはコマンドコードの bit 7 が 1 のコマンドです。\
  コマンドの発行後、その実行完了を待たずに他のコマンドの実行が可能です。\
  非同期コマンドは、エンドポイントパイプへのデータ送受信コマンドとそのキャンセルコマンドで使われます。\
  コマンドの実行完了はステータスレジスタの PnCOMPLETE (n=0～7) ビットの立ち上がりで知ることができ、このビットの割り込みイネーブルを 1 にすることで実行完了時に割り込みが発生するようになります。

## 使用リソース

ZUSB は X68000 の以下のリソースを使用します。

### アドレスマップ

ZUSB は、X68000 の以下のアドレス領域を使用します。

アドレス範囲       |サイズ      |用途
------------------|----------:|----------------------
$EC0000 - $EC007F |  128バイト | チャネル0 制御レジスタ
$EC0080 - $EC0FFF | 3968バイト | チャネル0 USB バッファ
$EC1000 - $EC107F |  128バイト | チャネル1 制御レジスタ
$EC1080 - $EC1FFF | 3968バイト | チャネル1 USB バッファ
$EC2000 - $EC207F |  128バイト | チャネル2 制御レジスタ
$EC2080 - $EC2FFF | 3968バイト | チャネル2 USB バッファ
$EC3000 - $EC307F |  128バイト | チャネル3 制御レジスタ
$EC3080 - $EC3FFF | 3968バイト | チャネル3 USB バッファ
$EC4000 - $EC407F |  128バイト | チャネル4 制御レジスタ
$EC4080 - $EC4FFF | 3968バイト | チャネル4 USB バッファ
$EC5000 - $EC507F |  128バイト | チャネル5 制御レジスタ
$EC5080 - $EC5FFF | 3968バイト | チャネル5 USB バッファ
$EC6000 - $EC607F |  128バイト | チャネル6 制御レジスタ
$EC6080 - $EC6FFF | 3968バイト | チャネル6 USB バッファ
$EC7000 - $EC707F |  128バイト | チャネル7 制御レジスタ
$EC7080 - $EC7FFF | 3968バイト | チャネル7 USB バッファ

### 割り込み

ZUSB は、データ転送の終了や接続状態の変化を割り込みで通知することができます。
割り込みは各チャネルごとに異なったベクタを使用します。
デフォルトではそれぞれ以下のベクタ番号を使用しますが、ベクタ設定コマンド(SETIVECT)によって番号を変更することもできます。

チャネル番号|ベクタ番号
-----------|---------
0          | $D0
1          | $D1
2          | $D2
3          | $D3
4          | $D4
5          | $D5
6          | $D6
7          | $D7

ZUSB の割り込みレベルは 2 を使用します。

## レジスタ一覧

ZUSB の各チャネルの制御レジスタの一覧を以下に示します。\
レジスタアドレスは各チャネルの制御レジスタ先頭アドレスからのオフセットで表します。

```
     +$0      +$2      +$4      +$6      +$8      +$A      +$C      +$E
+$00 [CMD    ][ERR    ] -------  ------- [STAT   ][INTEN  ] -------  ------- 
+$10 [CCOUNT ][CADDR  ] -------  ------- [DEVID  ][PARAM  ][VALUE  ][INDEX  ]
+$20 [P0CFG  ][P1CFG1 ][P2CFG  ][P3CFG  ][P4CFG  ][P5CFG  ][P6PCFG ][P7CFG  ]
+$30 [P0COUNT][P1COUNT][P2COUNT][P3COUNT][P4COUNT][P5COUNT][P6COUNT][P7COUNT]
+$40 [P0ADDR          ][P1ADDR          ][P2ADDR          ][P3ADDR          ]
+$50 [P4ADDR          ][P5ADDR          ][P6ADDR          ][P7ADDR          ]
+$60 [P0DADDR         ][P1DADDR         ][P2DADDR         ][P3DADDR         ]
+$70 [P4DADDR         ][P5DADDR         ][P6DADDR         ][P7DADDR         ]
```

レジスタは、パイプ転送アドレスレジスタ(PnADDR)とアイソクロナス転送データアドレスレジスタ(PnDADDR)のみ 32 ビットレジスタで、それ以外のレジスタはすべて 16 ビットです。\
レジスタへのCPU からのアクセスはワード単位で行う必要があります。

#### CMD -- コマンドレジスタ (オフセット +$00)
  このレジスタを読むと常に固定の値 $5A55 ('ZU') が読み出されます。\
  この値をチェックすることで ZUSB デバイスの存在確認に利用できます。\
  このレジスタへの書き込みによって、チャネルがコマンド実行を開始します。\
  コマンドが同期コマンド (bit7=0) の場合、書き込み前に後述のステータスレジスタの BUSY ビットが 0 になっている必要があります。BUSY ビットが 1 の間に同期コマンドの書き込みを行うとエラーが発生します。

#### ERR -- エラーコードレジスタ (オフセット +$02)
  コマンド実行でエラーが発生した場合に、その要因(エラーコード)がこのレジスタに設定されます\
  ステータスレジスタの ERROR ビットを 0 にすると、このレジスタの値が $0000 にクリアされます

#### STATUS -- ステータスレジスタ (オフセット +$08)

  このレジスタを読むとチャネルのステータスを取得できます。\
  このレジスタへの書き込みは、bit 10～0 については 1 を書き込んだステータスがクリアされます。bit 15～12 はレジスタ書き込みの影響を受けません。

  ビット番号|名前      |意味
  --------:|----------|---
  15       |INUSE     |このチャネルが利用中であることを示します (OPENCH/OPENCHP コマンドの実行で 1 になる)。INUSE=0 のチャネルは OPENCH/OPENCHP 以外のコマンドを受け付けず、ステータスレジスタの値も $0000 から変化しません
  14       |PROTECTED |このチャネルが保護されていることを示します (OPENCHP コマンドで使用を開始した)
  13       |CONNECTED |このチャネルがデバイスに接続されていることを示します。CONNECT コマンドの実行が完了すると 1 になります。CONNECTED=0 のチャネルは エンドポイントパイプレジスタやUSB バッファ領域へのアクセスができません。
  12       |BUSY      |このチャネルで発行した同期コマンドの実行中に 1 になります。実行完了すると 0 に戻ります。
  11       |---       |---
  10       |HOTPLUG   |USB デバイスの接続状態に変化があると(デバイスが外されたor繋がれた) 1 になります。
   9       |ERROR     |発行したコマンドがエラーになると 1 になります。この際、エラーの要因がERRレジスタに設定されます。
   8       |COMPLETE  |発行した同期コマンドの実行が完了する (BUSYビットが 1->0になる) と 1 になります。
   7       |P7COMPLETE|エンドポイントパイプ 7 のコマンド実行が完了すると 1 になります。
   6       |P6COMPLETE|エンドポイントパイプ 6 のコマンド実行が完了すると 1 になります。
   5       |P5COMPLETE|エンドポイントパイプ 5 のコマンド実行が完了すると 1 になります。
   4       |P4COMPLETE|エンドポイントパイプ 4 のコマンド実行が完了すると 1 になります。
   3       |P3COMPLETE|エンドポイントパイプ 3 のコマンド実行が完了すると 1 になります。
   2       |P2COMPLETE|エンドポイントパイプ 2 のコマンド実行が完了すると 1 になります。
   1       |P1COMPLETE|エンドポイントパイプ 1 のコマンド実行が完了すると 1 になります。
   0       |P0COMPLETE|エンドポイントパイプ 0 のコマンド実行が完了すると 1 になります。

#### INTEN -- 割り込みイネーブルレジスタ (オフセット +$0A)
  ステータスレジスタ (STATUS) の値による割り込みを有効にするレジスタです。
  このレジスタのビットを 1 にすると、STATUS レジスタの対応するビットが 1 の時に CPU に割り込みが発生します。

#### CCOUNT -- コントロール転送カウントレジスタ (オフセット +$10)
  USB デバイスのディスクリプタ取得や接続後のコントロール転送で送受信するデータのサイズを指定します。
  このレジスタへの書き込みにより、送受信するデータサイズを指定します。
  送受信完了後にレジスタを読み込むと、実際に送受信されたデータのサイズが得られます。

#### CADDR -- コントロール転送アドレスレジスタ (オフセット +$12)
  USB デバイスのディスクリプタ取得や接続後のコントロール転送で送受信するデータのアドレスを指定します。
  アドレスは、該当チャネルの USB バッファ領域先頭からのオフセットを指定します。
  レジスタの下位 12bit のみが有効で、設定可能な値の範囲は $080～$FFF (128～4095) となります。

#### DEVID -- デバイスIDレジスタ (オフセット +$18)
  チャネルが接続している USB デバイスのデバイス ID を保持するレジスタです。

#### PARAM -- コマンドパラメータレジスタ (オフセット +$1A)
  各コマンド実行時のパラメータを指定するレジスタです。パラメータの意味は実行するコマンドによって変わります。

#### VALUE -- wValue レジスタ (オフセット +$1C)
  デバイスへコントロール転送を行うコマンド (CONTROL) で、wValue フィールドの値を指定するレジスタです。\
  USB プロトコルで用いられる値はリトルエンディアンであるため、コントロール転送のリクエストをメモリ上に置く場合の各フィールドの値もリトルエンディアンとなるのですが、このレジスタへ設定する値は通常のビッグエンディアン 16bit 値となることに注意が必要です。

#### INDEX -- wIndex レジスタ (オフセット +$1E)
  デバイスへコントロール転送を行うコマンド (CONTROL) で、wIndex フィールドの値を指定するレジスタです。\
  USB プロトコルで用いられる値はリトルエンディアンであるため、コントロール転送のリクエストをメモリ上に置く場合の各フィールドの値もリトルエンディアンとなるのですが、このレジスタへ設定する値は通常のビッグエンディアン 16bit 値となることに注意が必要です。

---

以下はエンドポイントパイプの設定を行うレジスタです、n にはエンドポイントパイプ番号 (0～7) を指定します。

#### PnCFG --  パイプn コンフィグレーションレジスタ (オフセット +$20+n*2)
  エンドポイントパイプ n の接続先となるエンドポイント番号や転送モードを指定します。

  ビット番号|名前  |意味
  --------:|------|---
  15       |INOUT |エンドポイントの転送方向 (0=OUT / 1=IN)
  11 - 8   |EPNO  |エンドポイント番号 (0～15)
   1 - 0   |MODE  |転送モード (00:コントロール転送 / 01:アイソクロナス転送 / 10:バルク転送 / 11:インタラプト転送)

#### PnCOUNT -- パイプn 転送カウントレジスタ (オフセット +$30+n*2)
  エンドポイントパイプ n で送受信するデータのサイズを指定します。パイプの転送モードによって値の意味が変わります。
  - コントロール/インタラプト/バルク転送
    - このレジスタへの書き込みにより、送受信するデータサイズを指定します。
      送受信完了後にレジスタを読み込むと、実際に送受信されたデータのサイズが得られます。
  - アイソクロナス転送
    - このレジスタへの書き込みにより、転送に使用するアイソクロナスディスクリプタテーブルのエントリ数を指定します。
      レジスタを読み込むと、まだ転送が完了していないエントリ数が得られます。転送が進むにつれて値が減っていき、送受信が完了すると 0 となります。

#### PnADDR -- パイプn 転送アドレスレジスタ (オフセット +$40+n*4)
  エンドポイントパイプ n で送受信するデータのアドレスを指定します。パイプの転送モードによって値の意味が変わります。
  - コントロール/インタラプト/バルク転送
    - 該当チャネルの USB バッファ領域先頭からのオフセットを指定します。
      レジスタの下位 12bit のみが有効で、設定可能な値の範囲は $080～$FFF (128～4095) となります。
  - アイソクロナス転送
    - 転送に使用するアイソクロナスディスクリプタテーブルの先頭アドレス (拡張アドレス領域) を 32bit で指定します。

  このレジスタは 32bit 幅です。

#### PnDADDR -- パイプn アイソクロナス転送データアドレスレジスタ (オフセット +$60+n*4)
  エンドポイントパイプ n でアイソクロナス転送を行う場合に、データの送受信先となる拡張アドレス領域の先頭アドレスを 32bit で指定します。
  アイソクロナス転送以外の転送では使用されません。\
  このレジスタは 32bit 幅です。

## コマンドコード一覧

CMD レジスタ (コマンドレジスタ) に設定するコマンドコードの一覧を示します。
コマンドコードの bit 7 が 0 のコマンドは同期コマンド、1 のコマンドは非同期コマンドです。

### 同期コマンド

#### $00 GETVER
  ZUSB のリビジョン番号を取得します。
  - 入力パラメータ
    - なし
  - 出力パラメータ
    - ERR レジスタ = リビジョン番号

#### $01 OPENCH
  チャネルの利用を開始します。\
  既にチャネルが利用中だった場合、そのチャネルが保護されていなければ (STAT.PROTECTED = 0)、チャネルの設定内容を初期化して利用できるようにします。
  保護されていれば (STAT.PROTECTED = 1) エラーになります。
  - 入力パラメータ
    - なし
  - 出力パラメータ
    - なし
    - 実行後、STAT レジスタの INUSE ビットが 1 になります

#### $02 CLOSECH
  チャネルの利用を終了します。
  - 入力パラメータ
    - なし
  - 出力パラメータ
    - なし
    - 実行後、STAT レジスタの INUSE ビットが 0 になります

#### $03 OPENCHP
  チャネルの利用を開始して保護状態にします。\
  通常のプロセスは OPENCH を、常駐プロセスは OPENCHP を使用することで、常駐プロセスが利用中のチャネルを通常プロセスが奪わないようにする使い方を想定しています。
  - 入力パラメータ
    - なし
  - 出力パラメータ
    - なし
    - 実行後、STAT レジスタの INUSE ビットと PROTECTED ビットが 1 になります

#### $04 CLOSECHP
  チャネルの利用を終了します。
  - 入力パラメータ
    - なし
  - 出力パラメータ
    - なし
    - 実行後、STAT レジスタの INUSE ビットが 0 になります

#### $05 SETIVECT
  チャネルが使用する割り込みベクタを設定します。
  ZUSB の割り込みベクタの初期値は $D0 から $D7 ですが、このコマンドによって任意のベクタに変更することができます。
  - 入力パラメータ
    - PARAM レジスタ = 割り込みベクタ番号
  - 出力パラメータ
    - なし

#### $06 GETIVECT
  チャネルが使用している割り込みベクタを取得します。
  - 入力パラメータ
    - なし
  - 出力パラメータ
    - PARAM レジスタ = 割り込みベクタ番号

#### $10 GETDEV
  接続されている最初の USB デバイスのデバイス ID を取得します。
  - 入力パラメータ
    - なし
  - 出力パラメータ
    - DEVID レジスタ = 最初の USB デバイスのデバイス ID (デバイスが1つも接続されていなければ 0)

#### $11 NEXTDEV
  次の USB デバイスのデバイス ID を取得します。
  - 入力パラメータ
    - なし
  - 出力パラメータ
    - DEVID レジスタ = 次の USB デバイスのデバイス ID (これ以上デバイスが接続されていなければ 0)

#### $12 GETDESC
  USB デバイスの USB ディスクリプタを取得します。
  - 入力パラメータ
    - DEVID レジスタ = ディスクリプタを取得するデバイスのデバイス ID
    - CADDR レジスタ = ディスクリプタを読み込む USB バッファ領域のオフセット
    - CCOUNT レジスタ = ディスクリプタを読み込む最大バイト数
  - 出力パラメータ
    - CCOUNT レジスタ = 実際に読み込まれたディスクリプタのバイト数 (0ならこれ以上読み込めない)

#### $13 CONTROL
  USB デバイスに対してコントロール転送を行います。
  - 入力パラメータ
    - DEVID レジスタ = デバイスリクエスト発行先のデバイスのデバイス ID
    - PARAM レジスタ = デバイスリクエストの bmRequestType (bit 15-8)、bRequest (bit 7-0) を指定
    - VALUE レジスタ = デバイスリクエストの wValue を指定
    - INDEX レジスタ = デバイスリクエストの wIndex を指定
    - CCOUNT レジスタ = デバイスリクエストの wLength を指定
    - CADDR レジスタ = デバイスリクエストがデータ転送を伴う場合、転送に使用する USB バッファ領域のオフセット
  - 出力パラメータ
    - CCOUNT レジスタ = デバイスリクエストによって転送されたデータのバイト数

#### $14 CONNECT
  指定したデバイス ID のデバイスに接続します。
  - 入力パラメータ
    - DEVID レジスタ = 接続するデバイスのデバイス ID
    - PARAM レジスタ = 接続するデバイスの Configuration と Interface の選択
      - bit 15-8 : Configuration番号 (※ 現在、Configuration 1 のみが有効です)
      - bit 7-0 : Interface番号
  - 出力パラメータ
    - なし

#### $15 DISCONNECT
  USB デバイスへの接続を解除します。
  - 入力パラメータ
    - なし
  - 出力パラメータ
    - なし

#### $16 SETIFACE
  接続中のデバイスの Interface の AltSetting を選択します (コントロール転送の SET_INTERFACE リクエスト)。
  - 入力パラメータ
    - PARAM レジスタ = Interface と AltSetting の選択
      - bit 15-8 : Interface番号
      - bit 7-0 : AltSetting番号
  - 出力パラメータ
    - なし

### 非同期コマンド

#### $80+n SUBMITXFER
  エンドポイントパイプ n への送受信を開始します。パイプの転送モードによってパラメータの意味が変わります。
  - コントロール/インタラプト/バルク転送
    - 入力パラメータ
      - PnADDR レジスタ = データ転送に使用する USB バッファ領域のオフセット
      - PnCOUNT レジスタ = データ転送の最大バイト数
    - 出力パラメータ
      - PnCOUNT レジスタ = 実際に転送されたバイト数
  - アイソクロナス転送
    - 入力パラメータ
      - PnADDR レジスタ = アイソクロナスディスクリプタテーブルの先頭アドレス
      - PnCOUNT レジスタ = アイソクロナスディスクリプタテーブルのエントリ数
      - PnDADDR レジスタ = データ転送に使用するバッファアドレス
    - 出力パラメータ
      - PnCOUNT レジスタ = 実際に転送されたアイソクロナスディスクリプタテーブルのエントリ数

#### $90+n  CANCELXFER
  エンドポイントパイプ n の保留中の転送を中止します。

#### $A0+n CLEARHALT
  エンドポイントパイプ n のhalt状態をクリアします。

## エラーコード一覧

コマンドの実行時にエラーが発生すると、STATUS レジスタの ERROR ビットが 1 に立つとともに ERRCD レジスタにエラーコードが設定されます。\
ERRCD レジスタには上位バイト (bit15-8) にエラーの原因となったコマンドコード、下位バイト (bit7-0) にエラー種別が格納されます。

エラーコード | 名前            | 意味
------------|----------------|------
$0000       | ZUSB_ENOERR    | エラーなし
$nn01       | ZUSB_EBUSY     | まだ実行が完了していないコマンドがあるのに別のコマンドを実行しようとした
$nn02       | ZUSB_EFAULT    | アドレス指定の誤り
$nn03       | ZUSB_ENOTCONN  | まだデバイスに接続されていない
$nn04       | ZUSB_ENOTINUSE | まだ使用中状態でないデバイス(STATUS.INUSE=0)にOPENCH以外のコマンドを発行した
$nn05       | ZUSB_EINVAL    | コマンド引数指定の誤り
$nn06       | ZUSB_ENODEV    | 指定されたデバイスIDのデバイスが存在しない
$nn07       | ZUSB_EIO       | デバイスI/Oエラー

## チャネルの状態遷移

ZUSB の各チャネルは以下の状態を持ちます。
ユーザは未使用チャネルを確保して使用中、接続中状態にすることで USB デバイスへのアクセスを行います。

#### 未使用 (STAT.INUSE = 0)
* チャネルがどのプログラムにも利用されていない状態です。各チャネルの初期状態です。
* オフセット +$00 ～ $0F の範囲のレジスタのみアクセスできます。
* 使用できるコマンドは GETVER, OPENCH, CLOSECH, OPENCHP, CLOSECHP のみです。
* OPENCH または OPENCHP コマンドでチャネルの利用を開始することで使用中状態に移行します。

#### 使用中 (STAT.INUSE = 1)
* チャネルを確保したが USB デバイスにはまだ接続していない状態です。
* 接続するデバイスを検索するために USB ディスクリプタを取得することができます。
* オフセット +$00 ～ $1F の範囲のレジスタと、USB バッファ領域のみアクセスできます。
* 未使用状態に加えて、SETIVECT, GETIVECT, GETDEV, NEXTDEV, GETDESC, CONTROL, CONNECT コマンドが使用できます。
* CONNECT コマンドで接続中状態に移行します。
* CLOSECH, CLOSECHP コマンドで未使用状態に移行します。

#### 接続中 (STAT.CONNECTED = 1)
* チャネルが USB デバイスに接続した状態です。
* USB デバイスのインターフェースが持つエンドポイントとの間でデータの送受信を行うことができます。
* チャネルのすべてのレジスタと USB バッファ領域にアクセスできます。
* ZUSB のすべてのコマンドが使用できます。
* DISCONNECT コマンドで使用中状態に移行します。
* CLOSECH, CLOSECHP コマンドで未使用状態に移行します。
