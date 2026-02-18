extern "C" {
#include "lauxlib.h"
#include "stdint.h"
#include "string.h"
}

#include <memory>
using namespace std;

#define TYPE_NIL 0
#define TYPE_BOOLEAN 1
// hibits 0 false 1 true
#define TYPE_NUMBER 2
// hibits 0 : 0 , 1: byte, 2:word, 4: dword, 6: qword, 8 : double
#define TYPE_NUMBER_ZERO 0
#define TYPE_NUMBER_BYTE 1
#define TYPE_NUMBER_WORD 2
#define TYPE_NUMBER_DWORD 4
#define TYPE_NUMBER_QWORD 6
#define TYPE_NUMBER_REAL 8

#define TYPE_USERDATA 3
#define TYPE_SHORT_STRING 4
// hibits 0~31 : len
#define TYPE_LONG_STRING 5
#define TYPE_TABLE 6

#define MAX_COOKIE 32
#define COMBINE_TYPE(t, v) ((t) | (v) << 3)

struct Seri {
  char buff_[1024 * 1024];
  int len_;
  int dep_;
  lua_State* L_;
  struct Tmp {
    Seri* pseri_;
    int array_size_;
  };

  inline void push(void* p, int len);
  inline void pack_one(int index);
  inline void pack_nil();
  inline void pack_boolean(int boolean);
  inline void pack_integer(lua_Integer v);
  inline void pack_double(double v);
  inline void pack_pointer(void* v);
  inline void pack_string(const char* str, int len);
  void pack_table(int index);
  int pack_table_arr(int index);
  void pack_table_hash(int index, int arraysize);
};

void Seri::push(void* p, int len) {
  if (len + len_ >= sizeof(buff_)) {
    luaL_error(L_, "seri buff err");
    return;
  }
  memcpy(buff_ + len_, p, len);
  len_ += len;
}

void Seri::pack_nil() {
  uint8_t n = TYPE_NIL;
  push(&n, 1);
}

void Seri::pack_boolean(int boolean) {
  uint8_t n = COMBINE_TYPE(TYPE_BOOLEAN, boolean ? 1 : 0);
  push(&n, 1);
}

void Seri::pack_integer(lua_Integer v) {
  int type = TYPE_NUMBER;
  if (v == 0) {
    uint8_t n = COMBINE_TYPE(type, TYPE_NUMBER_ZERO);
    push(&n, 1);
  } else if (v != (int32_t)v) {
    uint8_t n = COMBINE_TYPE(type, TYPE_NUMBER_QWORD);
    int64_t v64 = v;
    push(&n, 1);
    push(&v64, sizeof(v64));
  } else if (v < 0) {
    int32_t v32 = (int32_t)v;
    uint8_t n = COMBINE_TYPE(type, TYPE_NUMBER_DWORD);
    push(&n, 1);
    push(&v32, sizeof(v32));
  } else if (v < 0x100) {
    uint8_t n = COMBINE_TYPE(type, TYPE_NUMBER_BYTE);
    push(&n, 1);
    uint8_t byte = (uint8_t)v;
    push(&byte, sizeof(byte));
  } else if (v < 0x10000) {
    uint8_t n = COMBINE_TYPE(type, TYPE_NUMBER_WORD);
    push(&n, 1);
    uint16_t word = (uint16_t)v;
    push(&word, sizeof(word));
  } else {
    uint8_t n = COMBINE_TYPE(type, TYPE_NUMBER_DWORD);
    push(&n, 1);
    uint32_t v32 = (uint32_t)v;
    push(&v32, sizeof(v32));
  }
}

void Seri::pack_double(double v) {
  uint8_t n = COMBINE_TYPE(TYPE_NUMBER, TYPE_NUMBER_REAL);
  push(&n, 1);
  push(&v, sizeof(v));
}

void Seri::pack_pointer(void* v) {
  uint8_t n = TYPE_USERDATA;
  push(&n, 1);
  push(&v, sizeof(v));
}

void Seri::pack_string(const char* str, int len) {
  if (len < MAX_COOKIE) {
    uint8_t n = COMBINE_TYPE(TYPE_SHORT_STRING, len);
    push(&n, 1);
    if (len > 0) {
      push((void*)str, len);
    }
  } else {
    uint8_t n;
    if (len < 0x10000) {
      n = COMBINE_TYPE(TYPE_LONG_STRING, 2);
      push(&n, 1);
      uint16_t x = (uint16_t)len;
      push(&x, 2);
    } else {
      n = COMBINE_TYPE(TYPE_LONG_STRING, 4);
      push(&n, 1);
      uint32_t x = (uint32_t)len;
      push(&x, 4);
    }
    push((void*)str, len);
  }
}

int Seri::pack_table_arr(int index) {
  int array_size = lua_rawlen(L_, index);
  if (array_size >= MAX_COOKIE - 1) {
    uint8_t n = COMBINE_TYPE(TYPE_TABLE, MAX_COOKIE - 1);
    push(&n, 1);
    pack_integer(array_size);
  } else {
    uint8_t n = COMBINE_TYPE(TYPE_TABLE, array_size);
    push(&n, 1);
  }

  int i;
  for (i = 1; i <= array_size; i++) {
    lua_rawgeti(L_, index, i);
    pack_one(-1);
    lua_pop(L_, 1);
  }

  return array_size;
}

void Seri::pack_table_hash(int index, int arraysize) {
  Tmp t{.pseri_ = this, .array_size_ = arraysize};
  lua_traversal(
      L_, index,
      [](void* p) {
        Tmp& t = *(Tmp*)p;
        lua_State* L = t.pseri_->L_;
        int array_size = t.array_size_;
        if (lua_type(L, -2) == LUA_TNUMBER) {
          if (lua_isinteger(L, -2)) {
            lua_Integer x = lua_tointeger(L, -2);
            if (x > 0 && x <= array_size) {
              return;
            }
          }
        }
        t.pseri_->pack_one(-2);
        t.pseri_->pack_one(-1);
      },
      &t);
  pack_nil();
}

void Seri::pack_table(int index) {
  ++dep_;
  if (dep_ > 12) {
    luaL_error(L_, "seri dep err");
    return;
  }

  if (!lua_checkstack(L_, LUA_MINSTACK)) {
    luaL_error(L_, "out of memory");
    return;
  }
  if (index < 0) {
    index = lua_gettop(L_) + index + 1;
  }

  int array_size = pack_table_arr(index);
  pack_table_hash(index, array_size);
  --dep_;
}

void Seri::pack_one(int index) {
  int type = lua_type(L_, index);
  switch (type) {
    case LUA_TNIL:
      pack_nil();
      break;
    case LUA_TNUMBER: {
      if (lua_isinteger(L_, index)) {
        lua_Integer x = lua_tointeger(L_, index);
        pack_integer(x);
      } else {
        lua_Number n = lua_tonumber(L_, index);
        pack_double(n);
      }
      break;
    }
    case LUA_TBOOLEAN:
      pack_boolean(lua_toboolean(L_, index));
      break;
    case LUA_TSTRING: {
      size_t sz = 0;
      const char* str = lua_tolstring(L_, index, &sz);
      pack_string(str, (int)sz);
      break;
    }
    case LUA_TLIGHTUSERDATA:
      pack_pointer(lua_touserdata(L_, index));
      break;
    case LUA_TTABLE: {
      pack_table(index);
      break;
    }
    default:
      luaL_error(L_, "Unsupport type %s to serialize", lua_typename(L_, type));
  }
}

static int pack(lua_State* L) {
  unique_ptr<Seri> p = make_unique<Seri>();
  p->len_ = 0;
  p->L_ = L;
  p->dep_ = 0;
  int n = lua_gettop(L);
  for (int i = 1; i <= n; ++i) {
    p->pack_one(i);
  }
  lua_pushlstring(L, p->buff_, p->len_);
  return 1;
}

extern "C" {
LUAMOD_API int luaopen_lgame_seri(lua_State* L) {
  luaL_Reg l[] = {{"pack", pack}, {NULL, NULL}};
  luaL_newlib(L, l);
  return 1;
}
}