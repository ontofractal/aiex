defmodule AIex.AISchemaConverter.PythonTypeHintAdapterTest do
  use ExUnit.Case
  alias AIex.AISchemaConverter.PythonTypeHintAdapter

  defmodule TestSchema do
    use Ecto.Schema

    schema "test_schema" do
      field(:name, :string)
      field(:age, :integer)
      field(:height, :float)
      field(:is_active, :boolean)
      field(:tags, {:array, :string})
    end
  end

  test "converts Ecto schema to default Python type hint annotations" do
    expected =
      "TestSchema = TypedDict('TestSchema', {name: str, age: int, height: float, is_active: bool, tags: List[str]})"

    assert AIex.PythonTypeHintAdapter.convert(TestSchema) == expected
  end

  test "converts Ecto schema to Gemini-specific Python type hint annotations" do
    expected =
      "TestSchema = TypedDict('TestSchema', {name: str, age: int, height: float, is_active: bool, tags: list[str]})"

    assert AIex.PythonTypeHintAdapter.convert(TestSchema, :gemini) == expected
  end
end
