extern "C" {
#include "lauxlib.h"
}
#include <cstdint>
#include <string>

#include "tsl/htrie_map.h"
using namespace std;

using trie_map = tsl::htrie_map<char, int64_t>;
static const char* META = "LTRIEMAP";
struct Ltriemap {
  static int create(lua_State*);
  static void meta(lua_State*);
  static int gc(lua_State*);

  static int insert(lua_State*);
  static int val(lua_State*);
  static int erase(lua_State*);
  static int seri(lua_State*);
  static int deseri(lua_State*);
};

int Ltriemap::deseri(lua_State* L) {
  trie_map** pp = (trie_map**)luaL_checkudata(L, 1, META);
  trie_map& tmap = **pp;
  size_t slen;
  const char* pstr = luaL_checklstring(L, 2, &slen);

  const char* pstart = pstr;
  const char* pend = pstr + slen;
  while (pstart < pend) {
    uint32_t keysize = *(uint32_t*)pstart;
    pstart += sizeof(keysize);
    string key(pstart, keysize);
    pstart += keysize;
    int64_t val = *(int64_t*)pstart;
    pstart += sizeof(val);
    tmap.insert(key, val);
  }
  return 0;
}

int Ltriemap::seri(lua_State* L) {
  trie_map** pp = (trie_map**)luaL_checkudata(L, 1, META);
  trie_map& tmap = **pp;
  string str;
  str.reserve(1024);
  for (auto it = tmap.begin(); it != tmap.end(); ++it) {
    string key = it.key();
    int64_t val = *it;
    uint32_t keysize = key.size();
    str.append((const char*)&keysize, sizeof(keysize));
    str.append(key.data(), key.size());
    str.append((const char*)&val, sizeof(val));
  }
  lua_pushlstring(L, str.data(), str.size());
  return 1;
}

int Ltriemap::val(lua_State* L) {
  trie_map** pp = (trie_map**)luaL_checkudata(L, 1, META);
  trie_map& tmap = **pp;
  size_t slen;
  const char* pstr = luaL_checklstring(L, 2, &slen);
  if (auto it = tmap.find({pstr, slen}); it != tmap.end()) {
    lua_pushinteger(L, *it);
    return 1;
  } else {
    return 0;
  }
}

int Ltriemap::erase(lua_State* L) {
  trie_map** pp = (trie_map**)luaL_checkudata(L, 1, META);
  trie_map& tmap = **pp;
  size_t slen;
  const char* pstr = luaL_checklstring(L, 2, &slen);
  tmap.erase({pstr, slen});
  return 0;
}

int Ltriemap::insert(lua_State* L) {
  trie_map** pp = (trie_map**)luaL_checkudata(L, 1, META);
  trie_map& tmap = **pp;
  size_t slen;
  const char* pstr = luaL_checklstring(L, 2, &slen);
  int64_t id = luaL_checkinteger(L, 3);
  tmap.insert({pstr, slen}, id);
  return 0;
}

int Ltriemap::gc(lua_State* L) {
  trie_map** pp = (trie_map**)luaL_checkudata(L, 1, META);
  delete *pp;
  return 0;
}

void Ltriemap::meta(lua_State* L) {
  if (luaL_newmetatable(L, META)) {
    luaL_Reg l[] = {{"insert", insert}, {"erase", erase},   {"val", val},
                    {"seri", seri},     {"deseri", deseri}, {NULL, NULL}};
    luaL_newlib(L, l);
    lua_setfield(L, -2, "__index");
    lua_pushcfunction(L, gc);
    lua_setfield(L, -2, "__gc");
  }
  lua_setmetatable(L, -2);
}

int Ltriemap::create(lua_State* L) {
  trie_map* p = new trie_map();
  trie_map** pp = (trie_map**)lua_newuserdata(L, sizeof(p));
  *pp = p;
  meta(L);
  return 1;
}

extern "C" {
LUAMOD_API int luaopen_lgame_trie(lua_State* L) {
  luaL_Reg l[] = {{"create", Ltriemap::create}, {NULL, NULL}};
  luaL_newlib(L, l);
  return 1;
}
}