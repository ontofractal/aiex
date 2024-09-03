defmodule AIex.Test.SchemaHelpers do
  defmodule SimpleSchema do
    use Ecto.Schema

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

    embedded_schema do
      field(:street, :string)
      field(:city, :string)
      field(:country, :string)
      field(:postal_code, :string)
    end
  end

  defmodule ComplexSchema1 do
    use Ecto.Schema

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

    embedded_schema do
      field(:name, :string)
      field(:quantity, :integer)
      field(:price, :decimal)
    end
  end

  defmodule ComplexSchema2 do
    use Ecto.Schema

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

  defmodule User do
    use Ecto.Schema

    schema "users" do
      field(:name, :string)
      field(:email, :string)
      has_many(:posts, Post)
      has_one(:profile, Profile)
    end
  end

  defmodule Post do
    use Ecto.Schema

    schema "posts" do
      field(:title, :string)
      field(:content, :string)
      belongs_to(:user, User)
      many_to_many(:tags, Tag, join_through: "posts_tags")
    end
  end

  defmodule Profile do
    use Ecto.Schema

    schema "profiles" do
      field(:bio, :string)
      belongs_to(:user, User)
    end
  end

  defmodule Tag do
    use Ecto.Schema

    schema "tags" do
      field(:name, :string)
      many_to_many(:posts, Post, join_through: "posts_tags")
    end
  end
end
