defmodule Futlixir.CLI do
  def main(args \\ []) do
    :ok =
      with {:ok, filename, module_name} <- get_args(args),
           {:ok, data} <- File.read(filename),
           {:ok, manifest} <- Jason.decode(data),
           nil <-
             if(
               Enum.any?(manifest["entry_points"], fn ep ->
                 length(elem(ep, 1)["outputs"]) > 1
               end),
               do: raise("Only functions with a single output are currently supported")
             ),
           rootname <- Path.rootname(filename),
           :ok <- write_ex_file(rootname, module_name, manifest),
           :ok <- write_nif_file(rootname, module_name, manifest),
           do: :ok
  end

  defp write_ex_file(rootname, module_name, manifest) do
    with {:ok, ex_file} <- File.open(rootname <> ".ex", [:write]) do
      IO.puts(ex_file, Futlixir.EX.boilerplate(module_name, rootname <> "_nif"))
      print_array_types(ex_file, manifest["types"])
      print_entry_points(ex_file, manifest["entry_points"])
      IO.puts(ex_file, "end")
      File.close(ex_file)
    end
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

  def print_nif_resources(device, types) do
    for {_ty, %{"elemtype" => elemtype, "rank" => rank}} <- types do
      resource_name = String.upcase("#{elemtype}_#{rank}d")
      IO.puts(device, "ErlNifResourceType* #{resource_name};")
    end
  end

  defp print_nif_array_types(device, types) do
    for {_ty, details} <- types do
      IO.puts(device, Futlixir.NIF.new_array_type(details))
    end
  end

  defp print_nif_entry_points(device, entry_points, types) do
    for {_name, details} <- entry_points do
      IO.puts(device, Futlixir.NIF.new_entry_point(details, types))
    end
  end

  defp print_nif_funcs(device, entry_points, types) do
    IO.puts(device, ~s"""
    static ErlNifFunc nif_funcs[] = {
      {"futhark_context_config_new", 0, futhark_context_config_new_nif},
      {"futhark_context_new", 1, futhark_context_new_nif},
    """)

    for {_ty, details} <- types do
      to_binary = "futhark_#{details["elemtype"]}_#{details["rank"]}d_to_binary"
      IO.puts(device, "  {\"#{details["ops"]["new"]}\", 2, #{details["ops"]["new"]}_nif},")
      IO.puts(device, "  {\"#{to_binary}\", 2, #{to_binary}_nif},")
    end

    for {_name, details} <- entry_points do
      IO.puts(
        device,
        "  {\"#{details["cfun"]}\", #{length(details["inputs"]) + 1}, #{details["cfun"]}_nif},"
      )
    end

    IO.puts(device, ~s"""
      {"futhark_context_sync", 1, futhark_context_sync_nif}
    };
    """)
  end

  defp write_nif_file(rootname, module_name, manifest) do
    with {:ok, nif_file} <- File.open(rootname <> "_nif.c", [:write]) do
      IO.puts(nif_file, Futlixir.NIF.boilerplate(rootname))
      print_nif_resources(nif_file, manifest["types"])
      IO.puts(nif_file, Futlixir.NIF.open_resources(manifest["types"]))
      print_nif_array_types(nif_file, manifest["types"])
      print_nif_entry_points(nif_file, manifest["entry_points"], manifest["types"])
      print_nif_funcs(nif_file, manifest["entry_points"], manifest["types"])
      IO.puts(nif_file, "ERL_NIF_INIT(Elixir.#{module_name}, nif_funcs, &load, NULL, NULL, NULL)")
      File.close(nif_file)
      :ok
    end
  end
end
