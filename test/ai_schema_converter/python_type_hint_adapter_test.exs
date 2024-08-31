defmodule AIex.AISchemaConverter.PythonTypeHintAdapterTest do
  use ExUnit.Case
  alias AIex.AISchemaConverter.PythonTypeHintAdapter
  alias AIex.Test.SchemaHelpers.{SimpleSchema, ComplexSchema1, ComplexSchema2}

  test "converts simple Ecto schema to default Python type hint annotations" do
    expected =
      "SimpleSchema = TypedDict('SimpleSchema', {name: str, age: int, height: float, is_active: bool, tags: List[str]})"

    assert AIex.AISchemaConverter.to_python_type_hint(SimpleSchema) == expected
  end

  test "converts complex Ecto schema with embedded schema to default Python type hint annotations" do
    expected = """
    Address = TypedDict('Address', {street: str, city: str, country: str, postal_code: str})
    ComplexSchema1 = TypedDict('ComplexSchema1', {
      id: int,
      title: str,
      description: str,
      price: Decimal,
      quantity: int,
      categories: List[str],
      metadata: Dict[str, Any],
      published_at: datetime,
      address: Address
    })
    """

    assert String.trim(AIex.AISchemaConverter.to_python_type_hint(ComplexSchema1)) ==
             String.trim(expected)
  end

  test "converts complex Ecto schema with multiple embedded schemas to default Python type hint annotations" do
    expected = """
    Address = TypedDict('Address', {street: str, city: str, country: str, postal_code: str})
    Item = TypedDict('Item', {name: str, quantity: int, price: Decimal})
    ComplexSchema2 = TypedDict('ComplexSchema2', {
      id: int,
      order_number: str,
      total_amount: Decimal,
      status: str,
      placed_at: datetime,
      items: List[Item],
      shipping_address: Address,
      billing_address: Address
    })
    """

    assert String.trim(AIex.AISchemaConverter.to_python_type_hint(ComplexSchema2)) ==
             String.trim(expected)
  end

  test "converts complex Ecto schema with multiple embedded schemas to Gemini-specific Python type hint annotations" do
    expected = """
    Address = TypedDict('Address', {street: str, city: str, country: str, postal_code: str})
    Item = TypedDict('Item', {name: str, quantity: int, price: Decimal})
    ComplexSchema2 = TypedDict('ComplexSchema2', {
      id: int,
      order_number: str,
      total_amount: Decimal,
      status: str,
      placed_at: datetime,
      items: list[Item],
      shipping_address: Address,
      billing_address: Address
    })
    """

    assert String.trim(AIex.AISchemaConverter.to_python_type_hint(ComplexSchema2, :gemini)) ==
             String.trim(expected)
  end
end
