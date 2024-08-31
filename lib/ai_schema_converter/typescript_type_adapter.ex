defmodule AIex.AISchemaConverter.TypeScriptTypeAdapter do
  @moduledoc """
  Adapter for converting Ecto schemas to TypeScript type declarations.
  """

  def convert(schema) do
    fields = schema.__schema__(:fields)
    schema_name = schema |> Module.split() |> List.last()

    field_declarations =
      Enum.map(fields, fn field ->
        type = schema.__schema__(:type, field)
        typescript_type = type_to_typescript(type)
        "  #{field}: #{typescript_type};"
      end)

    """
    interface #{schema_name} {
    #{Enum.join(field_declarations, "\n")}
    }
    """
  end

  defp type_to_typescript(:string), do: "string"
  defp type_to_typescript(:integer), do: "number"
  defp type_to_typescript(:float), do: "number"
  defp type_to_typescript(:boolean), do: "boolean"
  defp type_to_typescript({:array, type}), do: "#{type_to_typescript(type)}[]"
  defp type_to_typescript(:decimal), do: "number"
  defp type_to_typescript(:map), do: "Record<string, any>"
  defp type_to_typescript(:naive_datetime), do: "string"
  defp type_to_typescript(:id), do: "number"
  defp type_to_typescript(_), do: "any"
end
