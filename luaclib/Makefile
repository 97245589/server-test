LUA_DIR := ../skynet/3rd/lua
3RDPATH = ../3rd
3RDFLAG := -I$(3RDPATH) -L$(3RDPATH) -Wl,-rpath,$(3RDPATH):3rd
COMMON_FLAGS := -O2 -fPIC -shared -I$(LUA_DIR) -std=c++17

all : lgame.so

GAME_SRCS := $(shell find ./game -name "*.cc")
lgame.so : $(GAME_SRCS)
	g++ -o $@ $^ $(COMMON_FLAGS) $(3RDFLAG) -lzstd -lleveldb

.PHONY : clean
clean:
	find . -type f \( -name "*.o" -o -name "*.so" \) | xargs rm -f