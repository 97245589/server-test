#include <string.h>
#include "ikcp.h"
#include "lauxlib.h"

static const char* META = "LKCP";
#define _addrlen 20
typedef struct Lkcp {
  ikcpcb* pkcp;
  lua_State* L;
  int id;
} Lkcp;

static int gc(lua_State* L) {
  Lkcp* p = (Lkcp*)luaL_checkudata(L, 1, META);
  ikcp_release(p->pkcp);
  return 0;
}

static int send(lua_State* L) {
  Lkcp* p = (Lkcp*)luaL_checkudata(L, 1, META);
  size_t len = 0;
  const char* pstr = luaL_checklstring(L, 2, &len);
  ikcp_send(p->pkcp, pstr, len);
  return 0;
}

static int update(lua_State* L) {
  Lkcp* p = (Lkcp*)luaL_checkudata(L, 1, META);
  int64_t i = luaL_checkinteger(L, 2);
  p->L = L;
  ikcp_update(p->pkcp, i * 10);
  return 0;
}

static int input(lua_State* L) {
  Lkcp* p = (Lkcp*)luaL_checkudata(L, 1, META);
  size_t slen;
  const char* pstr = luaL_checklstring(L, 2, &slen);
  ikcp_input(p->pkcp, pstr, slen);
  return 0;
}

static int recv(lua_State* L) {
  Lkcp* p = (Lkcp*)luaL_checkudata(L, 1, META);
  char buf[1024 * 100];
  int len = ikcp_recv(p->pkcp, buf, sizeof(buf));
  if (len > 0) {
    lua_pushlstring(L, buf, len);
    return 1;
  } else if (len == -3) {
    return luaL_error(L, "kcp buf size more than 100k");
  } else {
    return 0;
  }
}

static int outputcb(const char* buf, int len, ikcpcb* kcp, void* user) {
  Lkcp* p = (Lkcp*)user;
  lua_State* L = p->L;
  lua_getiuservalue(L, 1, 1);
  lua_pushinteger(L, p->id);
  lua_pushlstring(L, buf, len);
  lua_call(L, 2, 0);
  return 0;
}

static int create(lua_State* L) {
  int conv = luaL_checkinteger(L, 1);
  int id = luaL_checkinteger(L, 2);
  luaL_checktype(L, 3, LUA_TFUNCTION);
  Lkcp* p = (Lkcp*)lua_newuserdatauv(L, sizeof(Lkcp), 1);
  lua_pushvalue(L, 3);
  lua_setiuservalue(L, -2, 1);
  p->id = id;

  ikcpcb* pkcp = ikcp_create(conv, p);
  pkcp->output = outputcb;
  ikcp_nodelay(pkcp, 2, 10, 2, 1);
  p->pkcp = pkcp;
  if (luaL_newmetatable(L, META)) {
    luaL_Reg l[] = {{"send", send},
                    {"recv", recv},
                    {"update", update},
                    {"input", input},
                    {NULL, NULL}};
    luaL_newlib(L, l);
    lua_setfield(L, -2, "__index");
    lua_pushcfunction(L, gc);
    lua_setfield(L, -2, "__gc");
  }
  lua_setmetatable(L, -2);
  return 1;
}

LUAMOD_API int luaopen_lgame_kcp(lua_State* L) {
  luaL_Reg l[] = {{"create", create}, {NULL, NULL}};
  luaL_newlib(L, l);
  return 1;
}