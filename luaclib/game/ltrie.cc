extern "C" {
#include "lauxlib.h"
}

#include <cstdint>
#include <ext/pb_ds/assoc_container.hpp>
#include <ext/pb_ds/trie_policy.hpp>
using namespace std;

using Trie =
    __gnu_pbds::trie<string, int64_t, __gnu_pbds::trie_string_access_traits<>,
                     __gnu_pbds::pat_trie_tag,
                     __gnu_pbds::trie_prefix_search_node_update>;

static const char* META = "LTRIE";
struct Ltrie {
  static int create(lua_State*);
  static int gc(lua_State*);

  static int insert(lua_State*);
  static int erase(lua_State*);
  static int value(lua_State*);
  static int prefix(lua_State*);
  static int seri(lua_State*);
  static int deseri(lua_State*);
};

int Ltrie::seri(lua_State* L) {
  Trie** pp = (Trie**)luaL_checkudata(L, 1, META);
  Trie& trie = **pp;

  string buf;
  buf.reserve(1024);
  for (auto& [k, v] : trie) {
    uint16_t klen = k.size();
    buf.append((char*)&klen, sizeof(klen));
    buf.append(k.data(), klen);
    buf.append((char*)&v, sizeof(v));
  }
  lua_pushlstring(L, buf.data(), buf.size());
  return 1;
}

int Ltrie::deseri(lua_State* L) {
  Trie** pp = (Trie**)luaL_checkudata(L, 1, META);
  size_t len;
  const char* p = luaL_checklstring(L, 2, &len);

  Trie& trie = **pp;
  char* ps = (char*)p;
  char* pe = ps + len;
  while (ps < pe) {
    uint16_t klen = *(uint16_t*)ps;
    ps += sizeof(klen);
    char* pk = ps;
    ps += klen;
    int64_t v = *(int64_t*)ps;
    ps += sizeof(v);
    trie[{pk, klen}] = v;
  }
  return 0;
}

int Ltrie::prefix(lua_State* L) {
  Trie** pp = (Trie**)luaL_checkudata(L, 1, META);
  size_t len;
  const char* p = luaL_checklstring(L, 2, &len);
  int num = luaL_checkinteger(L, 3);

  Trie& trie = **pp;
  string pre(p, len);
  auto pair = trie.prefix_range(pre);
  int c = 0;
  lua_createtable(L, 16, 0);
  for (auto it = pair.first; it != pair.second; ++it) {
    const string& k = it->first;
    lua_pushlstring(L, k.data(), k.size());
    lua_rawseti(L, -2, ++c);
    int64_t v = it->second;
    lua_pushinteger(L, v);
    lua_rawseti(L, -2, ++c);
    if (num > 0 && c / 2 >= num) break;
  }
  return 1;
}

int Ltrie::insert(lua_State* L) {
  Trie** pp = (Trie**)luaL_checkudata(L, 1, META);
  size_t klen;
  const char* pk = luaL_checklstring(L, 2, &klen);
  if (klen > UINT16_MAX) return luaL_error(L, "trie k too long");
  int64_t v = luaL_checkinteger(L, 3);

  Trie& trie = **pp;
  string k(pk, klen);
  trie[k] = v;
  return 0;
}

int Ltrie::erase(lua_State* L) {
  Trie** pp = (Trie**)luaL_checkudata(L, 1, META);
  size_t klen;
  const char* pk = luaL_checklstring(L, 2, &klen);
  Trie& trie = **pp;
  string k(pk, klen);
  trie.erase(k);
  return 0;
}

int Ltrie::value(lua_State* L) {
  Trie** pp = (Trie**)luaL_checkudata(L, 1, META);
  size_t klen;
  const char* pk = luaL_checklstring(L, 2, &klen);
  Trie& trie = **pp;
  string k(pk, klen);
  auto it = trie.find(k);
  if (it == trie.end()) return 0;
  lua_pushinteger(L, it->second);
  return 1;
}

int Ltrie::gc(lua_State* L) {
  Trie** pp = (Trie**)luaL_checkudata(L, 1, META);
  delete *pp;
  return 0;
}

int Ltrie::create(lua_State* L) {
  Trie* p = new Trie();
  Trie** pp = (Trie**)lua_newuserdata(L, sizeof(p));
  *pp = p;
  if (luaL_newmetatable(L, META)) {
    luaL_Reg l[] = {{"insert", insert}, {"erase", erase}, {"value", value},
                    {"prefix", prefix}, {"seri", seri},   {"deseri", deseri},
                    {NULL, NULL}};
    luaL_newlib(L, l);
    lua_setfield(L, -2, "__index");
    lua_pushcfunction(L, gc);
    lua_setfield(L, -2, "__gc");
  }
  lua_setmetatable(L, -2);
  return 1;
}

extern "C" {
LUAMOD_API int luaopen_lgame_trie(lua_State* L) {
  luaL_Reg l[] = {{"create", Ltrie::create}, {NULL, NULL}};
  luaL_newlib(L, l);
  return 1;
}
}