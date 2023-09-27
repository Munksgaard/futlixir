defmodule Futlixir.EX do
  @moduledoc """
  This module is responsible for generating the boilerplate Elixir module that loads the NIF.
  """

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

      def futhark_context_config_free(_cfg) do
        raise "NIF futhark_context_config_free no implemented"
      end

      def futhark_context_config_set_debugging(_cfg, _flag) do
        raise "NIF futhark_context_config_set_debugging not implemented"
      end

      def futhark_context_config_set_profiling(_cfg, _flag) do
        raise "NIF futhark_context_config_set_profiling not implemented"
      end

      def futhark_context_config_set_logging(_cfg, _flag) do
        raise "NIF futhark_context_config_set_logging not implemented"
      end

      def futhark_context_new(_cfg) do
        raise "NIF futhark_context_new not implemented"
      end

      def futhark_context_free(_cfg) do
        raise "NIF futhark_context_free not implemented"
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

  defp print_entry_points(device, entry_points) do
    for {_name, details} <- entry_points do
      IO.puts(device, Futlixir.EX.new_entry_point(details))
    end
  end

  defp print_array_types(device, types) do
    for {_ty, details} <- types do
      IO.puts(device, Futlixir.EX.new_array_type(details))
    end
  end

  def write_ex_file(rootname, module_name, manifest) do
    with {:ok, ex_file} <- File.open(rootname <> ".ex", [:write]) do
      IO.puts(ex_file, Futlixir.EX.boilerplate(module_name, rootname <> "_nif"))
      print_array_types(ex_file, manifest["types"])
      print_entry_points(ex_file, manifest["entry_points"])
      IO.puts(ex_file, "end")
      File.close(ex_file)
    end
  end
end
