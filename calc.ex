defmodule Calc do
  @on_load :load_nifs

  def load_nifs do
    :erlang.load_nif('./lib_calc_nif', 0)
  end

  def futhark_context_config_new do
    raise "NIF futhark_context_config_new not implemented"
  end

  def futhark_context_new(_cfg) do
    raise "NIF futhark_context_new not implemented"
  end
end
