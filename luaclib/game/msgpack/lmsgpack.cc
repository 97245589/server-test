extern "C" {
#include "lauxlib.h"
}
#include <iostream>

#include "msgpack.h"
using namespace std;

struct Unpack {
  lua_State* L;
  Msgpack::Unpack unpack_;
  void unpack();
};

void Unpack::unpack() {
  unpack_.parse();
  auto& val = unpack_.val_;
  auto& data = val.data_;
  switch (val.tp_) {
    case Msgpack::Unpack::NIL: {
      lua_pushnil(L);
      return;
    }
    case Msgpack::Unpack::BOOL: {
      lua_pushboolean(L, data.b_);
      return;
    }
    case Msgpack::Unpack::INT: {
      lua_pushinteger(L, data.i_);
      return;
    }
    case Msgpack::Unpack::DOU: {
      lua_pushnumber(L, data.d_);
      return;
    }
    case Msgpack::Unpack::STR: {
      lua_pushlstring(L, data.s_, data.len_);
      return;
    }
    case Msgpack::Unpack::ARR: {
      uint32_t len = data.len_;
      lua_createtable(L, len, 0);
      for (uint32_t i = 0; i < len; ++i) {
        unpack();
        lua_rawseti(L, -2, i + 1);
      }
      return;
    }
    case Msgpack::Unpack::MAP: {
      uint32_t len = data.len_;
      lua_createtable(L, 0, len);
      for (uint32_t i = 0; i < len; ++i) {
        unpack();
        unpack();
        lua_settable(L, -3);
      }
      return;
    }
    case Msgpack::Unpack::ERR: {
      luaL_error(L, "msgpack unpack err");
      return;
    }
  }
}

static int decode(lua_State* L) {
  size_t len;
  const char* p = luaL_checklstring(L, 1, &len);
  Unpack unpack{.L = L};
  auto& mup = unpack.unpack_;
  mup.ps_ = (char*)p;
  mup.pe_ = mup.ps_ + len;
  unpack.unpack();
  return 1;
}

struct Pack {
  lua_State* L;
  Msgpack::Pack pack_;
  int dep_;

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
  lua_checkstack(L, 2);
  if (dep_ > 10) {
    luaL_error(L, "msgpack dep err");
    return;
  }
  if (index < 0) index = lua_gettop(L) + index + 1;
  int32_t rawlen = lua_rawlen(L, index);
  int32_t tablen = table_len(index);
  if (rawlen == tablen) {
    pack_.pack_arr_head(tablen);
    lua_traversal(
        L, index,
        [](void* p) {
          Pack& pack = *(Pack*)p;
          pack.pack(-1);
        },
        this);
  } else {
    pack_.pack_map_head(tablen);
    lua_traversal(
        L, index,
        [](void* p) {
          Pack& pack = *(Pack*)p;
          pack.pack(-2);
          pack.pack(-1);
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
      if (lua_isinteger(L, index)) {
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
  std::string& buff = pack.pack_.buff_;
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