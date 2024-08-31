defmodule AIex.Test.SchemaHelpers do
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

  defmodule Address do
    use Ecto.Schema

    @primary_key false
    embedded_schema do
      field(:street, :string)
      field(:city, :string)
      field(:country, :string)
      field(:postal_code, :string)
    end
  end

  defmodule ComplexSchema1 do
    use Ecto.Schema

    @primary_key false
    schema "complex_schema_1" do
      field(:title, :string)
      field(:description, :string)
      field(:price, :decimal)
      field(:quantity, :integer)
      field(:categories, {:array, :string})
      field(:metadata, :map)
      field(:published_at, :naive_datetime)
      embeds_one(:address, Address)
    end
  end

  defmodule Item do
    use Ecto.Schema

    @primary_key false
    embedded_schema do
      field(:name, :string)
      field(:quantity, :integer)
      field(:price, :decimal)
    end
  end

  defmodule ComplexSchema2 do
    use Ecto.Schema

    @primary_key false
    schema "complex_schema_2" do
      field(:order_number, :string)
      field(:total_amount, :decimal)
      field(:status, :string)
      field(:placed_at, :utc_datetime)
      embeds_many(:items, Item)
      embeds_one(:shipping_address, Address)
      embeds_one(:billing_address, Address)
    end
  end
end
