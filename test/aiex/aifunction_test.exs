defmodule AIex.AifunctionTest do
  use ExUnit.Case

  describe "schema definition" do
    defmodule TestSchema do
      use AIex.Aifunction

      user_input do
        field :messages, {:array, :string}
      end

      user_template do
        ~H"""
        <%= for message <- @messages do %>
        <%= message %>
        <% end %>
        """
      end

      output do
        field :sentiment, :string
        field :positivity, :float
      end
    end

    test "defines input fields correctly" do
      assert TestSchema.__schema__(:input_fields) == [:messages]
    end

    test "defines output fields correctly" do
      assert TestSchema.__schema__(:output_fields) == [:sentiment, :positivity]
    end

    test "stores input types" do
      expected_types = %{
        messages: {:array, :string}
      }

      assert TestSchema.__schema__(:input_types) == expected_types
    end

    test "stores output types" do
      expected_types = %{
        sentiment: :string,
        positivity: :float
      }

      assert TestSchema.__schema__(:output_types) == expected_types
    end

    test "validates and formats input" do
      messages = [
        "Hello!",
        "Hi there!",
        "How are you?"
      ]

      assert {:ok, formatted} = TestSchema.format_input(%{messages: messages})
      assert formatted == {:safe, "\nHello!\n\nHi there!\n\nHow are you!\n"}
    end

    test "validates input with Ecto.Changeset" do
      result = TestSchema.cast_input(%{})
      refute result.valid?
      assert result.errors[:messages]
    end

    test "validates user input with embedded schema" do
      import Ecto.Changeset

      result = TestSchema.UserInput.changeset(%{"messages" => ["Hello!", "Hi there!"]})
      assert result.valid?
      assert get_change(result, :messages) == ["Hello!", "Hi there!"]
    end

    test "validates user input with embedded schema - invalid data" do
      import Ecto.Changeset

      result = TestSchema.UserInput.changeset(%{})
      refute result.valid?
      assert result.errors[:messages]
    end

    test "validates output with embedded schema" do
      import Ecto.Changeset
      result = TestSchema.Output.changeset(%{"sentiment" => "positive", "positivity" => 0.9})
      assert result.valid?
      assert get_change(result, :sentiment) == "positive"
      assert get_change(result, :positivity) == 0.9
    end

    test "validates output with embedded schema - invalid data" do
      result = TestSchema.Output.changeset(%{})
      refute result.valid?
      assert result.errors[:sentiment]
      assert result.errors[:positivity]
    end

    test "casts valid output" do
      import Ecto.Changeset

      output = %{
        "sentiment" => "positive",
        "positivity" => 0.9
      }

      result = TestSchema.cast_output(output)
      assert result.valid?
      assert get_change(result, :sentiment) == "positive"
      assert get_change(result, :positivity) == 0.9
    end
  end

  describe "integration with Query" do
    test "complete flow with schema" do
      query =
        AIex.Query.ai()
        |> AIex.Query.model(provider: "openai", model: "gpt-3.5-turbo")
        |> AIex.Query.user_prompt("Hello!")
        |> AIex.Query.assistant_message("Hi there!")
        |> AIex.Query.user_prompt("How are you?")
        |> AIex.Query.response_schema(TestSchema)

      assert {:ok, request} = AIex.OpenAI.to_request(query)
      assert request.model == "gpt-3.5-turbo"
      assert length(request.messages) == 3
    end
  end
end
