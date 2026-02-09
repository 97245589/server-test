3RDPATH = ../3rd
SKYNETPATH = ../skynet/skynet-src
3RDFLAG := -L$(3RDPATH) -Wl,-rpath,$(3RDPATH):3rd
COMMON_FLAGS := -O2 -fPIC -I../skynet/3rd/lua
CXX_FLAGS := $(COMMON_FLAGS) -std=c++17

all : lgame.so pb.so

GAMESRC_CCS := $(shell find ./game -name "*.cc")
GAMESRC_CS := $(shell find ./game -name "*.c")
GAME_OES := $(GAMESRC_CCS:.cc=.o) $(GAMESRC_CS:.c=.o)
lgame.so : $(GAME_OES)
	g++ -o $@ $^ -shared $(3RDFLAG) -lzstd -lleveldb

%.o : %.cc
	g++ -o $@ -c $< $(CXX_FLAGS) -I$(3RDPATH)

%.o : %.c
	gcc -o $@ -c $< $(COMMON_FLAGS) -I$(3RDPATH) -I$(SKYNETPATH)

pb.so : pb/pb.c
	gcc -o $@ $^ -shared $(COMMON_FLAGS)

.PHONY : clean
cleano:
	find . -type f -name "*.o" | xargs rm -f

cleanso:
	find . -type f -name "*.so" | xargs rm -f
	
clean: cleano cleanso