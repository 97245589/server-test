extern "C" {
#include "lauxlib.h"
}
#include <cstdint>
#include <cstring>
#include <iostream>
#include <memory>
#include <string>
using namespace std;

struct Pack {
  lua_State* L;
  char buff_[1024 * 1024];
  uint32_t len_;
  uint32_t dep_;

  void write(void* p, int len) {
    if (len_ + len > sizeof(buff_)) {
      luaL_error(L, "msgpackage is too big more than 1M");
      return;
    }
    memcpy(buff_ + len_, p, len);
    len_ += len;
  }
  void pack(int index);
  void pack_nil();
  void pack_boolean(bool val);
  void pack_integer(int64_t val);
  void pack_double(double val);
  void pack_string(const char* p, uint32_t len);
  void pack_arr_head(uint32_t len);
  void pack_map_head(uint32_t len);
  void pack_table(int index);
  uint32_t table_len(int index);
};

struct Unpack {
  lua_State* L;
  void unpack(const char*& p);
};

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

template <typename T>
static void parselen(const char*& p, T& v) {
  v = *(T*)p;
  p += sizeof(T);
  v = endian_change(v);
}

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

uint32_t Pack::table_len(int index) {
  uint32_t i = 0;
  lua_pushnil(L);
  while (lua_next(L, index) != 0) {
    ++i;
    lua_pop(L, 1);
  }
  return i;
}

void Pack::pack_table(int index) {
  ++dep_;
  // cout << "dep" << dep_ << endl;
  if (dep_ > 10) {
    luaL_error(L, "pack depth more than 10");
    return;
  }
  int32_t rawlen = lua_rawlen(L, index);
  int32_t tablen = table_len(index);
  bool ismap;
  // cout << rawlen << "," << tablen << endl;
  if (rawlen == tablen) {
    pack_arr_head(tablen);
    ismap = false;
  } else {
    pack_map_head(tablen);
    ismap = true;
  }

  lua_pushnil(L);
  while (lua_next(L, index) != 0) {
    if (!ismap) {
      pack(index + 2);
    } else {
      pack(index + 1);
      pack(index + 2);
    }
    lua_pop(L, 1);
  }
  --dep_;
}

void Pack::pack(int index) {
  int type = lua_type(L, index);
  switch (type) {
    case LUA_TNIL: {
      pack_nil();
      return;
    }
    case LUA_TBOOLEAN: {
      bool val = lua_toboolean(L, index);
      pack_boolean(val);
      return;
    }
    case LUA_TNUMBER: {
      if (lua_isinteger(L, -1)) {
        int64_t num = lua_tointeger(L, index);
        pack_integer(num);
      } else {
        double num = lua_tonumber(L, index);
        pack_double(num);
      }
      return;
    }
    case LUA_TSTRING: {
      size_t len;
      const char* ps = lua_tolstring(L, index, &len);
      pack_string(ps, len);
      return;
    }
    case LUA_TTABLE: {
      pack_table(index);
      return;
    }
    default: {
      luaL_error(L, "msgpack encode type err %d", type);
      return;
    }
  }
}

void Unpack::unpack(const char*& p) {
  uint8_t m;
  parselen(p, m);
  bool ismap = false;
  uint32_t tlen;

  if (m >= 0x00 && m <= 0x7f) {
    lua_pushinteger(L, m);
    return;
  }
  if (m >= 0xe0 && m <= 0xff) {
    lua_pushinteger(L, -32 + m - 0xe0);
    return;
  }
  if (m >= 0xa0 && m <= 0xbf) {
    tlen = m - 0xa0;
    lua_pushlstring(L, p, tlen);
    p += tlen;
    return;
  }
  if (m >= 0x80 && m <= 0x8f) {
    ismap = true;
    tlen = m - 0x80;
    goto __map;
  }
  if (m >= 0x90 && m <= 0x9f) {
    ismap = false;
    tlen = m - 0x90;
    goto __map;
  }
  switch (m) {
    case 0xc0: {
      lua_pushnil(L);
      return;
    }
    case 0xc2: {
      lua_pushboolean(L, false);
      return;
    }
    case 0xc3: {
      lua_pushboolean(L, true);
      return;
    }
    case 0xd9:
    case 0xc4: {
      uint8_t len;
      parselen(p, len);
      lua_pushlstring(L, p, len);
      p += len;
      return;
    }
    case 0xda:
    case 0xc5: {
      uint16_t len;
      parselen(p, len);
      lua_pushlstring(L, p, len);
      p += len;
      return;
    }
    case 0xdb:
    case 0xc6: {
      uint32_t len;
      parselen(p, len);
      lua_pushlstring(L, p, len);
      p += len;
      return;
    }
    case 0xca: {
      float f;
      parselen(p, f);
      lua_pushnumber(L, f);
      return;
    }
    case 0xcb: {
      double d;
      parselen(p, d);
      lua_pushnumber(L, d);
      return;
    }
    case 0xcc: {
      uint8_t v;
      parselen(p, v);
      lua_pushinteger(L, v);
      return;
    }
    case 0xcd: {
      uint16_t v;
      parselen(p, v);
      lua_pushinteger(L, v);
      return;
    }
    case 0xce: {
      uint32_t v;
      parselen(p, v);
      lua_pushinteger(L, v);
      return;
    }
    case 0xcf: {
      uint64_t v;
      parselen(p, v);
      lua_pushinteger(L, v);
      return;
    }
    case 0xd0: {
      int8_t v;
      parselen(p, v);
      lua_pushinteger(L, v);
      return;
    }
    case 0xd1: {
      int16_t v;
      parselen(p, v);
      lua_pushinteger(L, v);
      return;
    }
    case 0xd2: {
      int32_t v;
      parselen(p, v);
      lua_pushinteger(L, v);
      return;
    }
    case 0xd3: {
      int64_t v;
      parselen(p, v);
      lua_pushinteger(L, v);
      return;
    }
    case 0xdc: {
      uint16_t len;
      parselen(p, len);
      ismap = false;
      tlen = len;
      break;
    }
    case 0xdd: {
      uint32_t len;
      parselen(p, len);
      ismap = false;
      tlen = len;
      break;
    }
    case 0xde: {
      uint16_t len;
      parselen(p, len);
      ismap = true;
      tlen = len;
      break;
    }
    case 0xdf: {
      uint32_t len;
      parselen(p, len);
      ismap = true;
      tlen = len;
      break;
    }
    default: {
      luaL_error(L, "unpack sign err %d", m);
      return;
    }
  }

__map:
  if (!ismap) {
    lua_createtable(L, tlen, 0);
    for (uint32_t i = 0; i < tlen; ++i) {
      unpack(p);
      lua_rawseti(L, -2, i + 1);
    }
  } else {
    lua_createtable(L, 0, tlen);
    for (uint32_t i = 0; i < tlen; ++i) {
      unpack(p);
      unpack(p);
      lua_settable(L, -3);
    }
  }
}

static int encode(lua_State* L) {
  lua_settop(L, 1);
  unique_ptr<Pack> p = make_unique<Pack>();
  Pack& pack = *p;
  pack.L = L;
  pack.dep_ = 0;
  pack.len_ = 0;
  pack.pack(1);
  lua_pushlstring(L, pack.buff_, pack.len_);
  return 1;
}

static int decode(lua_State* L) {
  size_t len;
  const char* p = luaL_checklstring(L, 1, &len);
  Unpack unpack{.L = L};
  const char* np = p;
  unpack.unpack(np);
  return 1;
}

extern "C" {
LUAMOD_API int luaopen_lgame_msgpack(lua_State* L) {
  luaL_Reg l[] = {{"encode", encode}, {"decode", decode}, {NULL, NULL}};
  luaL_newlib(L, l);
  return 1;
}
}