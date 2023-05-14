#! /usr/bin/env elixir

Mix.install([:jason])

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

defmodule Futlixir.NIF do
  def boilerplate(rootname) do
    ~s"""
    #include <erl_nif.h>
    #include "#{rootname}.c"

    struct futhark_context;

    ERL_NIF_TERM atom_ok;

    ErlNifResourceType* CONFIG_TYPE;
    ErlNifResourceType* CONTEXT_TYPE;
    """
  end

  def open_resources(types) do
    ~s"""

    static int open_resource(ErlNifEnv* env, const char* name)
    {
      const char* mod = "resources";
      int flags = ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER;

      CONTEXT_TYPE = enif_open_resource_type(env, mod, name, NULL, flags, NULL);
      if(CONFIG_TYPE == NULL) return -1;
      return 0;
    }

    static int load(ErlNifEnv* env, void** priv, ERL_NIF_TERM load_info)
    {
      if(open_resource(env, "Config") == -1) return -1;
      if(open_resource(env, "Context") == -1) return -1;
    #{open_types(types)}

      atom_ok = enif_make_atom(env, "ok");

      return 0;
    }

    static ERL_NIF_TERM futhark_context_config_new_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
    {
      struct futhark_context_config **res;

      ERL_NIF_TERM ret;

      if(argc != 0) {
        return enif_make_badarg(env);
      }

      res = enif_alloc_resource(CONFIG_TYPE, sizeof(struct futhark_context_config *));
      if(res == NULL) return enif_make_badarg(env);

      struct futhark_context_config* tmp = futhark_context_config_new();

      *res = tmp;

      ret = enif_make_resource(env, res);
      enif_release_resource(res);

      return enif_make_tuple2(env, atom_ok, ret);
    }

    static ERL_NIF_TERM futhark_context_new_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
    {
      struct futhark_context_config **cfg;
      struct futhark_context **res;

      ERL_NIF_TERM ret;

      if(argc != 1) {
        return enif_make_badarg(env);
      }

      if(!enif_get_resource(env, argv[0], CONFIG_TYPE, (void**) &cfg)) {
        return enif_make_badarg(env);
      }

      res = enif_alloc_resource(CONTEXT_TYPE, sizeof(struct futhark_context *));
      if(res == NULL) return enif_make_badarg(env);

      struct futhark_context* tmp = futhark_context_new(*cfg);

      *res = tmp;

      ret = enif_make_resource(env, res);
      enif_release_resource(res);

      return enif_make_tuple2(env, atom_ok, ret);
    }

    """
  end

  def open_types(types) do
    for {_, %{"elemtype" => elemtype, "rank" => rank}} <- types do
      "  if(open_resource(env, \"#{elemtype}_#{rank}d\") == -1) return -1;"
    end
    |> Enum.join("\n")
  end
end

defmodule Futlixir.CLI do
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

  defp write_nif_file(rootname, module_name, manifest) do
    with {:ok, nif_file} <- File.open(rootname <> "_nif.c", [:write]) do
      IO.puts(nif_file, Futlixir.NIF.boilerplate(rootname))
      print_nif_resources(nif_file, manifest["types"])
      IO.puts(nif_file, Futlixir.NIF.open_resources(manifest["types"]))
      File.close(nif_file)
      :ok
    end
  end
end

Futlixir.CLI.main(System.argv())
