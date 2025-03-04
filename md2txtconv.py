#!/usr/bin/env python3
#
# md2txtconv.py - Convert markdown to text file
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

import sys
import re
import codecs
import os

WIDTH = 76

PRO_HEAD_CHARS = "。、〕〉》」』】〙〗"

def get_display_width(text):
    width = 0
    for char in text:
        if ord(char) < 128:
            width += 1
        else:
            width += 2
    return width

def wrap_text(text, width):
    if not text.strip():
        return text
    text = text.rstrip("\n")
    leading_spaces = len(text) - len(text.lstrip(' '))
    next_leading_spaces = leading_spaces

    if m := re.match(r'( *)\* ', text):
        text = " " + text
        leading_spaces = len(m.group(1)) + 1
        next_leading_spaces = len(m.group(0)) + 1
    if m := re.match(r'( *)\d+\. ', text):
        text = " " + text
        leading_spaces = len(m.group(1)) + 1
        next_leading_spaces = len(m.group(0)) + 1

    wrapped_lines = []
    current_line = " " * leading_spaces
    current_width = leading_spaces

    word_buffer = ""
    word_width = 0

    for char in text.lstrip(' '):
        char_width = get_display_width(char)
        if char.isspace():
            if current_width + word_width > width:
                wrapped_lines.append(current_line)
                leading_spaces = next_leading_spaces
                current_line = " " * leading_spaces + word_buffer
                current_width = leading_spaces + word_width
            else:
                current_line += word_buffer
                current_width += word_width
            current_line += char
            current_width += char_width
            word_buffer = ""
            word_width = 0
        else:
            if ord(char) < 128:
                if current_width + word_width + char_width > width:
                    wrapped_lines.append(current_line)
                    leading_spaces = next_leading_spaces
                    current_line = " " * leading_spaces + word_buffer + char
                    current_width = leading_spaces + word_width + char_width
                    word_buffer = ""
                    word_width = 0
                else:
                    word_buffer += char
                    word_width += char_width
            else:
                if word_width > 0:
                    current_line += word_buffer
                    current_width += word_width
                    word_buffer = ""
                    word_width = 0

                if current_width + char_width > width:
                    if char in PRO_HEAD_CHARS:
                        current_line += char
                        char = ""
                        char_width = 0
                    wrapped_lines.append(current_line)
                    leading_spaces = next_leading_spaces
                    current_line = " " * leading_spaces + char
                    current_width = leading_spaces + char_width
                else:
                    current_line += char
                    current_width += char_width

    if word_buffer:
        if current_width + word_width > width:
            wrapped_lines.append(current_line)
            current_line = " " * leading_spaces + word_buffer
        else:
            current_line += word_buffer

    if current_line.strip():
        wrapped_lines.append(current_line)

    return "\n".join(wrapped_lines) + "\n"

def process_file(filename, remove_original, replacements):
    with codecs.open(filename, 'r', 'utf-8') as f:
        lines = f.readlines()

    with codecs.open(filename.replace('.md', '.txt'), 'w', 'cp932') as f:
        nowrap = False
        for line in lines:
            w = get_display_width(line)

            if '```' in line:
                nowrap = not nowrap
                pos = line.find('```')
                if pos == 0:
                    line = '-' * (WIDTH - 1) + '\n'
                else:
                    line = line[:pos] + '-' * (WIDTH - pos - 1) + '\n'
            else:
                line = re.sub(r'`', '', line)
                line = re.sub(r'\\$', '', line)
                line = re.sub(r'\\<', '<', line)
                line = re.sub(r'\\>', '>', line)
                line = re.sub(r'^# (.*)', r'■■■ \1 ■■■', line)
                line = re.sub(r'^## ', '■ ', line)
                line = re.sub(r'^### ', '● ', line)
                line = re.sub(r'^#### ', '○ ', line)
                line = re.sub(r'\*\*', '', line)
                line = re.sub(r'\[([^]]*)\]\([^)]*\)', r'\1', line)
                line = re.sub(r'(--*):', r'\1-', line)
                if not re.search(r'.*\|.*\|', line) and not nowrap:
                    line = wrap_text(line, WIDTH)

                for keyword, value in replacements.items():
                    line = line.replace(keyword, value)

            line = re.sub(r'\n', '\r\n', line)
            f.write(line)

    if remove_original:
        os.remove(filename)

def print_usage():
    print("Usage: md2txtconv.py [options] <input files>")
    print("Options:")
    print("  -r              Remove original .md files after conversion")
    print("  -h              Show this help message")
    print("  keyword=value   Replace occurrences of 'keyword' with 'value' in the text")

if __name__ == "__main__":
    remove_original = False
    filenames = []
    replacements = {}

    for arg in sys.argv[1:]:
        if arg == '-r':
            remove_original = True
        elif arg == '-h':
            print_usage()
            sys.exit(0)
        elif '=' in arg:
            keyword, value = arg.split('=', 1)
            replacements[keyword] = value
        else:
            filenames.append(arg)

    if not filenames:
        print_usage()
        sys.exit(1)

    for filename in filenames:
        process_file(filename, remove_original, replacements)
