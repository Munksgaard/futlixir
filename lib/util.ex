defmodule Futlixir.Util do

  def safe_field_name(<<first, rest::binary>> = string) when first >= ?0 and first <= ?9 do
    "v#{string}"
  end
  def safe_field_name(string), do: string

end
