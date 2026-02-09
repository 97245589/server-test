#ifndef __ZSTDWRAP_H__
#define __ZSTDWRAP_H__

extern "C" {
#include "zstd.h"
}
#include <string>

struct Zstdwrap {
  static std::string compress(const char* p, size_t len) {
    std::string str;
    str.resize(ZSTD_compressBound(len));
    int rlen = ZSTD_compress(str.data(), str.size(), p, len, 1);
    str.resize(rlen);
    return str;
  }

  static std::string decompress(const char* p, size_t len) {
    std::string str;
    str.resize(ZSTD_getFrameContentSize(p, len));
    int rlen = ZSTD_decompress(str.data(), str.size(), p, len);
    str.resize(rlen);
    return str;
  }
};

#endif