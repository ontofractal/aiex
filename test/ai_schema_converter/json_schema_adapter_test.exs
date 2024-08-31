defmodule AIex.AISchemaConverter.JSONSchemaAdapterTest do
  use ExUnit.Case
  alias AIex.AISchemaConverter.JSONSchemaAdapter
  alias AIex.Test.SchemaHelpers.{SimpleSchema, ComplexSchema1, ComplexSchema2}

  test "converts simple Ecto schema to JSON schema" do
    expected = %{
      "name" => "string",
      "age" => "integer",
      "height" => "number",
      "is_active" => "boolean",
      "tags" => ["string"]
    }

    assert AIex.AISchemaConverter.to_json_schema(SimpleSchema) == expected
  end

  test "converts complex Ecto schema with embedded schema to JSON schema" do
    expected = %{
      "id" => "integer",
      "title" => "string",
      "description" => "string",
      "price" => "string",
      "quantity" => "integer",
      "categories" => ["string"],
      "metadata" => "object",
      "published_at" => "string",
      "address" => %{
        "street" => "string",
        "city" => "string",
        "country" => "string",
        "postal_code" => "string"
      }
    }

    assert AIex.AISchemaConverter.to_json_schema(ComplexSchema1) == expected
  end

  test "converts complex Ecto schema with multiple embedded schemas to JSON schema" do
    expected = %{
      "id" => "integer",
      "order_number" => "string",
      "total_amount" => "string",
      "status" => "string",
      "placed_at" => "string",
      "items" => [
        %{
          "name" => "string",
          "quantity" => "integer",
          "price" => "string"
        }
      ],
      "shipping_address" => %{
        "street" => "string",
        "city" => "string",
        "country" => "string",
        "postal_code" => "string"
      },
      "billing_address" => %{
        "street" => "string",
        "city" => "string",
        "country" => "string",
        "postal_code" => "string"
      }
    }

    assert AIex.AISchemaConverter.to_json_schema(ComplexSchema2) == expected
  end
end
