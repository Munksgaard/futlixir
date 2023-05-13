c("calc.ex")
{:ok, cfg} = Calc.futhark_context_config_new()
{:ok, ctx} = Calc.futhark_context_new(cfg)
xs_binary = <<1, 1, 0, 0, 0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 0>>
{:ok, xs} = Calc.futhark_new_i64_1d(ctx, xs_binary)
{:ok, xs_back} = Calc.futhark_i64_1d_to_binary(ctx, xs)
# {:ok, } = Calc.futhark_i64_1d_to_binary(ctx, xs)
# {:ok, ys} = Calc.futhark_new_i64_1d(ctx, <<0, 0, 0, 0, 0, 0, 0, 2>>)
# {:ok, zs} = Calc.futhark_entry_add(ctx, xs, ys)
