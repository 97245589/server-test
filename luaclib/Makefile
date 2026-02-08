3RDPATH = ../3rd
3RDFLAG := -I$(3RDPATH) -L$(3RDPATH) -Wl,-rpath,$(3RDPATH):3rd
COMMON_FLAGS := -O2 -fPIC -shared -I../skynet/3rd/lua -I../skynet/skynet-src

all : lgame.so pb.so

GAME_SRCS := $(shell find ./game -name "*.cc")
lgame.so : $(GAME_SRCS)
	g++ -o $@ $^ $(COMMON_FLAGS) $(3RDFLAG) -std=c++17 -lzstd -lleveldb

pb.so : pb/pb.c
	gcc -o $@ $^ $(COMMON_FLAGS)

.PHONY : clean
clean:
	find . -type f \( -name "*.o" -o -name "*.so" \) | xargs rm -f