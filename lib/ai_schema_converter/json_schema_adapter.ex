defmodule AIex.AISchemaConverter.JSONSchemaAdapter do
  @moduledoc """
  Adapter for converting Ecto schemas to JSON schemas.
  """

  def convert(schema) do
    fields = schema.__schema__(:fields)

    properties =
      Enum.reduce(fields, %{}, fn field, acc ->
        type = schema.__schema__(:type, field)
        Map.put(acc, Atom.to_string(field), field_to_json_schema(type))
      end)

    %{
      "type" => "object",
      "properties" => properties,
      "required" => Enum.map(fields, &Atom.to_string/1)
    }
  end

  defp field_to_json_schema(:string), do: "string"
  defp field_to_json_schema(:integer), do: "integer"
  defp field_to_json_schema(:float), do: "number"
  defp field_to_json_schema(:boolean), do: "boolean"

  defp field_to_json_schema({:array, type}),
    do: %{"type" => "array", "items" => field_to_json_schema(type)}

  # Default to string for unknown types
  defp field_to_json_schema(_), do: "string"

  # Add a specific handler for :id field
  defp field_to_json_schema(:id), do: "integer"
end
