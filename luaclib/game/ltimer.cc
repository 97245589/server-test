extern "C" {
#include "lauxlib.h"
}
#include <cstdint>
#include <set>
#include <string>
#include <unordered_map>
using namespace std;

struct Timer {
  struct Ele {
    int64_t id_;
    string mark_;
    uint64_t tm_;
    bool operator<(const Ele& rhs) const {
      if (tm_ != rhs.tm_) return tm_ < rhs.tm_;
      if (mark_ != rhs.mark_) return mark_ < rhs.mark_;
      return id_ < rhs.id_;
    }
  };
  set<Ele> info_;
  unordered_map<int64_t, unordered_map<string, set<Ele>::iterator>> id_mark_it_;

  void add(const Ele& ele) {
    const int64_t id = ele.id_;
    const string& mark = ele.mark_;
    del_mark(id, mark, true);
    auto [it, ok] = info_.insert(ele);
    id_mark_it_[id][mark] = it;
  }
  void del_id(const int64_t id) {
    auto it = id_mark_it_.find(id);
    if (it == id_mark_it_.end()) return;
    auto& mark_it = it->second;
    for (auto itt = mark_it.begin(); itt != mark_it.end();) {
      info_.erase(itt->second);
      itt = mark_it.erase(itt);
    }
    id_mark_it_.erase(it);
  }
  void del_mark(const int64_t id, const string& mark, bool einfo) {
    if (auto it = id_mark_it_.find(id); it != id_mark_it_.end()) {
      auto& mark_it = it->second;
      if (auto itt = mark_it.find(mark); itt != mark_it.end()) {
        if (einfo) {
          info_.erase(itt->second);
        }
        mark_it.erase(itt);
      }
      if (mark_it.empty()) {
        id_mark_it_.erase(it);
      }
    }
  }
};

static const char* META = "LTIMER";
struct Ltimer {
  static int create(lua_State*);
  static void meta(lua_State*);
  static int gc(lua_State*);

  static int add(lua_State*);
  static int del_mark(lua_State*);
  static int del_id(lua_State*);
  static int expire(lua_State*);
  static int info(lua_State*);
};

int Ltimer::expire(lua_State* L) {
  Timer** pp = (Timer**)luaL_checkudata(L, 1, META);
  Timer& timer = **pp;
  uint64_t tm = luaL_checkinteger(L, 2);

  lua_createtable(L, 0, 0);
  int i = 0;
  auto& info = timer.info_;
  for (auto it = info.begin(); it != info.end();) {
    const auto& ele = *it;
    if (tm >= ele.tm_) {
      const int64_t id = ele.id_;
      const string& mark = ele.mark_;
      timer.del_mark(id, mark, false);
      lua_pushinteger(L, id);
      lua_rawseti(L, -2, ++i);
      lua_pushlstring(L, mark.data(), mark.size());
      lua_rawseti(L, -2, ++i);
      it = info.erase(it);
    } else {
      break;
    }
  }
  return 1;
}

int Ltimer::del_id(lua_State* L) {
  Timer** pp = (Timer**)luaL_checkudata(L, 1, META);
  Timer& timer = **pp;
  int64_t id = luaL_checkinteger(L, 2);
  timer.del_id(id);
  return 0;
}

int Ltimer::del_mark(lua_State* L) {
  Timer** pp = (Timer**)luaL_checkudata(L, 1, META);
  Timer& timer = **pp;
  int64_t id = luaL_checkinteger(L, 2);
  size_t mlen;
  const char* pm = luaL_checklstring(L, 3, &mlen);
  timer.del_mark(id, {pm, mlen}, true);
  return 0;
}

int Ltimer::add(lua_State* L) {
  Timer** pp = (Timer**)luaL_checkudata(L, 1, META);
  Timer& timer = **pp;
  int64_t id = luaL_checkinteger(L, 2);
  uint64_t tm = luaL_checkinteger(L, 3);
  size_t mlen;
  const char* pm = luaL_checklstring(L, 4, &mlen);
  timer.add({.id_ = id, .mark_ = {pm, mlen}, .tm_ = tm});
  return 0;
}

int Ltimer::info(lua_State* L) {
  Timer** pp = (Timer**)luaL_checkudata(L, 1, META);
  Timer& timer = **pp;
  lua_createtable(L, 0, 0);
  int i = 0;
  lua_pushinteger(L, timer.info_.size());
  lua_rawseti(L, -2, ++i);
  for (auto& [id, val] : timer.id_mark_it_) {
    lua_pushinteger(L, id);
    lua_rawseti(L, -2, ++i);
    lua_pushinteger(L, val.size());
    lua_rawseti(L, -2, ++i);
  }
  return 1;
}

int Ltimer::gc(lua_State* L) {
  Timer** pp = (Timer**)luaL_checkudata(L, 1, META);
  delete *pp;
  return 0;
}

void Ltimer::meta(lua_State* L) {
  if (luaL_newmetatable(L, META)) {
    luaL_Reg l[] = {{"add", add},       {"del_mark", del_mark},
                    {"del_id", del_id}, {"expire", expire},
                    {"info", info},     {NULL, NULL}};
    luaL_newlib(L, l);
    lua_setfield(L, -2, "__index");
    lua_pushcfunction(L, gc);
    lua_setfield(L, -2, "__gc");
  }
  lua_setmetatable(L, -2);
}

int Ltimer::create(lua_State* L) {
  Timer* p = new Timer();
  Timer** pp = (Timer**)lua_newuserdata(L, sizeof(p));
  *pp = p;
  meta(L);
  return 1;
}

extern "C" {
LUAMOD_API int luaopen_lgame_timer(lua_State* L) {
  luaL_Reg l[] = {{"create", Ltimer::create}, {NULL, NULL}};
  luaL_newlib(L, l);
  return 1;
}
}