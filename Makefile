all: test.d64

test.d64: calc
	c1541 -format test,01 d64 $@ -write $^

#calc: calc.asm
#	xa -O PETSCII $^ -o $@

calc: math.o
	cl65 -u __EXEHDR__ -C c64-asm.cfg -o calc math.o

math.o: math.asm zp.h
	cl65 -c -t c64 -o $@ $<

clean:
	rm -f test.d64 calc math.o
