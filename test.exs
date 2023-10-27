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

{:ok, xs} = Map.NIF.futhark_i32_1d_from_list(ctx, [42, 43])
{:ok, zs} = Map.NIF.futhark_entry_addi(ctx, xs, 2)
{:ok, [44, 45]} = Map.NIF.futhark_i32_1d_to_list(ctx, zs)

:ok = Map.NIF.futhark_free_i32_1d(ctx, xs)
:ok = Map.NIF.futhark_free_i32_1d(ctx, zs)

{:ok, xs} = Map.NIF.futhark_f64_2d_from_list(ctx, [[1.0, 2.0, 3.0], [4, 5, 6], [7, 8, 9]])
{:ok, [3, 3]} = Map.NIF.futhark_shape_f64_2d(ctx, xs)
{:ok, zs} = Map.NIF.futhark_entry_matmul(ctx, xs, xs)

{:ok, [[30.0, 36.0, 42.0], [66.0, 81.0, 96.0], [102.0, 126.0, 150.0]]} = Map.NIF.futhark_f64_2d_to_list(ctx, zs)

:ok = Map.NIF.futhark_free_f64_2d(ctx, xs)
:ok = Map.NIF.futhark_free_f64_2d(ctx, zs)

{:ok, xs} = Map.NIF.futhark_u8_1d_from_list(ctx, [8, 10])
{:ok, ys} = Map.NIF.futhark_u8_1d_from_list(ctx, [2, 5])
{:ok, [2,5]} = Map.NIF.futhark_u8_1d_to_list(ctx, ys)

{:ok, opaque} = Map.NIF.futhark_new_opaque_foo(ctx, xs, ys)

{:ok, added} = Map.NIF.futhark_entry_add_foo(ctx, opaque)

{:ok, stored} = Map.NIF.futhark_store_opaque_foo(ctx, added)

{:ok, restored} = Map.NIF.futhark_restore_opaque_foo(ctx, stored)

{:ok, projected_xs} = Map.NIF.futhark_project_opaque_foo_0(ctx, added)

{:ok, projected_ys} = Map.NIF.futhark_project_opaque_foo_1(ctx, added)

{:ok, [10, 15]} = Map.NIF.futhark_u8_1d_to_list(ctx, projected_xs)
{:ok, [6,5]} = Map.NIF.futhark_u8_1d_to_list(ctx, projected_ys)

:ok = Map.NIF.futhark_free_u8_1d(ctx, xs)
:ok = Map.NIF.futhark_free_u8_1d(ctx, ys)
:ok = Map.NIF.futhark_free_u8_1d(ctx, projected_xs)
:ok = Map.NIF.futhark_free_u8_1d(ctx, projected_ys)

:ok = Map.NIF.futhark_free_opaque_foo(ctx, opaque)
:ok = Map.NIF.futhark_free_opaque_foo(ctx, added)
:ok = Map.NIF.futhark_free_opaque_foo(ctx, restored)

:ok = Map.NIF.futhark_context_free(ctx)
:ok = Map.NIF.futhark_context_config_free(cfg)
