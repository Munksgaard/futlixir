defmodule Futlixir.EX do
  def boilerplate(module_name, nif) do
    ~s"""
    defmodule #{module_name} do
      @on_load :load_nifs

      def load_nifs do
        :erlang.load_nif('./#{nif}', 0)
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
    """
  end

  def new_array_type(%{
        "ctype" => _ctype,
        "elemtype" => elemtype,
        "kind" => "array",
        "ops" => %{"free" => _free, "shape" => _shape, "values" => _values, "new" => new},
        "rank" => rank
      }) do
    to_binary = "futhark_#{elemtype}_#{rank}d_to_binary"

    ~s"""
      def #{new}(_ctx, _binary) do
        raise "NIF #{new} not implemented"
      end

      def #{to_binary}(_ctx, _in) do
        raise "NIF #{to_binary} not implemented"
      end
    """
  end

  def new_entry_point(%{
        "cfun" => cfun,
        "inputs" => inputs,
        "outputs" => _outputs,
        "tuning_params" => _tuning_params
      }) do
    ~s"""
      def #{cfun}(_ctx#{for %{"name" => name} <- inputs, do: ", _#{name}"}) do
        raise "NIF #{cfun} not implemented"
      end
    """
  end
end
