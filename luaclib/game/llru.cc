extern "C" {
#include "lauxlib.h"
}

#include <cstdint>
#include <list>
#include <unordered_map>
using namespace std;

static const char* LLRU_META = "LLRU_META";
struct Lru {
  list<int64_t> ids_;
  unordered_map<int64_t, list<int64_t>::iterator> it_;
  uint32_t max_;
  bool update(const int64_t& id, int64_t& evi) {
    del(id);
    ids_.push_front(id);
    it_[id] = ids_.begin();
    return evict(evi);
  }

  bool evict(int64_t& evi) {
    if (ids_.size() <= max_) return false;
    evi = ids_.back();
    it_.erase(evi);
    ids_.pop_back();
    return true;
  }

  void del(const int64_t id) {
    if (auto it = it_.find(id); it != it_.end()) {
      ids_.erase(it->second);
      it_.erase(it);
    }
  }

  // void dump() { cout << "dump:" << ids_.size() << " " << it_.size() << endl;
  // }
};

struct Llru {
  static int update(lua_State* L);
  static int del(lua_State* L);

  static int gc(lua_State* L);
  static void meta(lua_State* L);
  static int create(lua_State* L);
};

int Llru::del(lua_State* L) {
  Lru** pp = (Lru**)luaL_checkudata(L, 1, LLRU_META);
  Lru& lru = **pp;

  int64_t id = luaL_checkinteger(L, 2);
  lru.del(id);
  return 0;
}

int Llru::update(lua_State* L) {
  Lru** pp = (Lru**)luaL_checkudata(L, 1, LLRU_META);
  Lru& lru = **pp;
  int64_t id = luaL_checkinteger(L, 2);

  int64_t evict;
  if (lru.update(id, evict)) {
    lua_pushinteger(L, evict);
    return 1;
  } else {
    return 0;
  }
}

int Llru::gc(lua_State* L) {
  Lru** pp = (Lru**)luaL_checkudata(L, 1, LLRU_META);
  delete *pp;
  return 0;
}

void Llru::meta(lua_State* L) {
  if (luaL_newmetatable(L, LLRU_META)) {
    luaL_Reg l[] = {
        {"update", update},
        {"del", del},
        {NULL, NULL},
    };
    luaL_newlib(L, l);
    lua_setfield(L, -2, "__index");
    lua_pushcfunction(L, gc);
    lua_setfield(L, -2, "__gc");
  }
  lua_setmetatable(L, -2);
}

int Llru::create(lua_State* L) {
  int max = luaL_checkinteger(L, 1);
  if (max <= 0) return luaL_error(L, "lru create err");

  Lru* p = new Lru();
  p->max_ = max;
  Lru** pp = (Lru**)lua_newuserdata(L, sizeof(p));
  *pp = p;
  meta(L);
  return 1;
}

extern "C" {
LUAMOD_API int luaopen_lgame_lru(lua_State* L) {
  luaL_Reg funcs[] = {{"create", Llru::create}, {NULL, NULL}};
  luaL_newlib(L, funcs);
  return 1;
}
}