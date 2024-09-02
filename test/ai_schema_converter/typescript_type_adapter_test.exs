defmodule AIex.AISchemaConverter.TypeScriptTypeAdapterTest do
  use ExUnit.Case
  alias AIex.AISchemaConverter.TypeScriptTypeAdapter

  alias AIex.Test.SchemaHelpers.{
    SimpleSchema,
    ComplexSchema1,
    ComplexSchema2,
    User,
    Post,
    Profile,
    Tag
  }

  test "converts simple Ecto schema to TypeScript type declaration" do
    expected = """
    interface SimpleSchema {
      name: string;
      age: number;
      height: number;
      is_active: boolean;
      tags: string[];
    }
    """

    assert String.trim(TypeScriptTypeAdapter.convert(SimpleSchema)) ==
             String.trim(expected)
  end

  @tag :this
  test "converts complex Ecto schema with embedded schema to TypeScript type declaration" do
    expected = """
    interface ComplexSchema1 {
      title: string;
      description: string;
      price: number;
      quantity: number;
      categories: string[];
      metadata: Record<string, any>;
      published_at: string;
      address: {
        street: string;
        city: string;
        country: string;
        postal_code: string;
      };
    }
    """

    assert String.trim(TypeScriptTypeAdapter.convert(ComplexSchema1)) ==
             String.trim(expected)
  end

  test "converts complex Ecto schema with multiple embedded schemas to TypeScript type declaration" do
    expected = """
    interface ComplexSchema2 {
      order_number: string;
      total_amount: number;
      status: string;
      placed_at: string;
      items: Array<{
        name: string;
        quantity: number;
        price: number;
      }>;
      shipping_address: {
        street: string;
        city: string;
        country: string;
        postal_code: string;
      };
      billing_address: {
        street: string;
        city: string;
        country: string;
        postal_code: string;
      };
    }
    """

    assert String.trim(TypeScriptTypeAdapter.convert(ComplexSchema2)) ==
             String.trim(expected)
  end

  test "converts User schema to TypeScript type declaration without associations" do
    expected = """
    interface User {
      name: string;
      email: string;
    }
    """

    assert String.trim(TypeScriptTypeAdapter.convert(User)) ==
             String.trim(expected)
  end

  test "converts Post schema to TypeScript type declaration without associations" do
    expected = """
    interface Post {
      title: string;
      content: string;
    }
    """

    assert String.trim(TypeScriptTypeAdapter.convert(Post)) ==
             String.trim(expected)
  end

  test "converts Profile schema to TypeScript type declaration without associations" do
    expected = """
    interface Profile {
      bio: string;
    }
    """

    assert String.trim(TypeScriptTypeAdapter.convert(Profile)) ==
             String.trim(expected)
  end

  test "converts Tag schema to TypeScript type declaration without associations" do
    expected = """
    interface Tag {
      name: string;
    }
    """

    assert String.trim(TypeScriptTypeAdapter.convert(Tag)) ==
             String.trim(expected)
  end
end
