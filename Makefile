.PHONY: all run

all: lib_map_nif.so

run: all lib_map.ex
	iex --dot-iex test.exs

lib_map_nif.so: lib_map_nif.c lib_map.c
	gcc -Wall -shared -o $@ -fPIC $< -lOpenCL -lm

lib_map_nif.c: lib_map.c lib_map.json futlixir
	./futlixir lib_map.json Map.NIF

lib_map.ex: futlixir

futlixir: lib/cli.ex lib/ex.ex lib/cli.ex
	mix escript.build

# https://stackoverflow.com/questions/3046117/gnu-makefile-multiple-outputs-from-single-rule-preventing-intermediate-files
lib_map.c lib_map.h: lib_map.intermediate ;

.INTERMEDIATE: lib_map.intermediate
lib_map.intermediate: lib_map.fut
	futhark opencl --library $<

lib_map.so: lib_map.c lib_map.h
	gcc -Wall -std=c99 -o $@ -c $<

.PHONY: clean
clean:
	rm -f *.so lib_map.c lib_map.h lib_map.json lib_map.ex lib_map_nif.c futlixir
