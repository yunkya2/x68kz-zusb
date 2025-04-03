/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2024 Yuichi Nakamura (@yunkya2)
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

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <setjmp.h>
#include <x68k/iocs.h>

int jpegload(uint8_t *buffer, size_t bufsize, uint8_t *filebuf, size_t filesize, void (*abortfnc)(void), int imgsize);

#define BUFSIZE     (1024 * 1024)

static jmp_buf jenv;
static uint8_t *jpegbuf = NULL;

static void jpegabort(void)
{
    longjmp(jenv, 1);
}

int jpegdisp(uint8_t *filebuf, size_t filesize, int imgsize)
{
    int res = 0;

    if (jpegbuf == NULL) {
        jpegbuf = malloc(BUFSIZE);
        if (jpegbuf == NULL) {
            return -1;
        }
    }

    void *oldvec_buserr = _iocs_b_intvcs(0x02, jpegabort);
    void *oldvec_adrerr = _iocs_b_intvcs(0x03, jpegabort);
    void *oldvec_ilinst = _iocs_b_intvcs(0x04, jpegabort);

    if (setjmp(jenv) == 0) {
        jpegload(jpegbuf, BUFSIZE, filebuf, filesize, jpegabort, imgsize);
    } else {
        res = -1;
    }

    _iocs_b_intvcs(0x02, oldvec_buserr);
    _iocs_b_intvcs(0x03, oldvec_adrerr);
    _iocs_b_intvcs(0x04, oldvec_ilinst);

    return res;
}
