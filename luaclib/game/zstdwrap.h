#ifndef __ZSTDWRAP_H__
#define __ZSTDWRAP_H__

extern "C" {
#include "zstd.h"
}
#include <string>

struct Zstdwrap {
  static std::string compress(const char* p, size_t len) {
    std::string str;
    int sesize = ZSTD_compressBound(len);
    str.resize(sesize);
    size_t rlen = ZSTD_compress(str.data(), str.size(), p, len, 1);
    if (ZSTD_isError(rlen)) {
      return std::string();
    }
    str.resize(rlen);
    return str;
  }

  static std::string decompress(const char* p, size_t len) {
    int desize = ZSTD_getFrameContentSize(p, len);
    if (desize == ZSTD_CONTENTSIZE_ERROR ||
        desize == ZSTD_CONTENTSIZE_UNKNOWN) {
      return std::string();
    }
    std::string str;
    str.resize(desize);
    str.resize(ZSTD_getDecompressedSize(p, len));
    size_t rlen = ZSTD_decompress(str.data(), str.size(), p, len);
    if (ZSTD_isError(rlen)) {
      return std::string();
    }
    str.resize(rlen);
    return str;
  }
};

#endif