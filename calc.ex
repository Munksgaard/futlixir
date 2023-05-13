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

  def futhark_context_sync(_ctx) do
    raise "NIF futhark_context_sync not implemented"
  end

  def futhark_new_u8_1d(_ctx, _binary) do
    raise "NIF futhark_new_u8_1d not implemented"
  end

  def futhark_entry_add(_ctx, _in0, _in1) do
    raise "NIF futhark_entry_add not implemented"
  end

  def futhark_u8_1d_to_binary(_ctx, _in0) do
    raise "NIF futhark_u8_1d_to_binary not implemented"
  end
end
