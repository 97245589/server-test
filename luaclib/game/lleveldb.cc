extern "C" {
#include <fnmatch.h>

#include "lauxlib.h"
}

#include <functional>
#include <string>
#include <vector>
using namespace std;

#include "leveldb/db.h"
#include "leveldb/write_batch.h"

static const char SPLIT = 0xff;
struct Lleveldb {
  leveldb::DB* db_;
};

static int compact(lua_State* L) {
  luaL_checktype(L, 1, LUA_TLIGHTUSERDATA);
  Lleveldb* p = (Lleveldb*)lua_touserdata(L, 1);
  leveldb::DB* db = p->db_;
  db->CompactRange(nullptr, nullptr);
  return 0;
}

static void search_key(leveldb::DB* db, string& str,
                       function<void(string&, string&, string&)> func) {
  string start = str + SPLIT;
  string end = start + char(0xff);

  leveldb::Iterator* it = db->NewIterator(leveldb::ReadOptions());
  for (it->Seek(start); it->Valid() && it->key().ToString() < end; it->Next()) {
    string k = it->key().ToString();
    if (k.size() <= start.size()) {
      continue;
    }
    if (k.substr(0, start.size()) != start) {
      continue;
    }
    string key = k.substr(start.size());
    string val = it->value().ToString();
    func(key, val, k);
  }
  delete it;
}

static int hgetall(lua_State* L) {
  luaL_checktype(L, 1, LUA_TLIGHTUSERDATA);
  Lleveldb* p = (Lleveldb*)lua_touserdata(L, 1);
  size_t len;
  const char* ps = luaL_checklstring(L, 2, &len);

  leveldb::DB* db = p->db_;
  string str(ps, len);
  lua_createtable(L, 16, 0);
  int i = 0;
  search_key(db, str, [&](string& key, string& val, string& realkey) {
    lua_pushlstring(L, key.data(), key.size());
    lua_rawseti(L, -2, ++i);
    lua_pushlstring(L, val.data(), val.size());
    lua_rawseti(L, -2, ++i);
  });
  return 1;
}

static int hkeys(lua_State* L) {
  luaL_checktype(L, 1, LUA_TLIGHTUSERDATA);
  Lleveldb* p = (Lleveldb*)lua_touserdata(L, 1);
  size_t len;
  const char* ps = luaL_checklstring(L, 2, &len);

  leveldb::DB* db = p->db_;
  string str(ps, len);
  lua_createtable(L, 16, 0);
  int i = 0;
  search_key(db, str, [&](string& key, string& val, string& realkey) {
    lua_pushlstring(L, key.data(), key.size());
    lua_rawseti(L, -2, ++i);
  });
  return 1;
}

static int del(lua_State* L) {
  luaL_checktype(L, 1, LUA_TLIGHTUSERDATA);
  Lleveldb* p = (Lleveldb*)lua_touserdata(L, 1);
  size_t len;
  const char* ps = luaL_checklstring(L, 2, &len);

  leveldb::DB* db = p->db_;
  string str(ps, len);
  leveldb::WriteBatch batch;
  search_key(db, str, [&](string& key, string& val, string& realkey) {
    batch.Delete(realkey);
  });
  db->Write(leveldb::WriteOptions(), &batch);
  return 0;
}

static int keys(lua_State* L) {
  luaL_checktype(L, 1, LUA_TLIGHTUSERDATA);
  Lleveldb* p = (Lleveldb*)lua_touserdata(L, 1);
  size_t len;
  const char* ps = luaL_checklstring(L, 2, &len);

  leveldb::DB* db = p->db_;
  string patt(ps, len);
  vector<string> keys;
  keys.reserve(16);
  leveldb::Iterator* it = db->NewIterator(leveldb::ReadOptions());
  for (it->SeekToFirst(); it->Valid(); it->Next()) {
    string k = it->key().ToString();
    int p = k.find(SPLIT);
    if (p < 0 || p >= k.size() - 1) continue;
    string key = k.substr(0, p);
    if (0 != fnmatch(patt.data(), key.data(), 0)) continue;
    if (keys.empty() || keys.back() != key) {
      keys.push_back(key);
    }
  }
  delete it;

  lua_createtable(L, keys.size(), 0);
  int i = 0;
  for (string& key : keys) {
    lua_pushlstring(L, key.data(), key.size());
    lua_rawseti(L, -2, ++i);
  }
  return 1;
}

static int hmset(lua_State* L) {
  luaL_checktype(L, 1, LUA_TLIGHTUSERDATA);
  Lleveldb* p = (Lleveldb*)lua_touserdata(L, 1);
  leveldb::DB* db = p->db_;

  int pnum = lua_gettop(L);
  if (pnum < 4 || pnum % 2 != 0) {
    return luaL_error(L, "leveldb hmset len arr");
  }
  size_t lk;
  const char* pk = luaL_checklstring(L, 2, &lk);
  string key(pk, lk);

  leveldb::WriteBatch batch;
  for (int i = 3; i < pnum; i += 2) {
    size_t lhk;
    const char* phk = luaL_checklstring(L, i, &lhk);
    string hkey(phk, lhk);
    string rkey = key + SPLIT + hkey;
    size_t lv;
    const char* pv = luaL_checklstring(L, i + 1, &lv);
    string val(pv, lv);
    batch.Put(rkey, val);
  }
  db->Write(leveldb::WriteOptions(), &batch);
  return 0;
}

static int hget(lua_State* L) {
  luaL_checktype(L, 1, LUA_TLIGHTUSERDATA);
  Lleveldb* p = (Lleveldb*)lua_touserdata(L, 1);
  leveldb::DB* db = p->db_;

  size_t lk;
  const char* pk = luaL_checklstring(L, 2, &lk);
  string key(pk, lk);
  size_t hk;
  const char* phk = luaL_checklstring(L, 3, &hk);
  string hkey(phk, hk);
  string rkey = key + SPLIT + hkey;
  string val;
  leveldb::Status s = db->Get(leveldb::ReadOptions(), rkey, &val);
  if (!s.ok()) return 0;
  lua_pushlstring(L, val.data(), val.size());
  return 1;
}

static int hmget(lua_State* L) {
  luaL_checktype(L, 1, LUA_TLIGHTUSERDATA);
  Lleveldb* p = (Lleveldb*)lua_touserdata(L, 1);
  leveldb::DB* db = p->db_;

  int pnum = lua_gettop(L);
  if (pnum < 3) {
    return luaL_error(L, "leveldb hmget len arr");
  }

  size_t lk;
  const char* pk = luaL_checklstring(L, 2, &lk);
  string key(pk, lk);
  lua_createtable(L, pnum - 2, 0);
  for (int i = 3; i <= pnum; ++i) {
    size_t lhk;
    const char* phk = luaL_checklstring(L, i, &lhk);
    string hkey(phk, lhk);
    string rkey = key + SPLIT + hkey;
    string val;
    leveldb::Status s = db->Get(leveldb::ReadOptions(), rkey, &val);
    if (s.ok()) {
      lua_pushlstring(L, val.data(), val.size());
    } else {
      lua_pushnil(L);
    }
    lua_rawseti(L, -2, i - 2);
  }
  return 1;
}

static int hdel(lua_State* L) {
  luaL_checktype(L, 1, LUA_TLIGHTUSERDATA);
  Lleveldb* p = (Lleveldb*)lua_touserdata(L, 1);
  leveldb::DB* db = p->db_;

  int pnum = lua_gettop(L);
  if (pnum < 3) {
    return luaL_error(L, "leveldb hdel len arr");
  }

  size_t lk;
  const char* pk = luaL_checklstring(L, 2, &lk);
  string key(pk, lk);
  leveldb::WriteBatch batch;
  for (int i = 3; i <= pnum; ++i) {
    size_t lhk;
    const char* phk = luaL_checklstring(L, i, &lhk);
    string hkey(phk, lhk);
    string rkey = key + SPLIT + hkey;
    batch.Delete(rkey);
  }
  db->Write(leveldb::WriteOptions(), &batch);
  return 0;
}

static int create(lua_State* L) {
  size_t len;
  const char* pname = luaL_checklstring(L, 1, &len);

  leveldb::DB* db;
  leveldb::Options options;
  options.create_if_missing = true;
  options.compression = leveldb::kZstdCompression;
  options.zstd_compression_level = 1;
  options.write_buffer_size = 10 * 1024 * 1024;
  options.max_file_size = 5 * 1024 * 1024;
  options.block_size = 20 * 1024;
  leveldb::Status status = leveldb::DB::Open(options, {pname, len}, &db);

  if (!status.ok()) {
    return luaL_error(L, "leveldb open err");
  }
  Lleveldb* p = new Lleveldb();
  p->db_ = db;
  lua_pushlightuserdata(L, p);
  return 1;
}

static int release(lua_State* L) {
  luaL_checktype(L, 1, LUA_TLIGHTUSERDATA);
  Lleveldb* p = (Lleveldb*)lua_touserdata(L, 1);
  delete p->db_;
  delete p;
  return 0;
}

extern "C" {
LUAMOD_API int luaopen_lgame_leveldb(lua_State* L) {
  luaL_Reg l[] = {
      {"create", create}, {"release", release}, {"compact", compact},
      {"keys", keys},     {"del", del},         {"hgetall", hgetall},
      {"hkeys", hkeys},   {"hget", hget},       {"hmget", hmget},
      {"hset", hmset},    {"hmset", hmset},     {"hdel", hdel},
      {NULL, NULL}};
  luaL_newlib(L, l);
  return 1;
}
}