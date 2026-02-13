extern "C" {
#include "lauxlib.h"
}
#include "msgpack.h"
using namespace std;

struct Unpack {
  lua_State* L;
  void unpack(const char*& p);
  template <typename T>
  static void parselen(const char*& p, T& v) {
    v = *(T*)p;
    p += sizeof(T);
    v = Msgpack::endian_change(v);
  }
};

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
static int decode(lua_State* L) {
  size_t len;
  const char* p = luaL_checklstring(L, 1, &len);
  Unpack unpack{.L = L};
  const char* np = p;
  unpack.unpack(np);
  return 1;
}

struct Pack {
  lua_State* L;
  Msgpack pack_;
  uint32_t dep_;

  void pack(int index);
  uint32_t table_len(int index);
  void pack_table(int index);
};
uint32_t Pack::table_len(int index) {
  uint32_t i = 0;
  lua_traversal(
      L, index,
      [](void* p) {
        uint32_t* pi = (uint32_t*)p;
        *pi = *pi + 1;
      },
      &i);
  return i;
}
void Pack::pack_table(int index) {
  ++dep_;
  if (dep_ > 10) {
    luaL_error(L, "pack depth more than 10");
    return;
  }
  int32_t rawlen = lua_rawlen(L, index);
  int32_t tablen = table_len(index);
  if (index < 0) {
    index = lua_gettop(L) + index + 1;
  }

  if (rawlen == tablen) {
    pack_.pack_arr_head(tablen);
    lua_traversal(
        L, index,
        [](void* p) {
          Pack* pack = (Pack*)p;
          pack->pack(-1);
        },
        this);
  } else {
    pack_.pack_map_head(tablen);
    lua_traversal(
        L, index,
        [](void* p) {
          Pack* pack = (Pack*)p;
          pack->pack(-2);
          pack->pack(-1);
        },
        this);
  }
  --dep_;
}
void Pack::pack(int index) {
  int type = lua_type(L, index);
  switch (type) {
    case LUA_TNIL: {
      pack_.pack_nil();
      return;
    }
    case LUA_TBOOLEAN: {
      bool val = lua_toboolean(L, index);
      pack_.pack_boolean(val);
      return;
    }
    case LUA_TNUMBER: {
      if (lua_isinteger(L, -1)) {
        int64_t num = lua_tointeger(L, index);
        pack_.pack_integer(num);
      } else {
        double num = lua_tonumber(L, index);
        pack_.pack_double(num);
      }
      return;
    }
    case LUA_TSTRING: {
      size_t len;
      const char* ps = lua_tolstring(L, index, &len);
      pack_.pack_string(ps, len);
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
static int encode(lua_State* L) {
  lua_settop(L, 1);
  Pack pack{.L = L, .dep_ = 0};
  string& buff = pack.pack_.buff_;
  buff.reserve(1024 * 2);
  pack.pack(1);
  lua_pushlstring(L, buff.data(), buff.size());
  return 1;
}

extern "C" {
LUAMOD_API int luaopen_lgame_msgpack(lua_State* L) {
  luaL_Reg l[] = {{"encode", encode}, {"decode", decode}, {NULL, NULL}};
  luaL_newlib(L, l);
  return 1;
}
}