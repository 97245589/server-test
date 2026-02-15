#ifndef __MSGPACK_H__
#define __MSGPACK_H__

#include <cstdint>
#include <string>

struct Msgpack {
  template <typename T>
  static T endian_change(const T& val) {
    T new_val;
    char* pv = (char*)&val;
    char* pn = (char*)&new_val;
    int size = sizeof(T);
    for (int i = 0; i < size; ++i) {
      pn[i] = pv[size - i - 1];
    }
    return new_val;
  }
  std::string buff_;
  void write(void* p, int len) { buff_.append((const char*)p, len); }
  void pack_nil();
  void pack_boolean(bool val);
  void pack_integer(int64_t val);
  void pack_double(double val);
  void pack_string(const char* p, uint32_t len);
  void pack_arr_head(uint32_t len);
  void pack_map_head(uint32_t len);
};

#endif