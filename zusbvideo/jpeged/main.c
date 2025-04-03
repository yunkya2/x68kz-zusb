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
#include <x68k/dos.h>
#include <x68k/iocs.h>

int jpegdisp(uint8_t *filebuf, size_t filesize, int imgsize);

int main(int argc, char **argv)
{
    int imgsize = 2;

    if (argc < 2) {
        fprintf(stderr, "Usage: %s <filename> [<size>]\n", argv[0]);
        return 1;
    }

    if (argc >= 3) {
        imgsize = atoi(argv[2]);
    }

    FILE *fp = fopen(argv[1], "rb");
    if (fp == NULL) {
        fprintf(stderr, "Failed to open file: %s\n", argv[1]);
        return 1;
    }
    fseek(fp, 0, SEEK_END);
    size_t filesize = ftell(fp);
    fseek(fp, 0, SEEK_SET);
    char *filebuf = malloc(filesize);
    if (filebuf == NULL) {
        fprintf(stderr, "Failed to allocate memory\n");
        fclose(fp);
        return 1;
    }
    fread(filebuf, 1, filesize, fp);
    fclose(fp);

    switch (imgsize) {
    case 1:
        _iocs_crtmod(14);
        break;
    default:
        _iocs_crtmod(12);
        break;
    }
    _iocs_g_clr_on();

    uint32_t usp = _iocs_b_super(0);
    int res = jpegdisp(filebuf, filesize, imgsize);
    _iocs_b_super(usp);

    if (res < 0) {
        printf("jpegdisp error\n");
    }
    free(filebuf);

    return res;
}
