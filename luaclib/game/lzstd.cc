extern "C" {
#include "lauxlib.h"
}
#include "zstdwrap.h"

static int encode(lua_State* L) {
  size_t len;
  const char* p = luaL_checklstring(L, 1, &len);
  std::string ret = Zstdwrap::compress(p, len);
  lua_pushlstring(L, ret.data(), ret.size());
  return 1;
}

static int decode(lua_State* L) {
  size_t len;
  const char* p = luaL_checklstring(L, 1, &len);
  std::string ret = Zstdwrap::decompress(p, len);
  lua_pushlstring(L, ret.data(), ret.size());
  return 1;
}

LUAMOD_API int luaopen_lgame_zstd(lua_State* L) {
  luaL_Reg funcs[] = {
      {"compress", encode}, {"decompress", decode}, {NULL, NULL}};
  luaL_newlib(L, funcs);
  return 1;
}