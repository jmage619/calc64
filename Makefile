all: test.d64

test.d64: calc
	c1541 -format test,01 d64 $@ -write $^

calc: calc.asm
	xa -O PETSCII $^ -o $@

clean:
	rm -f test.d64 calc
