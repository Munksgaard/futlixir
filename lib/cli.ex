defmodule Futlixir.CLI do
  @moduledoc """
  A thin module for handling CLI invocation.
  """

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
           :ok <- Futlixir.EX.write_ex_file(rootname, module_name, manifest),
           :ok <- Futlixir.NIF.write_nif_file(rootname, module_name, manifest),
           do: :ok
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
end
