defmodule AIex.AISchemaConverter.TypeScriptTypeAdapter do
  @moduledoc """
  Adapter for converting Ecto schemas to TypeScript type declarations.
  """

  def convert(schema) do
    schema_name = schema |> Module.split() |> List.last()
    fields_to_exclude = get_fields_to_exclude(schema)
    fields = get_filtered_fields(schema, fields_to_exclude)

    field_declarations =
      Enum.map(fields, fn field ->
        type = schema.__schema__(:type, field)
        typescript_type = type_to_typescript(type, fields_to_exclude)
        "  #{field}: #{typescript_type};"
      end)

    """
    interface #{schema_name} {
    #{Enum.join(field_declarations, "\n")}
    }
    """
  end

  defp get_fields_to_exclude(schema) do
    associations = schema.__schema__(:associations)

    associations
    |> Enum.flat_map(fn assoc ->
      [assoc | [schema.__schema__(:association, assoc).owner_key]]
    end)
    |> Enum.uniq()
  end

  defp get_filtered_fields(schema, fields_to_exclude) do
    schema.__schema__(:fields)
    # |> Enum.reject(&(&1 == :id))
    |> Enum.reject(&Enum.member?(fields_to_exclude, &1))
  end

  defp type_to_typescript(:string, _), do: "string"
  defp type_to_typescript(:integer, _), do: "number"
  defp type_to_typescript(:float, _), do: "number"
  defp type_to_typescript(:boolean, _), do: "boolean"

  defp type_to_typescript({:array, type}, fields_to_exclude),
    do: "#{type_to_typescript(type, fields_to_exclude)}[]"

  defp type_to_typescript(:decimal, _), do: "number"
  defp type_to_typescript(:map, _), do: "Record<string, any>"
  defp type_to_typescript(:naive_datetime, _), do: "string"
  defp type_to_typescript(:id, _), do: "number"
  defp type_to_typescript(:utc_datetime, _), do: "string"
  defp type_to_typescript(:binary_id, _), do: "string"

  defp type_to_typescript(
         {:parameterized, {Ecto.Embedded, %{cardinality: :one, related: schema}}},
         fields_to_exclude
       ) do
    "{\n" <> embedded_fields_to_typescript(schema, fields_to_exclude) <> "\n  }"
  end

  defp type_to_typescript(
         {:parameterized, {Ecto.Embedded, %{cardinality: :many, related: schema}}},
         fields_to_exclude
       ) do
    "Array<{\n" <> embedded_fields_to_typescript(schema, fields_to_exclude) <> "\n  }>"
  end

  defp type_to_typescript(type, _), do: raise("Unsupported type: #{inspect(type)}")

  defp embedded_fields_to_typescript(schema, fields_to_exclude) do
    fields = get_filtered_fields(schema, fields_to_exclude)

    field_declarations =
      Enum.map(fields, fn field ->
        type = schema.__schema__(:type, field)
        typescript_type = type_to_typescript(type, fields_to_exclude)
        "    #{field}: #{typescript_type};"
      end)

    Enum.join(field_declarations, "\n")
  end
end
