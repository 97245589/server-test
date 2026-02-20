#include <string.h>

#include "ikcp.h"
#include "lauxlib.h"
#include "skynet.h"
#include "skynet_socket.h"

static const char* META = "LKCP";
#define _addrlen 20
typedef struct Lkcp {
  ikcpcb* pkcp;
  struct skynet_context* ctx;
  int host;
  int conv;
  char address[_addrlen];
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

static void meta(lua_State* L) {
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
}

static int servercb(const char* buf, int len, ikcpcb* kcp, void* user) {
  Lkcp* p = (Lkcp*)user;
  struct socket_sendbuffer sbuf;
  sbuf.id = p->host;
  sbuf.type = SOCKET_BUFFER_RAWPOINTER;
  sbuf.buffer = buf;
  sbuf.sz = len;
  int err = skynet_socket_udp_sendbuffer(p->ctx, p->address, &sbuf);
  return 0;
}

static int server(lua_State* L) {
  lua_getfield(L, LUA_REGISTRYINDEX, "skynet_context");
  struct skynet_context* ctx = (struct skynet_context*)lua_touserdata(L, -1);
  if (ctx == NULL) {
    return luaL_error(L, "Init skynet context first");
  }
  int conv = luaL_checkinteger(L, 1);
  int host = luaL_checkinteger(L, 2);
  size_t addrlen;
  const char* paddr = luaL_checklstring(L, 3, &addrlen);
  if (addrlen >= _addrlen) {
    return luaL_error(L, "kcp address len error");
  }

  Lkcp* p = (Lkcp*)lua_newuserdata(L, sizeof(Lkcp));
  p->ctx = ctx;
  p->conv = conv;
  p->host = host;
  memcpy(p->address, paddr, addrlen);
  ikcpcb* pkcp = ikcp_create(conv, p);
  pkcp->output = servercb;
  ikcp_nodelay(pkcp, 2, 10, 2, 1);
  p->pkcp = pkcp;
  meta(L);
  return 1;
}

static int clientcb(const char* buf, int len, ikcpcb* kcp, void* user) {
  Lkcp* p = (Lkcp*)user;
  struct socket_sendbuffer sbuf;
  sbuf.id = p->host;
  sbuf.type = SOCKET_BUFFER_RAWPOINTER;
  sbuf.buffer = buf;
  sbuf.sz = len;
  int err = skynet_socket_sendbuffer(p->ctx, &sbuf);
  return 0;
}

static int client(lua_State* L) {
  lua_getfield(L, LUA_REGISTRYINDEX, "skynet_context");
  struct skynet_context* ctx = (struct skynet_context*)lua_touserdata(L, -1);
  if (ctx == NULL) {
    return luaL_error(L, "Init skynet context first");
  }
  int conv = luaL_checkinteger(L, 1);
  int host = luaL_checkinteger(L, 2);
  Lkcp* p = (Lkcp*)lua_newuserdata(L, sizeof(Lkcp));
  p->ctx = ctx;
  p->conv = conv;
  p->host = host;
  ikcpcb* pkcp = ikcp_create(conv, p);
  pkcp->output = clientcb;
  ikcp_nodelay(pkcp, 2, 10, 2, 1);
  p->pkcp = pkcp;
  meta(L);
  return 1;
}

LUAMOD_API int luaopen_lgame_kcp(lua_State* L) {
  luaL_Reg l[] = {{"client", client}, {"server", server}, {NULL, NULL}};
  luaL_newlib(L, l);
  return 1;
}