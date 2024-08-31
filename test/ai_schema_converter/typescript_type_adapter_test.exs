defmodule AISchemaConverter.TypeScriptTypeAdapterTest do
  use ExUnit.Case
  alias AISchemaConverter.TypeScriptTypeAdapter

  defmodule TestSchema do
    use Ecto.Schema

    @primary_key false
    schema "test_schema" do
      field(:name, :string)
      field(:age, :integer)
      field(:height, :float)
      field(:is_active, :boolean)
      field(:tags, {:array, :string})
      field(:metadata, :map)
      field(:created_at, :naive_datetime)
    end
  end

  test "converts Ecto schema to TypeScript type declaration" do
    expected = """
    interface TestSchema {
      name: string;
      age: number;
      height: number;
      is_active: boolean;
      tags: string[];
      metadata: Record<string, any>;
      created_at: string;
    }
    """

    assert String.trim(TypeScriptTypeAdapter.convert(TestSchema)) == String.trim(expected)
  end
end
