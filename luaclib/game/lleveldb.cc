extern "C" {
#include <fnmatch.h>

#include "lauxlib.h"
}

#include <functional>
#include <string>
#include <vector>
using namespace std;

#include "leveldb/cache.h"
#include "leveldb/db.h"
#include "leveldb/filter_policy.h"
#include "leveldb/write_batch.h"

struct Lleveldb {
  leveldb::DB* db_;
  leveldb::Cache* cache_;
  const leveldb::FilterPolicy* bloom_;

  static int create(lua_State*);
  static int release(lua_State*);

  static int compact(lua_State* L);
  static int keys(lua_State* L);
  static int del(lua_State* L);
  static int hgetall(lua_State* L);
  static int hmget(lua_State* L);
  static int hmset(lua_State* L);
  static int hdel(lua_State* L);

  static void search_key(
      leveldb::DB* db, const string& str,
      function<void(const string&, const string&, const string&)> func);

  const static char split_ = 0xff;
};

int Lleveldb::compact(lua_State* L) {
  if (!lua_islightuserdata(L, 1)) return luaL_error(L, "check lightuserdata");
  Lleveldb* p = (Lleveldb*)lua_touserdata(L, 1);
  leveldb::DB* db = p->db_;
  db->CompactRange(nullptr, nullptr);
  return 0;
}

void Lleveldb::search_key(
    leveldb::DB* db, const string& str,
    function<void(const string&, const string&, const string&)> func) {
  string start = str + split_;
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

int Lleveldb::hgetall(lua_State* L) {
  if (!lua_islightuserdata(L, 1)) return luaL_error(L, "check lightuserdata");
  Lleveldb* p = (Lleveldb*)lua_touserdata(L, 1);
  leveldb::DB* db = p->db_;

  size_t len;
  const char* ps = luaL_checklstring(L, 2, &len);
  string str(ps, len);

  lua_createtable(L, 0, 0);
  int i = 0;
  search_key(db, str,
             [&](const string& key, const string& val, const string& realkey) {
               lua_pushlstring(L, key.c_str(), key.size());
               lua_rawseti(L, -2, ++i);
               lua_pushlstring(L, val.c_str(), val.size());
               lua_rawseti(L, -2, ++i);
             });

  return 1;
}

int Lleveldb::del(lua_State* L) {
  if (!lua_islightuserdata(L, 1)) return luaL_error(L, "check lightuserdata");
  Lleveldb* p = (Lleveldb*)lua_touserdata(L, 1);
  leveldb::DB* db = p->db_;

  size_t len;
  const char* ps = luaL_checklstring(L, 2, &len);
  string str(ps, len);

  leveldb::WriteBatch batch;

  search_key(db, str,
             [&](const string& key, const string& val, const string& realkey) {
               batch.Delete(realkey);
             });

  db->Write(leveldb::WriteOptions(), &batch);
  return 0;
}

int Lleveldb::keys(lua_State* L) {
  if (!lua_islightuserdata(L, 1)) return luaL_error(L, "check lightuserdata");
  Lleveldb* p = (Lleveldb*)lua_touserdata(L, 1);
  leveldb::DB* db = p->db_;

  size_t len;
  const char* ppat = luaL_checklstring(L, 2, &len);
  string patt(ppat, len);

  vector<string> keys;
  leveldb::Iterator* it = db->NewIterator(leveldb::ReadOptions());
  for (it->SeekToFirst(); it->Valid(); it->Next()) {
    string k = it->key().ToString();
    int p = k.find(split_);
    if (p < 0 || p >= k.size() - 1) continue;

    string key = k.substr(0, p);
    if (0 != fnmatch(patt.c_str(), key.c_str(), 0)) continue;
    if (keys.empty() || keys.back() != key) {
      keys.push_back(key);
    }
  }
  delete it;

  lua_createtable(L, keys.size(), 0);
  int i = 0;
  for (string& key : keys) {
    lua_pushlstring(L, key.c_str(), key.size());
    lua_rawseti(L, -2, ++i);
  }
  return 1;
}

int Lleveldb::hmset(lua_State* L) {
  if (!lua_islightuserdata(L, 1)) return luaL_error(L, "check lightuserdata");
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
    string rkey = key + split_ + hkey;
    size_t lv;
    const char* pv = luaL_checklstring(L, i + 1, &lv);
    string val(pv, lv);
    batch.Put(rkey, val);
  }
  db->Write(leveldb::WriteOptions(), &batch);
  return 0;
}

int Lleveldb::hmget(lua_State* L) {
  if (!lua_islightuserdata(L, 1)) return luaL_error(L, "check lightuserdata");
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
    string rkey = key + split_ + hkey;
    string val;
    leveldb::Status s = db->Get(leveldb::ReadOptions(), rkey, &val);
    if (s.ok()) {
      lua_pushlstring(L, val.c_str(), val.size());
    } else {
      lua_pushnil(L);
    }
    lua_rawseti(L, -2, i - 2);
  }
  return 1;
}

int Lleveldb::hdel(lua_State* L) {
  if (!lua_islightuserdata(L, 1)) return luaL_error(L, "check lightuserdata");
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
    string rkey = key + split_ + hkey;
    batch.Delete(rkey);
  }
  db->Write(leveldb::WriteOptions(), &batch);
  return 0;
}

int Lleveldb::create(lua_State* L) {
  size_t len;
  const char* pname = luaL_checklstring(L, 1, &len);

  leveldb::DB* db;
  leveldb::Options options;
  options.create_if_missing = true;
  options.compression = leveldb::kSnappyCompression;
  options.block_cache = leveldb::NewLRUCache(10 * 1024 * 1024);
  options.filter_policy = leveldb::NewBloomFilterPolicy(10);
  options.write_buffer_size = 20 * 1024 * 1024;
  options.max_file_size = 10 * 1024 * 1024;
  options.block_size = 20 * 1024;
  leveldb::Status status = leveldb::DB::Open(options, {pname, len}, &db);

  if (!status.ok()) {
    return luaL_error(L, "leveldb open err");
  }
  Lleveldb* p = new Lleveldb();
  p->db_ = db;
  p->cache_ = options.block_cache;
  p->bloom_ = options.filter_policy;
  lua_pushlightuserdata(L, p);
  return 1;
}

int Lleveldb::release(lua_State* L) {
  if (!lua_islightuserdata(L, 1)) return luaL_error(L, "check lightuserdata");
  Lleveldb* p = (Lleveldb*)lua_touserdata(L, 1);
  delete p->db_;
  delete p->cache_;
  delete p->bloom_;
  delete p;
  return 0;
}

extern "C" {
LUAMOD_API int luaopen_lgame_leveldb(lua_State* L) {
  luaL_Reg l[] = {
      {"create", Lleveldb::create},   {"release", Lleveldb::release},
      {"compact", Lleveldb::compact}, {"keys", Lleveldb::keys},
      {"del", Lleveldb::del},         {"hgetall", Lleveldb::hgetall},
      {"hmget", Lleveldb::hmget},     {"hmset", Lleveldb::hmset},
      {"hdel", Lleveldb::hdel},       {NULL, NULL}};
  luaL_newlib(L, l);
  return 1;
}
}