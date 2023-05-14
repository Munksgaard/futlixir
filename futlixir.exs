#! /usr/bin/env elixir

Mix.install([:jason])

defmodule Futlexir.EX do
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

defmodule Futlexir.CLI do
  def main(args \\ []) do
    :ok =
      with {:ok, filename, module_name} <- get_args(args),
           {:ok, data} <- File.read(filename),
           {:ok, manifest} <- Jason.decode(data),
           rootname <- Path.rootname(filename),
           :ok <- write_ex_file(rootname, module_name, manifest),
           :ok <- write_nif_file(rootname, module_name, manifest),
           do: :ok
  end

  defp write_ex_file(rootname, module_name, manifest) do
    with {:ok, ex_file} <- File.open(rootname <> ".ex", [:write]) do
      IO.puts(ex_file, Futlexir.EX.boilerplate(module_name, rootname <> "_nif"))
      print_array_types(ex_file, manifest["types"])
      print_entry_points(ex_file, manifest["entry_points"])
      IO.puts(ex_file, "end")
      File.close(ex_file)
    end
  end

  defp print_entry_points(device, entry_points) do
    for {_name, details} <- entry_points do
      IO.puts(device, Futlexir.EX.new_entry_point(details))
    end
  end

  defp print_array_types(device, types) do
    for {_ty, details} <- types do
      IO.puts(device, Futlexir.EX.new_array_type(details))
    end
  end

  defp get_args(args) do
    case(args) do
      [filename, module_name] ->
        if String.ends_with?(filename, ".json") do
          {:ok, filename, module_name}
        else
          {:err, :invalid_filename}
        end

      _ ->
        {:err, :invalid_arguments}
    end
  end

  defp write_nif_file(rootname, module_name, manifest) do
    with {:ok, nif_file} <- File.open(rootname <> "_nif.c", [:write]) do
      IO.puts(nif_file, ~s"""
      #include <erl_nif.h>
      #include "lib_map.c"

      struct futhark_context;
      """)

      File.close(nif_file)
      :ok
    end
  end
end

Futlexir.CLI.main(System.argv())
