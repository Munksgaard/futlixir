lib_calc_nif.so: lib_calc_nif.c lib_map.c
	gcc -shared -o $@ -fPIC $< -lOpenCL -lm -I `nix-build --no-out-link '<nixpkgs>' -A erlang`/lib/erlang/usr/include/

# https://stackoverflow.com/questions/3046117/gnu-makefile-multiple-outputs-from-single-rule-preventing-intermediate-files
lib_map.c lib_map.h: lib_map.intermediate ;

.INTERMEDIATE: lib_map.intermediate
lib_map.intermediate: lib_map.fut
	futhark opencl --library $<

lib_map.so: lib_map.c lib_map.h
	gcc -Wall -std=c99 -o $@ -c $<

.PHONY: clean
clean:
	rm -f *.so lib_map.c lib_map.h lib_map.json
