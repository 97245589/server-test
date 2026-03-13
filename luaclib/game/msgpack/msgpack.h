#ifndef __MSGPACK_H__
#define __MSGPACK_H__

#include <cstdint>
#include <cstring>
#include <string>

struct Msgpack {
  template <typename T>
  static T endian_change(const T val) {
    T new_val;
    char* pv = (char*)&val;
    char* pn = (char*)&new_val;
    int size = sizeof(T);
    for (int i = 0; i < size; ++i) {
      pn[i] = pv[size - i - 1];
    }
    return new_val;
  }
  struct Pack {
    char buf_[1024 * 1024];
    int len_;
    void write(void* p, int len) {
      if (len_ + len >= sizeof(buf_)) return;
      memcpy(buf_ + len_, p, len);
      len_ += len;
    }
    void pack_nil();
    void pack_boolean(bool val);
    void pack_integer(int64_t val);
    void pack_double(double val);
    void pack_string(const char* p, uint32_t len);
    void pack_arr_head(uint32_t len);
    void pack_map_head(uint32_t len);
  };
  struct Unpack {
    template <typename T>
    static void parselen(char*& p, T& v) {
      v = *(T*)p;
      p += sizeof(T);
      v = endian_change(v);
    }
    struct Val {
      struct Str {
        char* p_;
        uint32_t len_;
      };
      union Data {
        bool b_;
        int64_t i_;
        double d_;
        Str s_;
        uint32_t len_;
      };
      int8_t tp_;
      Data data_;
    };
    enum { NIL, BOOL, INT, DOU, STR, ARR, MAP, ERR };
    char* ps_;
    char* pe_;
    Val val_;
    void parse();
  };
};

#endif