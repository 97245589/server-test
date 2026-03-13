#include "msgpack.h"
using Pack = Msgpack::Pack;
using Unpack = Msgpack::Unpack;

void Pack::pack_nil() {
  uint8_t m = 0xc0;
  write(&m, sizeof(m));
}

void Pack::pack_boolean(bool val) {
  uint8_t m;
  if (val) {
    m = 0xc3;
  } else {
    m = 0xc2;
  }
  write(&m, sizeof(m));
}

void Pack::pack_integer(int64_t val) {
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

void Pack::pack_double(double val) {
  uint8_t m = 0xcb;
  write(&m, sizeof(m));
  val = endian_change(val);
  write(&val, sizeof(val));
}

void Pack::pack_string(const char* p, uint32_t len) {
  if (len < 32) {
    uint8_t m = 0xa0 + len;
    write(&m, sizeof(m));
  } else if (len < 256) {
    uint8_t m = 0xd9;
    write(&m, sizeof(m));
    uint8_t v = len;
    write(&v, sizeof(v));
  } else if (len < 65536) {
    uint8_t m = 0xda;
    write(&m, sizeof(m));
    uint16_t v = len;
    v = endian_change(v);
    write(&v, sizeof(v));
  } else {
    uint8_t m = 0xdb;
    write(&m, sizeof(m));
    uint32_t v = len;
    v = endian_change(v);
    write(&v, sizeof(v));
  }
  write((void*)p, len);
}

void Pack::pack_arr_head(uint32_t len) {
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

void Pack::pack_map_head(uint32_t len) {
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

void Unpack::parse() {
  int8_t& tp = val_.tp_;
  auto& data = val_.data_;
  if (ps_ >= pe_) {
    tp = ERR;
    return;
  }
  uint8_t m;
  parselen(ps_, m);

  if (m >= 0x00 && m <= 0x7f) {
    tp = INT;
    data.i_ = m;
    return;
  }
  if (m >= 0xe0 && m <= 0xff) {
    tp = INT;
    data.i_ = -32 + m - 0xe0;
    return;
  }
  if (m >= 0xa0 && m <= 0xbf) {
    tp = STR;
    int len = m - 0xa0;
    data.s_ = ps_;
    data.len_ = len;
    ps_ += len;
    return;
  }
  if (m >= 0x80 && m <= 0x8f) {
    tp = MAP;
    data.len_ = m - 0x80;
    return;
  }
  if (m >= 0x90 && m <= 0x9f) {
    tp = ARR;
    data.len_ = m - 0x90;
    return;
  }
  switch (m) {
    case 0xc0: {
      tp = NIL;
      return;
    }
    case 0xc2: {
      tp = BOOL;
      data.b_ = false;
      return;
    }
    case 0xc3: {
      tp = BOOL;
      data.b_ = true;
      return;
    }
    case 0xd9:
    case 0xc4: {
      tp = STR;
      uint8_t len;
      parselen(ps_, len);
      data.s_ = ps_;
      data.len_ = len;
      ps_ += len;
      return;
    }
    case 0xda:
    case 0xc5: {
      tp = STR;
      uint16_t len;
      parselen(ps_, len);
      data.s_ = ps_;
      data.len_ = len;
      ps_ += len;
      return;
    }
    case 0xdb:
    case 0xc6: {
      tp = STR;
      uint32_t len;
      parselen(ps_, len);
      data.s_ = ps_;
      data.len_ = len;
      ps_ += len;
      return;
    }
    case 0xca: {
      tp = DOU;
      float f;
      parselen(ps_, f);
      data.d_ = f;
      return;
    }
    case 0xcb: {
      tp = DOU;
      double d;
      parselen(ps_, d);
      data.d_ = d;
      return;
    }
    case 0xcc: {
      tp = INT;
      uint8_t v;
      parselen(ps_, v);
      data.i_ = v;
      return;
    }
    case 0xcd: {
      tp = INT;
      uint16_t v;
      parselen(ps_, v);
      data.i_ = v;
      return;
    }
    case 0xce: {
      tp = INT;
      uint32_t v;
      parselen(ps_, v);
      data.i_ = v;
      return;
    }
    case 0xcf: {
      tp = INT;
      uint64_t v;
      parselen(ps_, v);
      data.i_ = v;
      return;
    }
    case 0xd0: {
      tp = INT;
      int8_t v;
      parselen(ps_, v);
      data.i_ = v;
      return;
    }
    case 0xd1: {
      tp = INT;
      int16_t v;
      parselen(ps_, v);
      data.i_ = v;
      return;
    }
    case 0xd2: {
      tp = INT;
      int32_t v;
      parselen(ps_, v);
      data.i_ = v;
      return;
    }
    case 0xd3: {
      tp = INT;
      int64_t v;
      parselen(ps_, v);
      data.i_ = v;
      return;
    }
    case 0xdc: {
      tp = ARR;
      uint16_t len;
      parselen(ps_, len);
      data.len_ = len;
      return;
    }
    case 0xdd: {
      tp = ARR;
      uint32_t len;
      parselen(ps_, len);
      data.len_ = len;
      return;
    }
    case 0xde: {
      tp = MAP;
      uint16_t len;
      parselen(ps_, len);
      data.len_ = len;
      return;
    }
    case 0xdf: {
      tp = MAP;
      uint32_t len;
      parselen(ps_, len);
      data.len_ = len;
      return;
    }
    default: {
      tp = ERR;
      return;
    }
  }
}