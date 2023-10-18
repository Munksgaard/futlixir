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

      defp shape(xs), do: shape(xs, {})
      defp shape([], acc), do: acc
      defp shape([h|_] = xs, acc) do
        acc = Tuple.append(acc, length(xs))
        if is_list(h) do
          shape(h, acc)
        else
          acc
        end
      end
    """
  end

  def new_type(
        %{
          "ctype" => _ctype,
          "kind" => "opaque",
          "ops" => %{"free" => _free, "restore" => _restore, "store" => _store},
          "record" => record
        } = params
      ) do
    record_projections =
      for projection <- record["fields"] do
        ~s"""
          def #{projection["project"]}(_ctx, _record) do
            raise "NIF #{projection["project"]} not implemented"
          end
        """
      end
      |> Enum.join("\n\n")

    new_args = Enum.map_join(record["fields"], ", ", &"_#{&1["name"]}")

    ~s"""
    #{new_type(Map.delete(params, "record"))}

      def #{record["new"]}(_ctx, #{new_args}) do
        raise "NIF #{record["new"]} not implemented"
      end

    #{record_projections}
    """
  end

  def new_type(%{
        "ctype" => _ctype,
        "kind" => "opaque",
        "ops" => %{"free" => free, "restore" => restore, "store" => store}
      }) do
    ~s"""
      def #{free}(_ctx, _opaque) do
        raise "NIF #{free} not implemented"
      end

      def #{store}(_ctx, _opaque) do
        raise "NIF #{store} not implemented"
      end

      def #{restore}(_ctx, _binary) do
        raise "NIF #{restore} not implemented"
      end
    """
  end

  def new_type(%{
        "ctype" => _ctype,
        "elemtype" => elemtype,
        "kind" => "array",
        "ops" => %{"free" => free, "shape" => shape, "values" => _values, "new" => new},
        "rank" => rank
      }) do
    to_binary = "futhark_#{elemtype}_#{rank}d_to_binary"
    from_list = "futhark_#{elemtype}_#{rank}d_from_list"
    to_list = "futhark_#{elemtype}_#{rank}d_to_list"
    dims = Enum.map(1..rank, &"dim#{&1 - 1}")

    ~s"""
      def #{new}(_ctx, _binary, #{Enum.map_join(dims, ", ", &"_#{&1}")}) do
        raise "NIF #{new} not implemented"
      end

      def #{to_binary}(_ctx, _in) do
        raise "NIF #{to_binary} not implemented"
      end

      def #{shape}(_ctx, _in) do
        raise "NIF #{shape} not implemented"
      end

      def #{free}(_ctx, _in) do
        raise "NIF #{free} not implemented"
      end

      def #{from_list}(ctx, xs) do
        {#{Enum.join(dims, ", ")}} = shape(xs)
        #{new}(ctx, #{from_list}_helper(xs, <<>>), #{Enum.join(dims, ", ")})
      end

      defp #{from_list}_helper([], acc), do: acc

      defp #{from_list}_helper([h|t], acc) when is_list(h) do
        #{from_list}_helper(t, #{from_list}_helper(h, acc))
      end

      defp #{from_list}_helper([h|t], acc) do
        #{from_list}_helper(t, <<acc::binary, h::#{type_to_binary(elemtype)}>>)
      end

      def #{to_list}(ctx, ref) do
        {:ok, dims} = #{shape}(ctx, ref)
        {:ok, bin} = #{to_binary}(ctx, ref)
        {res, <<>>} = #{to_list}_helper(dims, [], bin)
        {:ok, res}
      end

      defp #{to_list}_helper(0, acc, bin), do: {Enum.reverse(acc), bin}

      defp #{to_list}_helper(i, acc, <<h::#{type_to_binary(elemtype)}, t::binary>>)
          when is_integer(i) and i > 0 do
        #{to_list}_helper(i-1, [h|acc], t)
      end

      defp #{to_list}_helper([i], acc, bin), do: #{to_list}_helper(i, acc, bin)

      defp #{to_list}_helper([0|_], acc, bin), do: {Enum.reverse(acc), bin}

      defp #{to_list}_helper([i|t], acc, bin) do
        {inner, bin} = #{to_list}_helper(t, [], bin)
        #{to_list}_helper([i-1|t], [inner|acc], bin)
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
      IO.puts(device, Futlixir.EX.new_type(details))
    end
  end

  def type_to_binary("f64"), do: "float-little"
  def type_to_binary("i8"), do: "integer-signed-8-little"
  def type_to_binary("i32"), do: "integer-signed-32-little"
  def type_to_binary("i64"), do: "integer-signed-64-little"
  def type_to_binary("u8"), do: "integer-unsigned-8-little"
  def type_to_binary("u32"), do: "integer-unsigned-32-little"
  def type_to_binary("u64"), do: "integer-unsigned-64-little"

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
