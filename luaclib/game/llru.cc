extern "C" {
#include "lauxlib.h"
}

#include <cstdint>
#include <iostream>
#include <list>
#include <sstream>
#include <unordered_map>
using namespace std;

static const char* META = "LLRU";
struct Lru {
  list<int64_t> ids_;
  unordered_map<int64_t, list<int64_t>::iterator> idit_;
  int max_;

  int64_t update(int64_t id) {
    del(id);
    ids_.push_front(id);
    idit_[id] = ids_.begin();
    return evict();
  }

  int64_t evict() {
    if (ids_.size() <= max_) return 0;
    int64_t id = ids_.back();
    idit_.erase(id);
    ids_.pop_back();
    return id;
  }

  void del(int64_t id) {
    auto it = idit_.find(id);
    if (it == idit_.end()) return;
    ids_.erase(it->second);
    idit_.erase(it);
  }
};

struct Llru {
  static int update(lua_State*);
  static int del(lua_State*);

  static int gc(lua_State*);
  static int create(lua_State*);
  static int dump(lua_State*);
};

int Llru::dump(lua_State* L) {
  Lru** pp = (Lru**)luaL_checkudata(L, 1, META);
  Lru& lru = **pp;

  ostringstream oss;
  auto& ids = lru.ids_;
  auto& idit = lru.idit_;
  oss << "lrudump:" << idit.size() << " " << ids.size() << endl;
  oss << "ids:";
  for (int64_t id : ids) {
    oss << id << " ";
  }
  oss << endl;
  const string& str = oss.str();
  lua_pushlstring(L, str.data(), str.size());
  return 1;
}

int Llru::del(lua_State* L) {
  Lru** pp = (Lru**)luaL_checkudata(L, 1, META);
  int64_t id = luaL_checkinteger(L, 2);
  Lru& lru = **pp;
  lru.del(id);
  return 0;
}

int Llru::update(lua_State* L) {
  Lru** pp = (Lru**)luaL_checkudata(L, 1, META);
  int64_t id = luaL_checkinteger(L, 2);
  Lru& lru = **pp;
  int64_t evict = lru.update(id);
  if (0 == evict) return 0;
  lua_pushinteger(L, evict);
  return 1;
}

int Llru::gc(lua_State* L) {
  Lru** pp = (Lru**)luaL_checkudata(L, 1, META);
  delete *pp;
  return 0;
}

int Llru::create(lua_State* L) {
  int max = luaL_checkinteger(L, 1);
  if (max <= 0) return luaL_error(L, "lru create err");

  Lru* p = new Lru();
  p->max_ = max;
  Lru** pp = (Lru**)lua_newuserdata(L, sizeof(p));
  *pp = p;

  if (luaL_newmetatable(L, META)) {
    luaL_Reg l[] = {
        {"update", update},
        {"del", del},
        {"dump", dump},
        {NULL, NULL},
    };
    luaL_newlib(L, l);
    lua_setfield(L, -2, "__index");
    lua_pushcfunction(L, gc);
    lua_setfield(L, -2, "__gc");
  }
  lua_setmetatable(L, -2);
  return 1;
}

extern "C" {
LUAMOD_API int luaopen_lgame_lru(lua_State* L) {
  luaL_Reg funcs[] = {{"create", Llru::create}, {NULL, NULL}};
  luaL_newlib(L, funcs);
  return 1;
}
}