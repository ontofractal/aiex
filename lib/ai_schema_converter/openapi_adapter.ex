defmodule AIex.AISchemaConverter.OpenAPIAdapter do
  @moduledoc """
  Adapter for converting Ecto schemas to OpenAPI v3 schema.
  """

  def convert(schema) do
    fields = schema.__schema__(:fields)

    properties =
      Enum.reduce(fields, %{}, fn field, acc ->
        type = schema.__schema__(:type, field)
        Map.put(acc, Atom.to_string(field), field_to_openapi_schema(type, schema, field))
      end)

    required_fields =
      fields
      |> Enum.map(&Atom.to_string/1)

    %{
      "type" => "object",
      "properties" => properties,
      "required" => required_fields
    }
  end

  defp field_to_openapi_schema(:string, _, _) do
    %{"type" => "string"}
  end

  defp field_to_openapi_schema(:integer, _, _) do
    %{"type" => "integer", "format" => "int64"}
  end

  defp field_to_openapi_schema(:float, _, _) do
    %{"type" => "number", "format" => "float"}
  end

  defp field_to_openapi_schema(:decimal, _, _) do
    %{"type" => "number", "format" => "double"}
  end

  defp field_to_openapi_schema(:boolean, _, _) do
    %{"type" => "boolean"}
  end

  defp field_to_openapi_schema(:date, _, _) do
    %{"type" => "string", "format" => "date"}
  end

  defp field_to_openapi_schema(:time, _, _) do
    %{"type" => "string", "format" => "time"}
  end

  defp field_to_openapi_schema(:naive_datetime, _, _) do
    %{"type" => "string", "format" => "date-time"}
  end

  defp field_to_openapi_schema(:utc_datetime, _, _) do
    %{"type" => "string", "format" => "date-time"}
  end

  defp field_to_openapi_schema({:array, type}, schema, field) do
    %{
      "type" => "array",
      "items" => field_to_openapi_schema(type, schema, field)
    }
  end

  defp field_to_openapi_schema(:map, _, _) do
    %{
      "type" => "object",
      "additionalProperties" => true
    }
  end

  defp field_to_openapi_schema(:id, _, _) do
    %{"type" => "integer", "format" => "int64"}
  end

  defp field_to_openapi_schema(type, schema, field) do
    case schema.__schema__(:type, field) do
      {:parameterized, {Ecto.Embedded, %{cardinality: :one, related: related}}} ->
        fields = related.__schema__(:fields) |> Enum.reject(&(&1 == :id))

        properties =
          Enum.reduce(fields, %{}, fn field, acc ->
            type = related.__schema__(:type, field)
            Map.put(acc, Atom.to_string(field), field_to_openapi_schema(type, related, field))
          end)

        %{
          "type" => "object",
          "properties" => properties,
          "required" => Enum.map(fields, &Atom.to_string/1)
        }

      {:parameterized, {Ecto.Embedded, %{cardinality: :many, related: related}}} ->
        fields = related.__schema__(:fields) |> Enum.reject(&(&1 == :id))

        properties =
          Enum.reduce(fields, %{}, fn field, acc ->
            type = related.__schema__(:type, field)
            Map.put(acc, Atom.to_string(field), field_to_openapi_schema(type, related, field))
          end)

        %{
          "type" => "array",
          "items" => %{
            "type" => "object",
            "properties" => properties,
            "required" => Enum.map(fields, &Atom.to_string/1)
          }
        }

      _ ->
        raise "Unsupported type: #{inspect(type)}"
    end
  end
end
