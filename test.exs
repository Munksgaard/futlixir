c("lib_map.ex")
{:ok, cfg} = Map.NIF.futhark_context_config_new()

:ok = Map.NIF.futhark_context_config_set_debugging(cfg, 1)
:ok = Map.NIF.futhark_context_config_set_profiling(cfg, 1)
:ok = Map.NIF.futhark_context_config_set_logging(cfg, 1)
:ok = Map.NIF.futhark_context_config_set_logging(cfg, 0)
:ok = Map.NIF.futhark_context_config_set_profiling(cfg, 0)
:ok = Map.NIF.futhark_context_config_set_debugging(cfg, 0)

{:ok, ctx} = Map.NIF.futhark_context_new(cfg)

xs_binary = <<0, 1>>
{:ok, xs} = Map.NIF.futhark_new_u8_1d(ctx, xs_binary, 2)
{:ok, ^xs_binary} = Map.NIF.futhark_u8_1d_to_binary(ctx, xs)
{:ok, ys} = Map.NIF.futhark_new_u8_1d(ctx, <<1, 4>>, 2)
{:ok, zs} = Map.NIF.futhark_entry_add(ctx, xs, ys)
{:ok, <<1, 5>> = zs_binary} = Map.NIF.futhark_u8_1d_to_binary(ctx, zs)

xs_binary = <<1::integer-signed-64-little>>
{:ok, xs} = Map.NIF.futhark_new_i64_1d(ctx, xs_binary, 1)
{:ok, ^xs_binary} = Map.NIF.futhark_i64_1d_to_binary(ctx, xs)
{:ok, ys} = Map.NIF.futhark_new_i64_1d(ctx, <<1279::integer-signed-64-little>>, 1)
{:ok, zs} = Map.NIF.futhark_entry_add_i64(ctx, xs, ys)
{:ok, <<1280::integer-signed-64-little>> = zs_binary} = Map.NIF.futhark_i64_1d_to_binary(ctx, zs)

xs_binary =
  <<1::integer-signed-32-little, 2::integer-signed-32-little, 3::integer-signed-32-little,
    4::integer-signed-32-little>>

{:ok, xs} = Map.NIF.futhark_new_i32_1d(ctx, xs_binary, 4)
{:ok, zs} = Map.NIF.futhark_entry_addi(ctx, xs, 2)

{:ok,
 <<3::integer-signed-32-little, 4::integer-signed-32-little, 5::integer-signed-32-little,
   6::integer-signed-32-little>> = zs_binary} = Map.NIF.futhark_i32_1d_to_binary(ctx, zs)

:ok = Map.NIF.futhark_free_i32_1d(ctx, xs)

{:ok, xs} = Map.NIF.futhark_new_u8_2d(ctx, <<1,2,3,4>>, 2, 2)
{:ok, ys} = Map.NIF.futhark_new_u8_2d(ctx, <<5,6,7,8>>, 2, 2)
{:ok, zs} = Map.NIF.futhark_entry_matplus(ctx, xs, ys)

{:ok, <<6,8,10,12>>} = Map.NIF.futhark_u8_2d_to_binary(ctx, zs)

:ok = Map.NIF.futhark_free_u8_2d(ctx, xs)
:ok = Map.NIF.futhark_free_u8_2d(ctx, ys)
:ok = Map.NIF.futhark_free_u8_2d(ctx, zs)


{:ok, xs} = Map.NIF.futhark_new_f64_2d(ctx, <<1.1::float-little, 2.1::float-little, 3.1::float-little, 4.123::float-little>>, 2, 2)
{:ok, <<1.1::float-little, 2.1::float-little, 3.1::float-little, 4.123::float-little>>} = Map.NIF.futhark_f64_2d_to_binary(ctx, xs)


{:ok, ys} = Map.NIF.futhark_new_f64_2d(ctx, <<42.1::float-little, 5.1::float-little, 23.4::float-little, 43.0::float-little>>, 2, 2)
{:ok, zs} = Map.NIF.futhark_entry_matmul(ctx, xs, ys)

{:ok, <<68.7::float-little, 51.3::float-little, 72.723::float-little, 55.32299999999999::float-little>>} = Map.NIF.futhark_f64_2d_to_binary(ctx, zs)

:ok = Map.NIF.futhark_free_f64_2d(ctx, xs)
:ok = Map.NIF.futhark_free_f64_2d(ctx, ys)
:ok = Map.NIF.futhark_free_f64_2d(ctx, zs)
