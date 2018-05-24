all: test.d64

test.d64: calc
	c1541 -format test,01 d64 $@ -write $^

calc: calc.o math.o
	cl65 -u __EXEHDR__ -C c64-asm.cfg -o $@ $^

calc.o: calc.asm math.inc zeropage.inc
	cl65 -c -t c64 -o $@ $<

math.o: math.asm math.inc zeropage.inc
	cl65 -c -t c64 -o $@ $<

clean:
	rm -f test.d64 calc calc.o math.o
