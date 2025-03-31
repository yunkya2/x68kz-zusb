*
*
*  WORK.INC
*
mul_flow		equ	128+64
RGB_flow		equ	1024
bufsize			equ	1024
YUV_RGB_table_size	equ	2048
*
	.data
	.offset 0
*
fname		ds.b	70
VSname		ds.b	70
temp_path       ds.b	256+14
Qname		ds.b	80
Comment		ds.b	200
uvmode		ds.b	1
uvmode_source	ds.b	1
Qlevel_source	ds.b	1
colormode	ds.b	1	* 0:color
				* 1:mono
Action		ds.b	1	* 0:Load  1:Save  2:Information 
DispMod		ds.b	1	* 0:間引かない
				* 1:全画面引き延ばし
				* 2:画像を画面内に収まるようする
Sys_flag	ds.b	1	* bit 0	1)キー入力待ちする　0)しない
				* bit 1	1)テンポラリに展開オプション有り 0)無し
				* bit 2	1)テンポラリに展開する 0)しない
				* bit 3	1)ディスクフルになった 0)ならない
				* bit 4	1)画像展開バッファは横１ブロックラインのみ 0)全体分
				* bit 5	1)アスペクト補正を行う
				* bit 6	1)マウスＸＹ移動量をキーに変換でＸを優先 0)Ｙを優先
				* bit 7	1)RGBの値の最大を252とする画像である
Sys_flag2	ds.b	1     	* bit 0	1)68020以上のMPUである
				* bit 1	1)ｽｸﾘｰﾝﾓｰﾄﾞ設定をしない
				* bit 2	1)展開後ｽｸﾛｰﾙする 0)しない
				* bit 3	1)位置指定有り 0)無し
				* bit 4	1)仮想画面指定有り 0)無し
				* bit 5	1)ﾌｧｲﾙ上の仮想画面 0)ﾒﾓﾘ上の仮想画面
				* bit 6	1)位置指定左上と右下両方 0)左上のみ
				* bit 7	1)ｵｰﾄｽｸﾛｰﾙ要求
Sys_flag3	ds.b	1	* bit 0	1)Undoｷｰでのﾒｯｾｰｼﾞ表示中 0)表示していない
				* bit 1	1)半階調表示中 0)じゃないよ(^^;
				* bit 2	1)何かｷｰが押された 0)押されていない (homeｷｰ以外)
				* bit 3	1)TV Ctrlｷｰも移動高速化ｷｰとして強制使用する
				* bit 4	1)'/'をｵﾌﾟｼｮﾝに使用出来なくする
				* bit 5	1)終了時の画像のHome位置補正を行う
*				* bit 6	1)画像表示途中でｴﾗｰが発生しても、即終了しない 0)終了する
DecodeStatus	ds.b	1	0)展開中 1)正常終了 -1)画像が異常
SOFx		ds.b	1	展開する画像の圧縮方式(SOFxのxの番号)
Home_key_time	ds.b	1	Homeｷｰが連続して押された回数
Cflag		ds.b	1
  even
HX		ds.w	1		GetPartでの表示開始位置X
HY		ds.w	1		GetPartでの表示開始位置Y
HZ		ds.w	1
HS		ds.w	1		画面上での横方向の表示開始位置
VS		ds.w	1		画面上での縦方向の表示開始位置
HE		ds.w	1		画面上での横方向の表示終了位置
VE		ds.w	1		画面上での縦方向の表示終了位置
XS		ds.w	1		画像上での横方向の表示開始位置
YS		ds.w	1		画像上での縦方向の表示開始位置
XE		ds.w	1		画像上での横方向の表示終了位置(実は使用されない）
YE		ds.w	1		画像上での縦方向の表示終了位置
Aspect		ds.w	2		ドット比
Qlevel		ds.w	1		量子化レベル
Interval	ds.w	4		間引き率
Interval_bak	ds.w	4		間引き率 一つ前

Home_X		ds.w	1		ｸﾞﾗﾌｨｯｸ画面のHome位置X
Home_Y		ds.w	1		ｸﾞﾗﾌｨｯｸ画面のHome位置Y
Home_FX		ds.w	1		倍率変更前のｸﾞﾗﾌｨｯｸ画面のHome位置X
Home_FY		ds.w	1		倍率変更前のｸﾞﾗﾌｨｯｸ画面のHome位置Y

MOUSE_X		ds.w	1		表示X座標(HOME位置)
MOUSE_Y		ds.w	1		表示Y座標(HOME位置)
MOUSE_Z		ds.w	1		倍率(変更前)
MOUSE_TX	ds.w	1		ｽｸﾛｰﾙX座標
MOUSE_TY	ds.w	1		ｽｸﾛｰﾙY座標
MOUSE_TZ	ds.w	1		倍率

XL		ds.w	1		表示するX方向の画像のﾄﾞｯﾄ数
XL2		ds.w	1		XL/2
XL3		ds.w	1		X方向の誤差吸収用
XL4		ds.w	1		XL/2の余り
YL		ds.w	1		表示するY方向の画像のﾄﾞｯﾄ数
YL2		ds.w	1		YL/2
YL3		ds.w	1		Y方向の誤差吸収用
YL4		ds.w	1		YL/2の余り
Y_last		ds.w	1		Y方向の残りの表示ﾄﾞｯﾄ数

TIME_BAK	ds.w	1
TIME_WAIT	ds.w	1		ｵｰﾄｽｸﾛｰﾙの方向を変える時の待時間(10ms単位)
DirX		ds.w	1		ｵｰﾄｽｸﾛｰﾙのX方向の向き
DirY		ds.w	1		ｵｰﾄｽｸﾛｰﾙのY方向の向き
DirZ		ds.w	1		ｵｰﾄｽｸﾛｰﾙのZ方向の向き(拡大縮小方向)

align 4

ErrorStackPoint	ds.l	1		ｴﾗｰ強制復帰用ｽﾀｯｸﾎﾟｲﾝﾀ(0の場合、強制復帰しない)
fdate		ds.l	1		JPGﾌｧｲﾙの作成日付
TEMP_FP		ds.l	1		ﾃﾝﾎﾟﾗﾘﾌｧｲﾙ読み込みﾌｧｲﾙﾎﾟｲﾝﾀ
TEMP_RED_SIZE	ds.l	1		読み込みｻｲｽﾞ

FFxxFlag	ds.w	1				ここから
rdata		ds.w	1		残りﾃﾞｰﾀ	↓
rlen		ds.w	1		残りﾋﾞｯﾄ長	ここまで連続してる必要あり
preDC		ds.w	3		前のDC値

LastBufSize	ds.w	1		ﾊﾞｯﾌｧの残りﾊﾞｲﾄ数				ここから
LastFFxxSize	ds.w	1		次のFFxx(またはﾊﾞｯﾌｧの最後)までの残りﾊﾞｲﾄ数	↓
bufadr		ds.l	1		ﾃﾞｰﾀ読み込みｱﾄﾞﾚｽ				ここまで連続してる必要あり
errflg		ds.l	1		ﾃﾞｰﾀ読み込みｴﾗｰﾌﾗｸﾞ
DQTadr		ds.l	1

lx		ds.l	1		画像の横のブロック数＊バイト数
BlkX		ds.w	1		画像の横のブロック数
BlkY		ds.w	1		画像の縦のブロック数

DCL_bits	ds.w	1		DCLのハフマン符号数
DCC_bits	ds.w	1		DCCのハフマン符号数
Jhandle		ds.w	1		画像ファイルハンドル
VShandle	ds.w	1		画像ファイルハンドル
temp_handle	ds.w	1		展開画像を保存するﾃﾝﾎﾟﾗﾘﾌｧｲﾙﾊﾝﾄﾞﾙ
DeltaX		ds.w	1		１ブロック当たりの横のドット数
DeltaY		ds.w	1		１ブロック当たりの縦のドット数
Yline		ds.w	1		画像の縦のドット数
Xline		ds.w	1		画像の横のドット数
Maxline		ds.w	1		画像の縦と横で長い方のﾄﾞｯﾄ数
GETP_adrs	ds.l	1		画像表示命令ｱﾄﾞﾚｽ
GETP_size	ds.l	1		画像表示命令ｻｲｽﾞ
HScroll_size	ds.l	1		1ﾌﾞﾛｯｸ内での1ﾗｲﾝ下までのﾊﾞｲﾄ数
file_addr	ds.l	1
file_point	ds.l	1
EncodePath	ds.w	1		圧縮時ﾊﾟｽ回数-1
imsg_handle	ds.w	1		ﾒｯｾｰｼﾞ表示用ﾌｧｲﾙﾊﾝﾄﾞﾙ
imsg_start_point	ds.l	1	ﾒｯｾｰｼﾞ開始ﾌｧｲﾙﾎﾟｲﾝﾄ
imsg_point	ds.l	1		ﾒｯｾｰｼﾞ読み込みﾌｧｲﾙﾎﾟｲﾝﾄ
imsg_size	ds.l	1		ﾒｯｾｰｼﾞｻｲｽﾞ
buf_adrs	ds.l	1		読み込みバッファアドレス
buf_size	ds.l	1		読み込みバッファサイズ
Scroll_Area	ds.l	1		画像バッファアドレス
Scroll_size	ds.l	1		画像バッファサイズ
VSFile_buf_adrs	ds.l	1		仮想画面ファイルへのバッファアドレス
VSFile_buf_size	ds.l	1		仮想画面ファイルへのバッファサイズ
picture_size	ds.l	1		画像の大きさ(1word単位)

clr_end					*０クリア終了アドレス

VSadr     	ds.l	1		仮想画面のアドレスまたはファイルポインタ
VSXsize		ds.w	1		仮想画面の横のﾄﾞｯﾄ数
VSYsize		ds.w	1		仮想画面の縦のﾄﾞｯﾄ数
VSXbyte		ds.l	1		仮想画面の横のバイト数
VScbit		ds.w	1		仮想画面1ﾄﾞｯﾄ当たりのﾋﾞｯﾄ数

align 4

QtableL		ds.w	64		このテーブルと、
QtableC		ds.w	64		このテーブルは連続したアドレスに無ければいけない

buff_size	ds.l	1		*
buff_adrs	ds.l	1		*
GetHeadWorkAdrs	ds.l	1
free_adrs	ds.l	1		画像のｽｸﾛｰﾙ表示で使わないメモリアドレス
free_size	ds.l	1				〃		サイズ

x1		ds.w	1
y1		ds.w	1
v		ds.w	1
yi		ds.w	1

Key_work	ds.b	(2+2+2)*128	*(w)ｷｰｵﾝした時間 $ffffの場合はｷｰｵﾌ中 (get_key_timeで更新される)
					*(w)ｷｰｵﾝした時間
					*(w)ｷｰが押されていた時間
Mouse_work	ds.b	(2+2+2)*2	*Key_workと同じﾌｫｰﾏｯﾄ

	.align	4

em_free_adrs


*展開用ﾜｰｸｴﾘｱ定義
*----------------------------
	.offset em_free_adrs

ydata1		ds.w	64		このテーブルから
ydata2		ds.w	64		↓
ydata3		ds.w	64		↓
ydata4		ds.w	64		このテーブルまでは連続したアドレスに無ければいけない
udata1		ds.w	64
vdata1		ds.w	64

DECODE_TBL	ds.b	256*8*4		*DCL,ACL,DCC,ACC
DCL_DECODE_TBL	equ	DECODE_TBL
ACL_DECODE_TBL	equ	DECODE_TBL+1*8
DCC_DECODE_TBL	equ	DECODE_TBL+2*8
ACC_DECODE_TBL	equ	DECODE_TBL+3*8

RootDCL		ds.l	20
RootDCC		ds.l	20
RootACL		ds.l	200
RootACC		ds.l	200

GetHeadWorkStart

UQL_tbl		ds.l	64
UQC_tbl		ds.l	64
UQ_mul_tbl	ds.w	22134+128

COS_under	ds.w	mul_flow*6
COS_TBL		ds.w	4096*6
COS_over	ds.w	mul_flow*6
COS6		equ	0
COS2		equ	2
COS1		equ	4
COS3		equ	6
COS5		equ	8
COS7		equ	10

YUV_RGB_under	ds.w	mul_flow*6
YUV_RGB_TBL	ds.w	2048*6
YUV_RGB_over	ds.w	mul_flow*6
U03441		equ	0
U17718		equ	2
V14020		equ	4
V07319		equ	6
V00012		equ	8

RGB_TBL_under	ds.w	RGB_flow*6
RGB_TBL		ds.w	2048*6
RGB_TBL_over	ds.w	RGB_flow*6
G_TBL		equ	0
R_TBL		equ	2
B_TBL		equ	4

GETP_WORK				*画像表示命令展開アドレス

load_work_size


*圧縮用ﾜｰｸｴﾘｱ定義
*----------------------------
	.offset em_free_adrs

HuffCount
Eydata1		ds.l	64
Eydata2		ds.l	64
Eydata3		ds.l	64
Eydata4		ds.l	64
Eudata1		ds.l	64
Evdata1		ds.l	64

RateTableStart
DCLtable	ds.l	(16-4)*2	このテーブルと、
ACLtable	ds.l	(16*16-4)*2	このテーブルは連続したアドレスに無ければいけない
DCCtable	ds.l	(16-4)*2		このテーブルと、
ACCtable	ds.l	(16*16-4)*2	このテーブルは連続したアドレスに無ければいけない
RateTableEnd
HuffTreeStart
HuffTree	ds.l	(16*16-4)*2
HuffTreeEnd

DCT_TBL		ds.l	4096*8
DCOS6		equ	0
DCOS2		equ	4
DCOS1		equ	8
DCOS3		equ	12
DCOS6h		equ	16
DCOS2h		equ	20
DCOS5		equ	24
DCOS7		equ	28

RGB_YUV_TBL	ds.l	256*8
G05870		equ	0
G03316		equ	4
G04187		equ	8
R02990		equ	12
R01684		equ	16
R05000		equ	20
B01140		equ	24
B00813		equ	28

save_work_size
