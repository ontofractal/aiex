defmodule AIex.AISchemaConverter.OpenAPIAdapterTest do
  use ExUnit.Case
  alias AIex.AISchemaConverter.OpenAPIAdapter
  alias AIex.Test.SchemaHelpers.{SimpleSchema, ComplexSchema1, ComplexSchema2}

  test "converts simple Ecto schema to OpenAPI schema" do
    expected = %{
      "type" => "object",
      "properties" => %{
        "name" => %{"type" => "string"},
        "age" => %{"type" => "integer", "format" => "int64"},
        "height" => %{"type" => "number", "format" => "float"},
        "is_active" => %{"type" => "boolean"},
        "tags" => %{
          "type" => "array",
          "items" => %{"type" => "string"}
        }
      },
      "required" => ["name", "age", "height", "is_active", "tags"]
    }

    assert OpenAPIAdapter.convert(SimpleSchema) == expected
  end

  test "converts complex Ecto schema with embedded schema to OpenAPI schema" do
    expected = %{
      "type" => "object",
      "properties" => %{
        "id" => %{"type" => "integer", "format" => "int64"},
        "title" => %{"type" => "string"},
        "description" => %{"type" => "string"},
        "price" => %{"type" => "number", "format" => "double"},
        "quantity" => %{"type" => "integer", "format" => "int64"},
        "categories" => %{
          "type" => "array",
          "items" => %{"type" => "string"}
        },
        "metadata" => %{
          "type" => "object",
          "additionalProperties" => true
        },
        "published_at" => %{"type" => "string", "format" => "date-time"},
        "address" => %{
          "type" => "object",
          "properties" => %{
            "street" => %{"type" => "string"},
            "city" => %{"type" => "string"},
            "country" => %{"type" => "string"},
            "postal_code" => %{"type" => "string"}
          },
          "required" => ["street", "city", "country", "postal_code"]
        }
      },
      "required" => [
        "title",
        "description",
        "price",
        "quantity",
        "categories",
        "metadata",
        "published_at",
        "address"
      ]
    }

    assert OpenAPIAdapter.convert(ComplexSchema1) == expected
  end

  test "converts complex Ecto schema with multiple embedded schemas to OpenAPI schema" do
    expected = %{
      "type" => "object",
      "properties" => %{
        "id" => %{"type" => "integer", "format" => "int64"},
        "order_number" => %{"type" => "string"},
        "total_amount" => %{"type" => "number", "format" => "double"},
        "status" => %{"type" => "string"},
        "placed_at" => %{"type" => "string", "format" => "date-time"},
        "items" => %{
          "type" => "array",
          "items" => %{
            "type" => "object",
            "properties" => %{
              "name" => %{"type" => "string"},
              "quantity" => %{"type" => "integer", "format" => "int64"},
              "price" => %{"type" => "number", "format" => "double"}
            },
            "required" => ["name", "quantity", "price"]
          }
        },
        "shipping_address" => %{
          "type" => "object",
          "properties" => %{
            "street" => %{"type" => "string"},
            "city" => %{"type" => "string"},
            "country" => %{"type" => "string"},
            "postal_code" => %{"type" => "string"}
          },
          "required" => ["street", "city", "country", "postal_code"]
        },
        "billing_address" => %{
          "type" => "object",
          "properties" => %{
            "street" => %{"type" => "string"},
            "city" => %{"type" => "string"},
            "country" => %{"type" => "string"},
            "postal_code" => %{"type" => "string"}
          },
          "required" => ["street", "city", "country", "postal_code"]
        }
      },
      "required" => [
        "order_number",
        "total_amount",
        "status",
        "placed_at",
        "items",
        "shipping_address",
        "billing_address"
      ]
    }

    assert OpenAPIAdapter.convert(ComplexSchema2) == expected
  end
end
