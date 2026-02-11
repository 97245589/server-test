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

void Msgpack::pack_nil() {
  uint8_t m = 0xc0;
  write(&m, sizeof(m));
}

void Msgpack::pack_boolean(bool val) {
  uint8_t m;
  if (val) {
    m = 0xc3;
  } else {
    m = 0xc2;
  }
  write(&m, sizeof(m));
}

void Msgpack::pack_integer(int64_t val) {
  if (val >= 0) {
    if (val < 128) {
      uint8_t v = val;
      write(&v, sizeof(v));
    } else if (val <= 0xff) {
      uint8_t m = 0xcc;
      write(&m, sizeof(m));
      uint8_t v = val;
      write(&v, sizeof(v));
    } else if (val <= 0xffff) {
      uint8_t m = 0xcd;
      write(&m, sizeof(m));
      uint16_t v = val;
      v = endian_change(v);
      write(&v, sizeof(v));
    } else if (val <= 0xffffffff) {
      uint8_t m = 0xce;
      write(&m, sizeof(m));
      uint32_t v = val;
      v = endian_change(v);
      write(&v, sizeof(v));
    } else {
      uint8_t m = 0xcf;
      write(&m, sizeof(m));
      uint64_t v = val;
      v = endian_change(v);
      write(&v, sizeof(v));
    }
  } else {
    if (val >= -32) {
      uint8_t v = 0xe0 + val + 32;
      write(&v, sizeof(v));
    } else if (val >= -128) {
      uint8_t m = 0xd0;
      write(&m, sizeof(m));
      int8_t v = val;
      write(&v, sizeof(v));
    } else if (val >= -32768) {
      uint8_t m = 0xd1;
      write(&m, sizeof(m));
      int16_t v = val;
      v = endian_change(v);
      write(&v, sizeof(v));
    } else if (val >= -2147483648) {
      uint8_t m = 0xd2;
      write(&m, sizeof(m));
      int32_t v = val;
      v = endian_change(v);
      write(&v, sizeof(v));
    } else {
      uint8_t m = 0xd3;
      write(&m, sizeof(m));
      int64_t v = val;
      v = endian_change(v);
      write(&v, sizeof(v));
    }
  }
}

void Msgpack::pack_double(double val) {
  uint8_t m = 0xcb;
  write(&m, sizeof(m));
  val = endian_change(val);
  write(&val, sizeof(val));
}

void Msgpack::pack_string(const char* p, uint32_t len) {
  if (len < 256) {
    uint8_t m = 0xc4;
    write(&m, sizeof(m));
    uint8_t v = len;
    write(&v, sizeof(v));
  } else if (len < 65536) {
    uint8_t m = 0xc5;
    write(&m, sizeof(m));
    uint16_t v = len;
    v = endian_change(v);
    write(&v, sizeof(v));
  } else {
    uint8_t m = 0xc6;
    write(&m, sizeof(m));
    uint32_t v = len;
    v = endian_change(v);
    write(&v, sizeof(v));
  }
  write((void*)p, len);
}

void Msgpack::pack_arr_head(uint32_t len) {
  if (len < 16) {
    uint8_t m = 0x90 + len;
    write(&m, sizeof(m));
  } else if (len < 65536) {
    uint8_t m = 0xdc;
    write(&m, sizeof(m));
    uint16_t v = len;
    v = endian_change(v);
    write(&v, sizeof(v));
  } else {
    uint8_t m = 0xdd;
    write(&m, sizeof(m));
    uint32_t v = len;
    v = endian_change(v);
    write(&v, sizeof(v));
  }
}

void Msgpack::pack_map_head(uint32_t len) {
  if (len < 16) {
    uint8_t m = 0x80 + len;
    write(&m, sizeof(m));
  } else if (len < 65536) {
    uint8_t m = 0xde;
    write(&m, sizeof(m));
    uint16_t v = len;
    v = endian_change(v);
    write(&v, sizeof(v));
  } else {
    uint8_t m = 0xdf;
    write(&m, sizeof(m));
    uint32_t v = len;
    v = endian_change(v);
    write(&v, sizeof(v));
  }
}

#endif