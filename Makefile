lib_calc_nif.so: lib_calc_nif.c lib_calc.so lib_map.so
	gcc -shared -o $@ -fPIC $^ -lOpenCL -lm -I `nix-build '<nixpkgs>' -A erlang`/lib/erlang/usr/include/

# https://stackoverflow.com/questions/3046117/gnu-makefile-multiple-outputs-from-single-rule-preventing-intermediate-files
lib_map.c lib_map.h: lib_map.intermediate ;

.INTERMEDIATE: lib_map.intermediate
lib_map.intermediate: lib_map.fut
	futhark opencl --library $<

lib_map.so: lib_map.c lib_map.h
	gcc -o $@ -c $<

lib_map_nif.so: lib_map_nif.c lib_map.so
	gcc -shared -o $@ -fpic $^ -lOpenCL -lm -I `nix-build '<nixpkgs>' -A erlang`/lib/erlang/usr/include/

lib_calc.so: lib_calc.c lib_calc.h
	gcc -o $@ -c $<


.PHONY: clean
clean:
	rm -f *.so lib_map.c lib_map.h lib_map.json
