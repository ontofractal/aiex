defmodule AIex.AISchemaConverter.JSONSchemaAdapterTest do
  use ExUnit.Case
  alias AIex.AISchemaConverter.JSONSchemaAdapter

  defmodule SimpleSchema do
    use Ecto.Schema

    @primary_key false
    schema "simple_schema" do
      field(:name, :string)
      field(:age, :integer)
      field(:height, :float)
      field(:is_active, :boolean)
      field(:tags, {:array, :string})
    end
  end

  defmodule ComplexSchema do
    use Ecto.Schema

    schema "complex_schema" do
      field(:title, :string)
      field(:description, :string)
      field(:price, :decimal)
      field(:quantity, :integer)
      field(:categories, {:array, :string})
      field(:metadata, :map)
      field(:published_at, :naive_datetime)
    end
  end

  test "converts simple Ecto schema to JSON schema" do
    expected = %{
      "type" => "object",
      "properties" => %{
        "name" => "string",
        "age" => "integer",
        "height" => "number",
        "is_active" => "boolean",
        "tags" => %{"type" => "array", "items" => "string"}
      },
      "required" => ["name", "age", "height", "is_active", "tags"]
    }

    assert AIex.JSONSchemaAdapter.convert(SimpleSchema) == expected
  end

  test "converts complex Ecto schema to JSON schema" do
    expected = %{
      "type" => "object",
      "properties" => %{
        "id" => "integer",
        "title" => "string",
        "description" => "string",
        "price" => "string",
        "quantity" => "integer",
        "categories" => "[string]",
        "metadata" => "string",
        "published_at" => "string"
      },
      "required" => [
        "id",
        "title",
        "description",
        "price",
        "quantity",
        "categories",
        "metadata",
        "published_at"
      ]
    }

    assert AIex.JSONSchemaAdapter.convert(ComplexSchema) == expected
  end
end
