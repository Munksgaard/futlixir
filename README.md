# Futlixir

A [NIF](https://www.erlang.org/doc/tutorial/nif.html)-generator for
[Futhark](https://futhark-lang.org)-code, which lets you run Futhark code from
the safety and comfort of the BEAM VM.

## Usage

To generate and compile the shared NIF library:

```
futhark opencl --library lib_map.fut
mix escript.build
./futlixir lib_map.json Map.NIF
gcc -shared -o lib_map_nif.so -fPIC lib_map_nif.c -lOpenCL -lm
```

Here's an example workflow from Elixir:

```elixir
c("lib_map.ex")
{:ok, cfg} = Map.NIF.futhark_context_config_new()
{:ok, ctx} = Map.NIF.futhark_context_new(cfg)

xs_binary = <<0, 1>>
{:ok, xs} = Map.NIF.futhark_new_u8_1d(ctx, xs_binary)
{:ok, ^xs_binary} = Map.NIF.futhark_u8_1d_to_binary(ctx, xs)
{:ok, ys} = Map.NIF.futhark_new_u8_1d(ctx, <<1, 4>>)
{:ok, zs} = Map.NIF.futhark_entry_add(ctx, xs, ys)
{:ok, <<1, 5>> = zs_binary} = Map.NIF.futhark_u8_1d_to_binary(ctx, zs)

xs_binary = <<1::integer-signed-64-little>>
{:ok, xs} = Map.NIF.futhark_new_i64_1d(ctx, xs_binary)
{:ok, ^xs_binary} = Map.NIF.futhark_i64_1d_to_binary(ctx, xs)
{:ok, ys} = Map.NIF.futhark_new_i64_1d(ctx, <<1279::integer-signed-64-little>>)
{:ok, zs} = Map.NIF.futhark_entry_add_i64(ctx, xs, ys)

{:ok, <<1280::integer-signed-64-little>> = zs_binary} =
  Map.NIF.futhark_i64_1d_to_binary(ctx, zs)
```

## Features

Futlixir is still very barebones. Right now, it only supports functions with
one-dimensional scalar array arguments, where the arrays are represented as
binaries on the Elixir-side.

## TODO

 - [x] Support and test multidimensional arrays
 - [x] Support using Elixir lists for arrays
 - [x] Support scalar arguments
 - [x] Support opaque Futhark types
 - [x] Support multiple return values
 - [ ] Package as a proper application
 - [ ] Release with mix?
 - [ ] Flakify
 - [ ] More testing

Probably other stuff I haven't thought of as well.
