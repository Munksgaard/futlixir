c("map.ex")
{:ok, cfg} = Map.NIF.futhark_context_config_new()
{:ok, ctx} = Map.NIF.futhark_context_new(cfg)
xs_binary = <<0, 1>>
{:ok, xs} = Map.NIF.futhark_new_u8_1d(ctx, xs_binary)
{:ok, ^xs_binary} = Map.NIF.futhark_u8_1d_to_binary(ctx, xs)
{:ok, ys} = Map.NIF.futhark_new_u8_1d(ctx, <<1, 4>>)
{:ok, zs} = Map.NIF.futhark_entry_add(ctx, xs, ys)
{:ok, <<1, 5>> = zs_binary} = Map.NIF.futhark_u8_1d_to_binary(ctx, zs)

xs_binary = <<1, 0, 0, 0, 0, 0, 0, 0>>
{:ok, xs} = Map.NIF.futhark_new_i64_1d(ctx, xs_binary)
{:ok, ^xs_binary} = Map.NIF.futhark_i64_1d_to_binary(ctx, xs)
{:ok, ys} = Map.NIF.futhark_new_i64_1d(ctx, <<255, 4, 0, 0, 0, 0, 0, 0>>)
{:ok, zs} = Map.NIF.futhark_entry_add_i64(ctx, xs, ys)
{:ok, <<0, 5, 0, 0, 0, 0, 0, 0>> = zs_binary} = Map.NIF.futhark_i64_1d_to_binary(ctx, zs)
