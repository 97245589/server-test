extern "C" {
#include <stdlib.h>

#include "lauxlib.h"
#include "zstd.h"

static int compress(lua_State* L) {
  size_t cont_len;
  const char* pcont = luaL_checklstring(L, 1, &cont_len);

  int buff_len = ZSTD_compressBound(cont_len);
  void* pbuff = malloc(buff_len);
  int len = ZSTD_compress(pbuff, buff_len, pcont, cont_len, 1);

  lua_pushlstring(L, (const char*)pbuff, len);
  free(pbuff);
  return 1;
}

static int decompress(lua_State* L) {
  size_t cont_len;
  const char* pcont = luaL_checklstring(L, 1, &cont_len);

  int buff_len = ZSTD_getFrameContentSize(pcont, cont_len);
  void* pbuff = malloc(buff_len);
  int len = ZSTD_decompress(pbuff, buff_len, pcont, cont_len);

  lua_pushlstring(L, (const char*)pbuff, len);
  free(pbuff);
  return 1;
}

LUAMOD_API int luaopen_lgame_zstd(lua_State* L) {
  luaL_Reg funcs[] = {
      {"compress", compress}, {"decompress", decompress}, {NULL, NULL}};
  luaL_newlib(L, funcs);
  return 1;
}
}