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

SUBDIRS = src zusbvideo zusbether zusbfddrv zusbscsi

GIT_REPO_VERSION=$(shell git describe --tags --always)

all:
	-for d in $(SUBDIRS); do $(MAKE) -C $$d all; done

install: all
	rm -rf build
	mkdir build && (cd build && mkdir doc bin sys)
	cp README-release.md build/README.md
	-for d in $(SUBDIRS); do $(MAKE) -C $$d install; done
	mkdir -p build/sdk && (cd build/sdk && mkdir doc include)
	cp -p include/*.h build/sdk/include
	cp -p ZUSB-api.md ZUSB-specs.md build/sdk/doc
	./md2txtconv.py -r build/*.md build/doc/*.md build/sdk/doc/*.md GIT_REPO_VERSION=$(GIT_REPO_VERSION)
	(cd build && xdftool.py c zusb-$(GIT_REPO_VERSION).xdf README.txt bin sys sdk doc)

release: install
	(cd build && zip -r ../zusb-$(GIT_REPO_VERSION).zip *)

clean:
	-rm -rf build
	-for d in $(SUBDIRS); do $(MAKE) -C $$d clean; done

.PHONY: all clean install
