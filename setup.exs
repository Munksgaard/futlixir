c("calc.ex")
{:ok, cfg} = Calc.futhark_context_config_new()
{:ok, ctx} = Calc.futhark_context_new(cfg)
