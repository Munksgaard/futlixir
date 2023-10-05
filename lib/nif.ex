defmodule Futlixir.NIF do
  @moduledoc """
  This module is responsible for generating the NIF C files corresponding
  to a particular Futhark library.
  """

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

    static int open_resource(ErlNifEnv* env, ErlNifResourceType** resource_type, const char* name)
    {
      const char* mod = "resources";
      int flags = ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER;

      *resource_type = enif_open_resource_type(env, mod, name, NULL, flags, NULL);
      if(*resource_type == NULL) return -1;
      return 0;
    }

    static int load(ErlNifEnv* env, void** priv, ERL_NIF_TERM load_info)
    {
      if(open_resource(env, &CONFIG_TYPE, "Config") == -1) return -1;
      if(open_resource(env, &CONTEXT_TYPE, "Context") == -1) return -1;
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

    static ERL_NIF_TERM futhark_context_config_free_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
    {
      struct futhark_context_config **cfg;

      ERL_NIF_TERM ret;

      if(argc != 1) {
        return enif_make_badarg(env);
      }

      if(!enif_get_resource(env, argv[0], CONFIG_TYPE, (void**) &cfg)) {
        return enif_make_badarg(env);
      }

      futhark_context_config_free(*cfg);

      return atom_ok;
    }

    static ERL_NIF_TERM futhark_context_config_set_debugging_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
    {
      struct futhark_context_config **cfg;

      ERL_NIF_TERM ret;

      if(argc != 2) {
        return enif_make_badarg(env);
      }

      if(!enif_get_resource(env, argv[0], CONFIG_TYPE, (void**) &cfg)) {
        return enif_make_badarg(env);
      }

      int flag;
      if (!enif_get_int(env, argv[1], &flag)) {
        return enif_make_badarg(env);
      }

      futhark_context_config_set_debugging(*cfg, flag);

      return atom_ok;
    }

    static ERL_NIF_TERM futhark_context_config_set_profiling_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
    {
      struct futhark_context_config **cfg;

      ERL_NIF_TERM ret;

      if(argc != 2) {
        return enif_make_badarg(env);
      }

      if(!enif_get_resource(env, argv[0], CONFIG_TYPE, (void**) &cfg)) {
        return enif_make_badarg(env);
      }

      int flag;
      if (!enif_get_int(env, argv[1], &flag)) {
        return enif_make_badarg(env);
      }

      futhark_context_config_set_profiling(*cfg, flag);

      return atom_ok;
    }

    static ERL_NIF_TERM futhark_context_config_set_logging_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
    {
      struct futhark_context_config **cfg;

      ERL_NIF_TERM ret;

      if(argc != 2) {
        return enif_make_badarg(env);
      }

      if(!enif_get_resource(env, argv[0], CONFIG_TYPE, (void**) &cfg)) {
        return enif_make_badarg(env);
      }

      int flag;
      if (!enif_get_int(env, argv[1], &flag)) {
        return enif_make_badarg(env);
      }

      futhark_context_config_set_logging(*cfg, flag);

      return atom_ok;
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

    static ERL_NIF_TERM futhark_context_free_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
    {
      struct futhark_context **ctx;

      if(argc != 1) {
        return enif_make_badarg(env);
      }

      if(!enif_get_resource(env, argv[0], CONTEXT_TYPE, (void**) &ctx)) {
        return enif_make_badarg(env);
      }

      futhark_context_free(*ctx);

      return atom_ok;
    }

    static ERL_NIF_TERM futhark_context_sync_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
    {
      struct futhark_context **ctx;

      if(argc != 1) {
        return enif_make_badarg(env);
      }

      if(!enif_get_resource(env, argv[0], CONTEXT_TYPE, (void**) &ctx)) {
        return enif_make_badarg(env);
      }

      if (futhark_context_sync(*ctx) != 0) return enif_make_badarg(env);

      return atom_ok;
    }
    """
  end

  def open_types(types) do
    for {_, %{"elemtype" => elemtype, "rank" => rank}} <- types do
      name = "#{elemtype}_#{rank}d"
      "  if(open_resource(env, &#{String.upcase(name)}, \"#{name}\") == -1) return -1;"
    end
    |> Enum.join("\n")
  end

  def resource_name(%{"elemtype" => elemtype, "rank" => rank}),
    do: String.upcase("#{elemtype}_#{rank}d")

  def resource_name(%{"ctype" => ctype}) do
    ~r{^struct (?<name>[^ ]+) \*$}
    |> Regex.named_captures(ctype)
    |> Map.fetch!("name")
    |> String.upcase()
  end

  def new_type(
        %{
          "ctype" => ctype,
          "elemtype" => elemtype,
          "kind" => "array",
          "ops" => %{"free" => _free, "shape" => shape, "values" => values, "new" => new},
          "rank" => rank
        } = params,
        _types
      ) do
    elemtype_t = to_elemtype_t(elemtype)
    to_binary = "futhark_#{elemtype}_#{rank}d_to_binary_nif"

    ~s"""
    static ERL_NIF_TERM #{new}_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
    {
      struct futhark_context **ctx;
      ErlNifBinary bin;

      #{ctype}*res;
      ERL_NIF_TERM ret;

      if(argc != 2) {
        return enif_make_badarg(env);
      }

      if(!enif_get_resource(env, argv[0], CONTEXT_TYPE, (void**) &ctx)) {
        return enif_make_badarg(env);
      }

      if (!enif_inspect_binary(env, argv[1], &bin)) {
        return enif_make_badarg(env);
      }

      res = enif_alloc_resource(#{resource_name(params)}, sizeof(#{ctype}));
      if(res == NULL) return enif_make_badarg(env);

      #{ctype} tmp = #{new}(*ctx, (const #{elemtype_t} *)bin.data, bin.size / sizeof(#{elemtype_t}));
      const int64_t *shape = #{shape}(*ctx, tmp);
      if (futhark_context_sync(*ctx) != 0) return enif_make_badarg(env);

      *res = tmp;

      ret = enif_make_resource(env, res);
      enif_release_resource(res);

      return enif_make_tuple2(env, atom_ok, ret);
    }

    static ERL_NIF_TERM #{to_binary}(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
    {
      struct futhark_context **ctx;
      #{ctype}*xs;

      ErlNifBinary binary;
      ERL_NIF_TERM ret;

      if(argc != 2) {
        return enif_make_badarg(env);
      }

      if(!enif_get_resource(env, argv[0], CONTEXT_TYPE, (void**) &ctx)) {
        return enif_make_badarg(env);
      }

      if(!enif_get_resource(env, argv[1], #{resource_name(params)}, (void**) &xs)) {
        return enif_make_badarg(env);
      }

      const int64_t *shape = #{shape}(*ctx, *xs);

      enif_alloc_binary(shape[0] * sizeof(#{elemtype_t}), &binary);

      if (#{values}(*ctx, *xs, (#{elemtype_t} *)(binary.data)) != 0) return enif_make_badarg(env);
      if (futhark_context_sync(*ctx) != 0) return enif_make_badarg(env);

      ret = enif_make_binary(env, &binary);

      return enif_make_tuple2(env, atom_ok, ret);
    }
    """
  end

  def new_type(
        %{
          "ctype" => ctype,
          "kind" => "opaque",
          "ops" => _ops,
          "record" => record
        } = params,
        types
      ) do
    get_args =
      record["fields"]
      |> Enum.with_index()
      |> Enum.map(fn {field, i} ->
        ~s"""
        #{types[field["type"]]["ctype"]} *#{field["name"]};
          if (!enif_get_resource(env, argv[#{i + 1}], #{resource_name(types[field["type"]])}, (void**) &#{field["name"]})) {
            return enif_make_badarg(env);
          }
        """
      end)
      |> Enum.join("\n  ")

    ~s"""
    #{new_type(Map.delete(params, "record"), types)}

    static ERL_NIF_TERM #{record["new"]}_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
    {
      struct futhark_context **ctx;

      #{ctype}*res;
      ERL_NIF_TERM ret;

      if(argc != #{length(record["fields"]) + 1}) {
        return enif_make_badarg(env);
      }

      if(!enif_get_resource(env, argv[0], CONTEXT_TYPE, (void**) &ctx)) {
        return enif_make_badarg(env);
      }

      #{get_args}

      res = enif_alloc_resource(#{resource_name(params)}, sizeof(#{ctype}));
      if(res == NULL) return enif_make_badarg(env);

      if (!#{record["new"]}(*ctx, res, #{record["fields"] |> Enum.map(&"*#{&1["name"]}") |> Enum.join(", ")})) {
        return enif_make_badarg(env);
      }

      ret = enif_make_resource(env, res);
      enif_release_resource(res);

      return enif_make_tuple2(env, atom_ok, ret);
    }

    #{record["fields"] |> Enum.map(&record_projection(&1, params, types)) |> Enum.join("\n\n")}
    """
  end

  def new_type(
        %{
          "ctype" => ctype,
          "kind" => "opaque",
          "ops" => ops
        } = params,
        _types
      ) do
    ~s"""
    static ERL_NIF_TERM #{ops["free"]}_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
    {
      struct futhark_context **ctx;
      ErlNifBinary bin;

      #{ctype}*res;
      ERL_NIF_TERM ret;

      if(argc != 2) {
        return enif_make_badarg(env);
      }

      if(!enif_get_resource(env, argv[0], CONTEXT_TYPE, (void**) &ctx)) {
        return enif_make_badarg(env);
      }

      if(!enif_get_resource(env, argv[1], #{resource_name(params)}, (void**) &res)) {
        return enif_make_badarg(env);
      }

      if(#{ops["free"]}(*ctx, *res) != 0) return enif_make_badarg(env);

      return atom_ok;
    }

    static ERL_NIF_TERM #{ops["store"]}_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
    {
      struct futhark_context **ctx;
      #{ctype}*xs;

      ErlNifBinary binary;
      ERL_NIF_TERM ret;

      if(argc != 2) {
        return enif_make_badarg(env);
      }

      if(!enif_get_resource(env, argv[0], CONTEXT_TYPE, (void**) &ctx)) {
        return enif_make_badarg(env);
      }

      if(!enif_get_resource(env, argv[1], #{resource_name(params)}, (void**) &xs)) {
        return enif_make_badarg(env);
      }

      size_t n;
      #{ops["store"]}(*ctx, *xs, NULL, &n);

      enif_alloc_binary(n, &binary);

      if (#{ops["store"]}(*ctx, *xs, (void**)&binary.data, &n) != 0) return enif_make_badarg(env);

      ret = enif_make_binary(env, &binary);

      return enif_make_tuple2(env, atom_ok, ret);
    }

    static ERL_NIF_TERM #{ops["restore"]}_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
    {
      struct futhark_context **ctx;

      #{ctype}*res;
      ErlNifBinary binary;
      ERL_NIF_TERM ret;

      if(argc != 2) {
        return enif_make_badarg(env);
      }

      if(!enif_get_resource(env, argv[0], CONTEXT_TYPE, (void**) &ctx)) {
        return enif_make_badarg(env);
      }

      if (!enif_inspect_binary(env, argv[1], &binary)) {
        return enif_make_badarg(env);
      }

      #{ctype} tmp = #{ops["restore"]}(*ctx, binary.data);
      if (futhark_context_sync(*ctx) != 0) return enif_make_badarg(env);

      res = enif_alloc_resource(#{resource_name(params)}, sizeof(#{ctype}));
      if(res == NULL) return enif_make_badarg(env);

      *res = tmp;

      ret = enif_make_resource(env, res);
      enif_release_resource(res);

      return enif_make_tuple2(env, atom_ok, ret);
    }
    """
  end

  def record_projection(%{"project" => project, "type" => type}, opaque, types) do
    ~s"""
    static ERL_NIF_TERM #{project}_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
    {
      struct futhark_context **ctx;

      #{opaque["ctype"]}*opaque;

      #{types[type]["ctype"]}*res;
      ERL_NIF_TERM ret;

      if(argc != 2) {
        return enif_make_badarg(env);
      }

      if(!enif_get_resource(env, argv[0], CONTEXT_TYPE, (void**) &ctx)) {
        return enif_make_badarg(env);
      }

      if(!enif_get_resource(env, argv[1], #{resource_name(opaque)}, (void**) &opaque)) {
        return enif_make_badarg(env);
      }

      res = enif_alloc_resource(#{resource_name(types[type])}, sizeof(#{types[type]["ctype"]}));
      if(res == NULL) return enif_make_badarg(env);

      if (!#{project}(*ctx, res, *opaque)) {
        return enif_make_badarg(env);
      }

      ret = enif_make_resource(env, res);
      enif_release_resource(res);

      return enif_make_tuple2(env, atom_ok, ret);
    }
    """
  end

  def new_entry_point(
        %{
          "cfun" => cfun,
          "inputs" => inputs,
          "outputs" => outputs,
          "tuning_params" => _tuning_params
        },
        types
      ) do
    init_inputs =
      for %{"name" => name, "type" => type, "unique" => _unique} <- inputs do
        if types[type] do
          ~s"""
          #{types[type]["ctype"]}*#{name};
          """
        else
          ~s"""
          #{to_elemtype_t(type)} #{name};
          """
        end
      end
      |> Enum.join("  ")

    init_outputs =
      for %{"type" => type, "unique" => _unique} <- outputs do
        "#{types[type]["ctype"]}*res;"
      end
      |> Enum.join("\n  ")

    get_resources =
      for {%{"name" => name, "type" => type, "unique" => _unique}, i} <-
            Enum.with_index(inputs, 1) do
        if types[type] do
          ~s"""
          if(!enif_get_resource(env, argv[#{i}], #{resource_name(types[type])}, (void**) &#{name})) {
              return enif_make_badarg(env);
            }
          """
        else
          ~s"""
          if (!#{get_type(type)}(env, argv[#{i}], &#{name})) {
              return enif_make_badarg(env);
            }
          """
        end
      end
      |> Enum.join("\n  ")

    alloc_results =
      for %{"type" => type, "unique" => _unique} <- outputs do
        ~s"""
        res = enif_alloc_resource(#{resource_name(types[type])}, sizeof(#{types[type]["ctype"]}));
          if(res == NULL) return enif_make_badarg(env);
        """
      end
      |> Enum.join("\n  ")

    input_names =
      for %{"name" => name, "type" => type} <- inputs do
        if types[type] do
          "*#{name}"
        else
          name
        end
      end
      |> Enum.join(", ")

    ~s"""
    static ERL_NIF_TERM #{cfun}_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
    {
      struct futhark_context **ctx;

      #{init_inputs}
      #{init_outputs}

      ERL_NIF_TERM ret;

      if(argc != #{length(inputs) + 1}) {
        return enif_make_badarg(env);
      }

      if(!enif_get_resource(env, argv[0], CONTEXT_TYPE, (void**) &ctx)) {
        return enif_make_badarg(env);
      }

      #{get_resources}
      #{alloc_results}
      if (#{cfun}(*ctx, res, #{input_names}) != 0) return enif_make_badarg(env);

      ret = enif_make_resource(env, res);
      enif_release_resource(res);

      return enif_make_tuple2(env, atom_ok, ret);
    }
    """
  end

  def to_elemtype_t("u8"), do: "uint8_t"
  def to_elemtype_t("u32"), do: "uint32_t"
  def to_elemtype_t("u64"), do: "uint64_t"
  def to_elemtype_t("i8"), do: "int8_t"
  def to_elemtype_t("i32"), do: "int32_t"
  def to_elemtype_t("i64"), do: "int64_t"
  def to_elemtype_t("f64"), do: "double"

  def get_type("u32"), do: "enif_get_uint"
  def get_type("u64"), do: "enif_get_uint64"
  def get_type("i32"), do: "enif_get_int"
  def get_type("i64"), do: "enif_get_int64"
  def get_type("f64"), do: "enif_get_double"

  def print_nif_resources(device, types) do
    for {_ty, desc} <- types do
      IO.puts(device, "ErlNifResourceType* #{resource_name(desc)};")
    end
  end

  defp print_nif_array_types(device, types) do
    for {_ty, details} <- types do
      IO.puts(device, Futlixir.NIF.new_type(details, types))
    end
  end

  defp print_nif_entry_points(device, entry_points, types) do
    for {_name, details} <- entry_points do
      IO.puts(device, Futlixir.NIF.new_entry_point(details, types))
    end
  end

  defp nif_funcs({_ty, %{"kind" => "array"} = details}) do
    to_binary = "futhark_#{details["elemtype"]}_#{details["rank"]}d_to_binary"

    ~s"""
      {"#{details["ops"]["new"]}", 2, #{details["ops"]["new"]}_nif},
      {"#{to_binary}", 2, #{to_binary}_nif},
    """
  end

  defp nif_funcs({_ty, %{"kind" => "opaque"} = details}) do
    result = ~s"""
      {"#{details["ops"]["free"]}", 2, #{details["ops"]["free"]}_nif},
      {"#{details["ops"]["restore"]}", 2, #{details["ops"]["restore"]}_nif},
      {"#{details["ops"]["store"]}", 2, #{details["ops"]["store"]}_nif},
    """

    if record = details["record"] do
      ~s"""
      #{result}
        {"#{record["new"]}", #{length(record["fields"]) + 1}, #{record["new"]}_nif},
      """ <>
        (Enum.map(record["fields"], fn field ->
           ~s[  {"#{field["project"]}", 2, #{field["project"]}_nif},]
         end)
         |> Enum.join("\n"))
    else
      result
    end
  end

  defp print_nif_funcs(device, entry_points, types) do
    IO.puts(device, ~s"""
    static ErlNifFunc nif_funcs[] = {
      {"futhark_context_config_new", 0, futhark_context_config_new_nif},
      {"futhark_context_config_free", 1, futhark_context_config_free_nif},
      {"futhark_context_config_set_debugging", 2, futhark_context_config_set_debugging_nif},
      {"futhark_context_config_set_profiling", 2, futhark_context_config_set_profiling_nif},
      {"futhark_context_config_set_logging", 2, futhark_context_config_set_logging_nif},
      {"futhark_context_new", 1, futhark_context_new_nif},
      {"futhark_context_free", 1, futhark_context_free_nif},
    """)

    for details <- types do
      IO.puts(device, nif_funcs(details))
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

  def write_nif_file(rootname, module_name, manifest) do
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
