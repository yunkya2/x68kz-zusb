/*
 * Copyright (c) 2026 Yuichi Nakamura (@yunkya2)
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

#include <stdint.h>
#include <string.h>
#include <x68k/dos.h>
#include <x68k/iocs.h>
#include <x68k/tsr.h>
#include <zusb.h>
#include "zusbscsi.h"

int main(int argc, char **argv)
{
  int remove_requested = argc == 2 &&
      (strcmp(argv[1], "/r") == 0 || strcmp(argv[1], "-r") == 0);

  if (argc < 2 || (!remove_requested && argc > 5)) {
    _dos_print("usage: zusbscsi.x /id<n>[:MO|:CD|:<VID>:<PID>] ... | /r\r\n");
    return 1;
  }

  tsr_device_t dev = tsr_finddev(ZUSBSCSI_NAME);
  if (dev != NULL) {
    if (!remove_requested) {
      _dos_print("zusbscsi: 既に常駐しています\r\n");
      return 1;
    }
    struct zusbscsi_state *state = tsr_getdevdata(dev);
    int ssp = tsr_super(0);
    uint8_t loaded_ids = *(volatile uint8_t *)0x000cec;
    tsr_super(ssp);
    if (state == NULL || state->magic != ZUSBSCSI_STATE_MAGIC ||
        !tsr_isfreeable(dev) || _dos_intvcg(0x01f5) != state->newvector ||
        (loaded_ids & state->mask) != 0) {
      _dos_print("zusbscsi: 常駐解除できません\r\n");
      return 1;
    }

    ssp = tsr_super(0);
    _iocs_b_intvcs(0x01f5, state->oldvector);
    for (int i = 0; i < ZUSBSCSI_MAX_DRIVE; i++) {
      if (state->channels[i] >= 0) {
        zusb_set_channel(state->channels[i]);
        zusb_close();
      }
    }
    tsr_super(ssp);
    if (tsr_freedev(dev) < 0) {
      _dos_print("zusbscsi: 常駐解除できません\r\n");
      return 1;
    }
    _dos_print("zusbscsi: 常駐解除しました\r\n");
    return 0;
  }

  if (remove_requested) {
    _dos_print("zusbscsi: 常駐していません\r\n");
    return 1;
  }

  int ssp = tsr_super(0);
  int result = zusbscsi_initialize(argc - 1, argv + 1);
  tsr_super(ssp);
  if (result != 0) {
    return 1;
  }

  tsr_keepdev(NULL, 0);
}
