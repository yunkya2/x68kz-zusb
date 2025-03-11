/*
 * Copyright (c) 2025 Yuichi Nakamura (@yunkya2)
 *
 * The MIT License (MIT)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

/* X-BASIC external function header */

    .extern     xfnc_token
    .extern     xfnc_param
    .extern     xfnc_entry


    .text

    .long   noop            // BASIC起動時の初期化ルーチンのアドレス
    .long   noop            // RUN時に実行されるサブルーチンのアドレス
    .long   noop            // END時に実行されるサブルーチンのアドレス
    .long   noop            // OS復帰時に実行されるサブルーチンのアドレス
    .long   noop            // ブログラム中断時に実行されるサブルーチンのアドレス
    .long   noop            // 一行入力中のCTRL+D押下時に実行されるサブルーチンのアドレス
    .long   noop            // Reserved
    .long   noop            // Reserved
    .long   xfnc_token      // トークンテーブル
    .long   xfnc_param      // パラメータテーブル
    .long   xfnc_entry      // 実行アドレステーブル
    .long   noop            // Reserved
    .long   noop            // Reserved
    .long   noop            // Reserved
    .long   noop            // Reserved
    .long   noop            // Reserved

noop:
    rts

    .end
