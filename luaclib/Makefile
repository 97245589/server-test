3RDPATH := ../3rd
3RDFLAG := -L$(3RDPATH) -Wl,-rpath,$(3RDPATH):3rd
COMMON_FLAGS := -O2 -fPIC -I../skynet/3rd/lua -I$(3RDPATH) -MMD -MP
CXX_FLAGS := $(COMMON_FLAGS) -std=c++17
LINK := -s -flto=auto -shared

all : lgame.so pb.so

GAMESRC_CCS := $(shell find ./game -name "*.cc")
GAMESRC_CS := $(shell find ./game -name "*.c")
GAME_OES := $(GAMESRC_CCS:.cc=.o) $(GAMESRC_CS:.c=.o)
GAME_DEP := $(GAME_OES:.o=.d)
-include $(GAME_DEP)
lgame.so : $(GAME_OES)
	g++ -o $@ $^ $(3RDFLAG) $(LINK) -lleveldb

%.o : %.cc
	g++ -o $@ -c $< $(CXX_FLAGS)

%.o : %.c
	gcc -o $@ -c $< $(COMMON_FLAGS)

pb.so : pb/pb.c
	gcc -o $@ $^ $(COMMON_FLAGS) $(LINK)

.PHONY : clean
cleano:
	find . -type f \( -name "*.o" -o -name "*.d" \) | xargs rm -f

cleanso:
	find . -type f -name "*.so" | xargs rm -f

clean: cleano cleanso