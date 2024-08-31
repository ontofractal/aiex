defmodule AISchemaConverter do
  @moduledoc """
  Provides functionality to convert Ecto schemas to various formats.

  This module offers conversion methods for Ecto schemas to JSON schema,
  Python type hint annotations, and TypeScript type declarations.
  """

  alias AISchemaConverter.{JSONSchemaAdapter, PythonTypeHintAdapter, TypeScriptTypeAdapter}

  @doc """
  Converts an Ecto schema to JSON schema.

  ## Examples

      iex> schema = %MyApp.User{name: "John Doe", age: 30}
      iex> AISchemaConverter.to_json_schema(schema)
      %{
        "type" => "object",
        "properties" => %{
          "name" => %{"type" => "string"},
          "age" => %{"type" => "integer"}
        }
      }
  """
  @spec to_json_schema(struct()) :: map()
  def to_json_schema(%_{} = schema) do
    JSONSchemaAdapter.convert(schema)
  end

  @doc """
  Converts an Ecto schema to Python type hint annotations.

  The `flavor` parameter allows specifying the Python type hint style.

  ## Examples

      iex> schema = %MyApp.User{name: "John Doe", age: 30}
      iex> AISchemaConverter.to_python_type_hint(schema)
      "class User:\\n    name: str\\n    age: int"

      iex> AISchemaConverter.to_python_type_hint(schema, :pydantic)
      "from pydantic import BaseModel\\n\\nclass User(BaseModel):\\n    name: str\\n    age: int"
  """
  @spec to_python_type_hint(struct(), atom()) :: String.t()
  def to_python_type_hint(%_{} = schema, flavor \\ :default) when is_atom(flavor) do
    PythonTypeHintAdapter.convert(schema, flavor)
  end

  @doc """
  Converts an Ecto schema to TypeScript type declaration.

  ## Examples

      iex> schema = %MyApp.User{name: "John Doe", age: 30}
      iex> AISchemaConverter.to_typescript_type(schema)
      "interface User {\\n  name: string;\\n  age: number;\\n}"
  """
  @spec to_typescript_type(struct()) :: String.t()
  def to_typescript_type(%_{} = schema) do
    TypeScriptTypeAdapter.convert(schema)
  end
end
