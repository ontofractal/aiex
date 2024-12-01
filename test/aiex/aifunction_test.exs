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

    test "validates input" do
      assert {:error, _} = TestSchema.cast_input(%{})
    end

    test "validates user input with embedded schema" do
      assert {:ok, input} = TestSchema.cast_input(%{"messages" => ["Hello!", "Hi there!"]})
      assert input.messages == ["Hello!", "Hi there!"]
    end

    test "validates user input with embedded schema - invalid data" do
      assert {:error, _} = TestSchema.cast_input(%{})
    end

    test "validates output with embedded schema" do
      assert {:ok, output} =
               TestSchema.cast_output(%{"sentiment" => "positive", "positivity" => 0.9})

      assert output.sentiment == "positive"
      assert output.positivity == 0.9
    end

    test "validates output with embedded schema - invalid data" do
      assert {:error, _} = TestSchema.cast_output(%{})
    end

    test "casts valid output" do
      params = %{
        "sentiment" => "positive",
        "positivity" => 0.9
      }

      assert {:ok, output} = TestSchema.cast_output(params)
      assert output.sentiment == "positive"
      assert output.positivity == 0.9
    end
  end

  describe "complex schema with embedded fields" do
    defmodule ComplexSchema do
      use AIex.Aifunction

      defmodule Address do
        use Ecto.Schema
        import Ecto.Changeset

        @primary_key false
        embedded_schema do
          field :street, :string
          field :city, :string
          field :country, :string
        end

        def changeset(struct, params) do
          struct
          |> cast(params, [:street, :city, :country])
          |> validate_required([:city, :country])
        end
      end

      defmodule MessageContext do
        use Ecto.Schema
        import Ecto.Changeset

        @primary_key false
        embedded_schema do
          field :context_type, :string
          field :relevance_score, :float
        end

        def changeset(struct, params) do
          struct
          |> cast(params, [:context_type, :relevance_score])
          |> validate_required([:context_type])
          |> validate_number(:relevance_score,
            greater_than_or_equal_to: 0,
            less_than_or_equal_to: 1
          )
        end
      end

      user_input do
        field :user_id, :string
        field :message, :string
        embeds_one(:location, Address)
        embeds_many(:contexts, MessageContext)
      end

      output do
        field :response, :string
        field :confidence_score, :float
        embeds_one(:source_location, Address)
        embeds_many(:relevant_contexts, MessageContext)
      end
    end

    test "validates user input with valid embedded fields" do
      input_params = %{
        "user_id" => "user123",
        "message" => "Hello from Paris!",
        "location" => %{
          "street" => "123 Champs-Élysées",
          "city" => "Paris",
          "country" => "France"
        },
        "contexts" => [
          %{"context_type" => "greeting", "relevance_score" => 0.9},
          %{"context_type" => "location", "relevance_score" => 0.7}
        ]
      }

      assert {:ok, input} = ComplexSchema.cast_input(input_params)
      assert input.user_id == "user123"
      assert input.message == "Hello from Paris!"
      assert input.location.city == "Paris"
      assert length(input.contexts) == 2
      assert Enum.at(input.contexts, 0).context_type == "greeting"
    end

    test "validates user input with invalid embedded fields" do
      input_params = %{
        "user_id" => "user123",
        "message" => "Hello!",
        "location" => %{
          "street" => "123 Main St"
          # missing required city and country
        },
        "contexts" => [
          # invalid score
          %{"context_type" => "greeting", "relevance_score" => 1.5}
        ]
      }

      assert {:error, changeset} = ComplexSchema.cast_input(input_params)
      assert %{location: %{city: ["can't be blank"]}} = errors_on(changeset)

      assert %{contexts: [%{relevance_score: ["must be less than or equal to 1"]}]} =
               errors_on(changeset)
    end

    test "validates output with valid embedded fields" do
      output_params = %{
        "response" => "Greetings from the AI!",
        "confidence_score" => 0.95,
        "source_location" => %{
          "city" => "San Francisco",
          "country" => "USA"
        },
        "relevant_contexts" => [
          %{"context_type" => "greeting", "relevance_score" => 0.9}
        ]
      }

      assert {:ok, output} = ComplexSchema.cast_output(output_params)
      assert output.response == "Greetings from the AI!"
      assert output.confidence_score == 0.95
      assert output.source_location.city == "San Francisco"
      assert length(output.relevant_contexts) == 1
    end

    test "validates output with missing required embedded fields" do
      output_params = %{
        "response" => "Hello!",
        "confidence_score" => 0.95,
        # missing required fields
        "source_location" => %{},
        "relevant_contexts" => [
          # missing required fields
          %{}
        ]
      }

      assert {:error, changeset} = ComplexSchema.cast_output(output_params)
      assert %{source_location: %{city: ["can't be blank"]}} = errors_on(changeset)
      assert %{relevant_contexts: [%{context_type: ["can't be blank"]}]} = errors_on(changeset)
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

      assert {:ok, request} = AIex.Adapters.OpenAI.to_request(query)
      assert request.model == "gpt-3.5-turbo"
      assert length(request.messages) == 3
    end
  end

  # Helper function for error testing
  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
