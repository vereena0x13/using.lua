.PHONY: all clean test coverage cov

all: coverage

clean:
	rm -f luacov.*

test:
	busted

coverage: clean
	- busted -c
	luacov-console
	luacov-console -s

cov: coverage