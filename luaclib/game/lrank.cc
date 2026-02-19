extern "C" {
#include "lauxlib.h"
}

#include <cstdint>
#include <ext/pb_ds/assoc_container.hpp>
#include <ext/pb_ds/tree_policy.hpp>
#include <string>
#include <tuple>
#include <unordered_map>
using namespace std;

#include "zstdwrap.h"

struct Rank {
  struct Rankele {
    int64_t id_;
    int64_t score_;
    int64_t tm_;

    bool operator<(const Rankele& rhs) const {
      if (score_ != rhs.score_) return score_ > rhs.score_;
      if (tm_ != rhs.tm_) return tm_ < rhs.tm_;
      return id_ < rhs.id_;
    }
  };

  template <class T>
  using ordered_set =
      __gnu_pbds::tree<T, __gnu_pbds::null_type, less<T>,
                       __gnu_pbds::rb_tree_tag,
                       __gnu_pbds::tree_order_statistics_node_update>;

  ordered_set<Rankele> ranks_;
  unordered_map<int64_t, ordered_set<Rankele>::iterator> id_it_;
  int32_t max_;

  void add(const Rankele& ele) {
    if (auto it = id_it_.find(ele.id_); it != id_it_.end()) {
      ranks_.erase(it->second);
      id_it_.erase(ele.id_);
    }
    auto [it, ok] = ranks_.insert(ele);
    id_it_.insert({ele.id_, it});
    evict();
  }

  void evict() {
    if (ranks_.size() <= max_) return;
    auto lastit = prev(ranks_.end());
    id_it_.erase(lastit->id_);
    ranks_.erase(lastit);
  }

  tuple<int32_t, int64_t> get_order(const int64_t id) {
    auto it = id_it_.find(id);
    if (it == id_it_.end()) return make_tuple(-1, 0);
    auto& val = *it->second;
    int32_t order = ranks_.order_of_key(val) + 1;
    return make_tuple(order, val.score_);
  }
};

static const char* META = "LRANK_META";
struct Lrank {
  static int create(lua_State*);
  static void meta(lua_State*);
  static int gc(lua_State*);

  static int add(lua_State*);
  static int order(lua_State*);
  static int info(lua_State*);
  static int seri(lua_State*);
  static int deseri(lua_State*);
};

int Lrank::seri(lua_State* L) {
  Rank** pp = (Rank**)luaL_checkudata(L, 1, META);
  Rank& rank = **pp;

  auto& ranks = rank.ranks_;
  string buff;
  buff.reserve(1024 * 2);
  for (auto& ele : ranks) {
    buff.append((const char*)&ele, sizeof(ele));
  }
  string bin = Zstdwrap::compress(buff.data(), buff.size());
  lua_pushlstring(L, bin.data(), bin.size());
  return 1;
}

int Lrank::deseri(lua_State* L) {
  Rank** pp = (Rank**)luaL_checkudata(L, 1, META);
  Rank& rank = **pp;
  size_t len;
  const char* p = luaL_checklstring(L, 2, &len);
  string buff = Zstdwrap::decompress(p, len);

  const char* pstart = buff.data();
  const char* pend = pstart + buff.size();
  while (pstart < pend) {
    Rank::Rankele ele = *(Rank::Rankele*)pstart;
    rank.add(ele);
    pstart += sizeof(ele);
  }
  return 0;
}

int Lrank::info(lua_State* L) {
  Rank** pp = (Rank**)luaL_checkudata(L, 1, META);
  Rank& rank = **pp;
  auto& ranks = rank.ranks_;
  int lb = luaL_checkinteger(L, 2) - 1;
  int ub = luaL_checkinteger(L, 3);
  if (ub > ranks.size()) ub = ranks.size();
  lua_createtable(L, (ub - lb) * 3, 0);
  int c = 0;
  for (auto it = ranks.find_by_order(lb); it != ranks.find_by_order(ub); ++it) {
    const auto& id = it->id_;
    lua_pushinteger(L, id);
    lua_rawseti(L, -2, ++c);
    lua_pushinteger(L, it->score_);
    lua_rawseti(L, -2, ++c);
    // lua_pushinteger(L, it->tm_);
    // lua_rawseti(L, -2, ++c);
  }
  return 1;
}

int Lrank::order(lua_State* L) {
  Rank** pp = (Rank**)luaL_checkudata(L, 1, META);
  Rank& rank = **pp;

  int64_t id = luaL_checkinteger(L, 2);
  auto [order, score] = rank.get_order(id);
  if (order <= 0) return 0;
  lua_pushinteger(L, order);
  lua_pushinteger(L, score);
  return 2;
}

int Lrank::add(lua_State* L) {
  Rank** pp = (Rank**)luaL_checkudata(L, 1, META);
  Rank& rank = **pp;

  int64_t id = luaL_checkinteger(L, 2);
  int64_t score = luaL_checkinteger(L, 3);
  int64_t tm = luaL_checkinteger(L, 4);
  rank.add({.id_ = id, .score_ = score, .tm_ = tm});
  return 0;
}

int Lrank::gc(lua_State* L) {
  Rank** pp = (Rank**)luaL_checkudata(L, 1, META);
  delete *pp;
  return 0;
}

void Lrank::meta(lua_State* L) {
  if (luaL_newmetatable(L, META)) {
    luaL_Reg l[] = {{"add", add},   {"order", order},   {"info", info},
                    {"seri", seri}, {"deseri", deseri}, {NULL, NULL}};
    luaL_newlib(L, l);
    lua_setfield(L, -2, "__index");
    lua_pushcfunction(L, gc);
    lua_setfield(L, -2, "__gc");
  }
  lua_setmetatable(L, -2);
}

int Lrank::create(lua_State* L) {
  int num = luaL_checkinteger(L, 1);
  if (num <= 0) return luaL_error(L, "lrank create err");

  Rank* p = new Rank();
  p->max_ = num;
  Rank** pp = (Rank**)lua_newuserdata(L, sizeof(p));
  *pp = p;
  meta(L);
  return 1;
}

extern "C" {
LUAMOD_API int luaopen_lgame_rank(lua_State* L) {
  luaL_Reg funcs[] = {{"create", Lrank::create}, {NULL, NULL}};
  luaL_newlib(L, funcs);
  return 1;
}
}