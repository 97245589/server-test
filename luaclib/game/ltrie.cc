extern "C" {
#include "lauxlib.h"
}
#include <cstdint>
#include <sstream>
#include <string>
using namespace std;

#include "tsl/htrie_map.h"

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
  static int dump(lua_State*);
};

int Ltriemap::dump(lua_State* L) {
  trie_map** pp = (trie_map**)luaL_checkudata(L, 1, META);
  trie_map& tmap = **pp;
  ostringstream oss;
  oss << "trie dump: " << tmap.size() << endl;
  for (auto it = tmap.begin(); it != tmap.end(); ++it) {
    const string& key = it.key();
    oss << key << ":" << *it << " ";
  }
  const string& ret = oss.str();
  lua_pushlstring(L, ret.data(), ret.size());
  return 1;
}

int Ltriemap::seri(lua_State* L) {
  trie_map** pp = (trie_map**)luaL_checkudata(L, 1, META);
  trie_map& tmap = **pp;
  string buff;

  for (auto it = tmap.begin(); it != tmap.end(); ++it) {
    const string& key = it.key();
    int64_t v = *it;
    uint32_t len = key.size();
    buff.append((const char*)&len, sizeof(len));
    buff.append(key.data(), key.size());
    buff.append((const char*)&v, sizeof(v));
  }
  lua_pushlstring(L, buff.data(), buff.size());
  return 1;
}

int Ltriemap::deseri(lua_State* L) {
  trie_map** pp = (trie_map**)luaL_checkudata(L, 1, META);
  trie_map& tmap = **pp;
  size_t len;
  const char* p = luaL_checklstring(L, 2, &len);

  const char* pstart = p;
  const char* pend = p + len;
  while (pstart < pend) {
    uint32_t len = *(uint32_t*)pstart;
    pstart += sizeof(len);
    const char* pstr = pstart;
    pstart += len;
    int64_t id = *(int64_t*)pstart;
    pstart += sizeof(id);
    tmap.insert({pstr, len}, id);
  }
  return 0;
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
                    {"seri", seri},     {"deseri", deseri}, {"dump", dump},
                    {NULL, NULL}};
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