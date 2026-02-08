SKYNET = skynet/skynet
LUACLIB = luaclib/dummy

all : $(SKYNET) $(LUACLIB)

$(SKYNET):
	make linux -j16 -Cskynet

$(LUACLIB):
	make -j16 -Cluaclib
	
cleanskynet:
	make cleanall -Cskynet

cleanluaclib:
	make clean -Cluaclib

clean: cleanluaclib

cleanall: cleanskynet cleanluaclib