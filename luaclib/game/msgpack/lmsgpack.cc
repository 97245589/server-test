extern "C" {
#include "lauxlib.h"
}
#include <iostream>

#include "msgpack.h"
using namespace std;

using Pack = Msgpack::Pack;
using Unpack = Msgpack::Unpack;

struct Decode {
  lua_State* L;
  Unpack unpack_;
  void decode();
};

void Decode::decode() {
  unpack_.parse();
  auto& val = unpack_.val_;
  auto& data = val.data_;
  switch (val.tp_) {
    case Unpack::NIL: {
      lua_pushnil(L);
      return;
    }
    case Unpack::BOOL: {
      lua_pushboolean(L, data.b_);
      return;
    }
    case Unpack::INT: {
      lua_pushinteger(L, data.i_);
      return;
    }
    case Unpack::DOU: {
      lua_pushnumber(L, data.d_);
      return;
    }
    case Unpack::STR: {
      lua_pushlstring(L, data.s_, data.len_);
      return;
    }
    case Unpack::ARR: {
      uint32_t len = data.len_;
      lua_createtable(L, len, 0);
      for (uint32_t i = 0; i < len; ++i) {
        decode();
        lua_rawseti(L, -2, i + 1);
      }
      return;
    }
    case Unpack::MAP: {
      uint32_t len = data.len_;
      lua_createtable(L, 0, len);
      for (uint32_t i = 0; i < len; ++i) {
        decode();
        decode();
        lua_settable(L, -3);
      }
      return;
    }
    case Unpack::ERR: {
      luaL_error(L, "msgpack unpack err");
      return;
    }
  }
}

static int decode(lua_State* L) {
  size_t len;
  const char* p = luaL_checklstring(L, 1, &len);
  Decode decode{.L = L};
  auto& mup = decode.unpack_;
  mup.ps_ = (char*)p;
  mup.pe_ = mup.ps_ + len;
  decode.decode();
  return 1;
}

struct Encode {
  lua_State* L;
  Pack pack_;
  int dep_;

  void encode(int index);
  uint32_t table_len(int index);
  void encode_table(int index);
};
uint32_t Encode::table_len(int index) {
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
void Encode::encode_table(int index) {
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
          Encode& encode = *(Encode*)p;
          encode.encode(-1);
        },
        this);
  } else {
    pack_.pack_map_head(tablen);
    lua_traversal(
        L, index,
        [](void* p) {
          Encode& encode = *(Encode*)p;
          encode.encode(-2);
          encode.encode(-1);
        },
        this);
  }
  --dep_;
}
void Encode::encode(int index) {
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
      encode_table(index);
      return;
    }
    default: {
      luaL_error(L, "msgpack encode type err %d", type);
      return;
    }
  }
}

static const char* META = "MSGPACK";
static int encode(lua_State* L) {
  Encode** pp = (Encode**)luaL_checkudata(L, 1, META);
  Encode& encode = **pp;
  auto& pack = encode.pack_;
  encode.L = L;
  encode.dep_ = 0;
  pack.len_ = 0;
  encode.encode(2);
  if (pack.len_ > sizeof(pack.buff_) - 1024 * 100) {
    return luaL_error(L, "msgpack buff err");
  }
  lua_pushlstring(L, pack.buff_, pack.len_);
  return 1;
}
static int gc(lua_State* L) {
  Encode** pp = (Encode**)luaL_checkudata(L, 1, META);
  delete *pp;
  return 0;
}
static int create(lua_State* L) {
  Encode* p = new Encode();
  Encode** pp = (Encode**)lua_newuserdata(L, sizeof(p));
  *pp = p;
  if (luaL_newmetatable(L, META)) {
    luaL_Reg l[] = {{"encode", encode}, {NULL, NULL}};
    luaL_newlib(L, l);
    lua_setfield(L, -2, "__index");
    lua_pushcfunction(L, gc);
    lua_setfield(L, -2, "__gc");
  }
  lua_setmetatable(L, -2);
  return 1;
}

extern "C" {
LUAMOD_API int luaopen_lgame_msgpack(lua_State* L) {
  luaL_Reg l[] = {{"create", create}, {"decode", decode}, {NULL, NULL}};
  luaL_newlib(L, l);
  return 1;
}
}