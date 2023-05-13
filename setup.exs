c("calc.ex")
{:ok, cfg} = Calc.futhark_context_config_new()
{:ok, ctx} = Calc.futhark_context_new(cfg)
{:ok, xs} = Calc.futhark_new_i64_1d(ctx, <<1, 2, 3, 4>>)
