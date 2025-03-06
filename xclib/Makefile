#
# Copyright (c) 2025 Yuichi Nakamura (@yunkya2)
#
# The MIT License (MIT)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

SRCDIR = libzusb
INCDIR = include
LIBDIR = lib
INSTDIR = ../build/sdk/xc

convert = sed 's/$$/\r/' $(1) | grep -v stdint | sed 's/__attribute__ ((.*))//' | iconv -f utf-8 -t cp932 > $(2)

all:

install: src ../build
	-mkdir -p $(INSTDIR)
	cp -pr $(INCDIR) $(LIBDIR) $(INSTDIR)
	$(MAKE) clean

src: $(SRCDIR) $(INCDIR) $(LIBDIR)
	./makefunc.py ../include/zusbfunc.h $(SRCDIR) $(INCDIR)/zusbfunc.h
	$(call convert,zusb.h,$(INCDIR)/zusb.h)
	$(call convert,../include/zusbtypes.h,$(INCDIR)/zusbtypes.h)
	$(call convert,../include/zusbregs.h,$(INCDIR)/zusbregs.h)
	$(call convert,zusb_var.c,$(SRCDIR)/zusb_var.c)
	$(call convert,Makefile.lib,$(SRCDIR)/Makefile)

$(SRCDIR) $(INCDIR) $(LIBDIR):
	mkdir $@

clean:
	rm -rf $(SRCDIR) $(INCDIR)
