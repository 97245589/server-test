extern "C" {
#include "lauxlib.h"
}
#include <iostream>
#include <set>
#include <sstream>
#include <string>
using namespace std;

struct Timer {
  struct Ele {
    int64_t id_;
    int64_t tm_;
    string info_;
    bool operator<(const Ele& rhs) const {
      if (id_ != rhs.id_) return id_ < rhs.id_;
      return info_ < rhs.info_;
    }
  };

  using miter = set<Ele>::iterator;
  struct Itercmp {
    bool operator()(miter lhs, miter rhs) const {
      if (lhs->tm_ != rhs->tm_) return lhs->tm_ < rhs->tm_;
      if (lhs->id_ != rhs->id_) return lhs->id_ < rhs->id_;
      return lhs->info_ < rhs->info_;
    }
  };

  set<Ele> timer_;
  set<miter, Itercmp> iter_;

  void del(const Ele& ele) {
    auto it = timer_.find(ele);
    if (it == timer_.end()) return;
    iter_.erase(it);
    timer_.erase(it);
  }

  void add(const Ele& ele) {
    del(ele);
    auto [it, ok] = timer_.insert(ele);
    if (ok) iter_.insert(it);
  }

  void delid(int64_t id) {
    Ele ele{.id_ = id};
    for (auto it = timer_.lower_bound(ele); it != timer_.end();) {
      if (it->id_ == id) {
        iter_.erase(it);
        it = timer_.erase(it);
      } else {
        break;
      }
    }
  }

  string dump() {
    ostringstream oss;
    oss << "timer:" << timer_.size() << " " << iter_.size() << endl;
    for (auto& ele : timer_) {
      oss << ele.id_ << "," << ele.tm_ << "," << ele.info_ << " ";
    }
    oss << endl;
    return oss.str();
  }
};

static const char* META = "LTIMER";

static int add(lua_State* L) {
  Timer** pp = (Timer**)luaL_checkudata(L, 1, META);
  int64_t id = luaL_checkinteger(L, 2);
  int64_t tm = luaL_checkinteger(L, 3);
  size_t len;
  const char* p = luaL_checklstring(L, 4, &len);

  Timer& timer = **pp;
  timer.add({id, tm, {p, len}});
  return 0;
}

static int del(lua_State* L) {
  Timer** pp = (Timer**)luaL_checkudata(L, 1, META);
  int64_t id = luaL_checkinteger(L, 2);
  size_t len;
  const char* p = luaL_checklstring(L, 3, &len);

  Timer& timer = **pp;
  timer.del({id, 0, {p, len}});
  return 0;
}

static int delid(lua_State* L) {
  Timer** pp = (Timer**)luaL_checkudata(L, 1, META);
  int64_t id = luaL_checkinteger(L, 2);
  Timer& timer = **pp;
  timer.delid(id);
  return 0;
}

static int expire(lua_State* L) {
  Timer** pp = (Timer**)luaL_checkudata(L, 1, META);
  int64_t tm = luaL_checkinteger(L, 2);

  lua_createtable(L, 32, 0);
  int c = 0;
  Timer& timer = **pp;
  auto& iter_ = timer.iter_;
  for (auto it = iter_.begin(); it != iter_.end();) {
    auto& ele = **it;
    if (tm >= ele.tm_) {
      lua_pushinteger(L, ele.id_);
      lua_rawseti(L, -2, ++c);
      const string& info = ele.info_;
      lua_pushlstring(L, info.data(), info.size());
      lua_rawseti(L, -2, ++c);
      timer.timer_.erase(*it);
      it = iter_.erase(it);
    } else {
      break;
    }
  }
  return 1;
}

static int dump(lua_State* L) {
  Timer** pp = (Timer**)luaL_checkudata(L, 1, META);
  Timer& timer = **pp;
  string ret = timer.dump();
  lua_pushlstring(L, ret.data(), ret.size());
  return 1;
}

static int gc(lua_State* L) {
  Timer** pp = (Timer**)luaL_checkudata(L, 1, META);
  delete *pp;
  return 0;
}

static int create(lua_State* L) {
  Timer* p = new Timer();
  Timer** pp = (Timer**)lua_newuserdata(L, sizeof(p));
  *pp = p;
  if (luaL_newmetatable(L, META)) {
    luaL_Reg l[] = {{"add", add},       {"del", del},   {"delid", delid},
                    {"expire", expire}, {"dump", dump}, {NULL, NULL}};
    luaL_newlib(L, l);
    lua_setfield(L, -2, "__index");
    lua_pushcfunction(L, gc);
    lua_setfield(L, 2, "__gc");
  }
  lua_setmetatable(L, -2);
  return 1;
}

extern "C" {
LUAMOD_API int luaopen_lgame_timer(lua_State* L) {
  luaL_Reg l[] = {{"create", create}, {NULL, NULL}};
  luaL_newlib(L, l);
  return 1;
}
}