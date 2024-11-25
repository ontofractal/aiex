defmodule AIex.RequestTest do
  use ExUnit.Case

  describe "schema definition" do
    defmodule SentimentSchema do
      use AIex.Aifunction

      @zero_shot true

      inputs do
        field :messages, {:array, :map}, description: "Conversation messages"
      end

      input_template do
        for message <- @messages do
          "#{message.role}: #{message.content}"
        end
      end

      output do
        field(:sentiment, :string, description: "Overall sentiment of the conversation")
        field(:positivity, :float, description: "Positivity score from 0 to 1")
      end
    end

    test "defines input fields correctly" do
      assert SentimentSchema.__schema__(:input_fields) == [:messages]
    end

    test "defines output fields correctly" do
      assert SentimentSchema.__schema__(:output_fields) == [:sentiment, :positivity]
    end

    test "stores input types" do
      expected_types = %{
        messages: {:array, :map}
      }

      assert SentimentSchema.__schema__(:input_types) == expected_types
    end

    test "stores output types" do
      expected_types = %{
        sentiment: :string,
        positivity: :float
      }

      assert SentimentSchema.__schema__(:output_types) == expected_types
    end

    test "stores field descriptions" do
      expected_input_descriptions = %{
        messages: "Conversation messages"
      }

      expected_output_descriptions = %{
        sentiment: "Overall sentiment of the conversation",
        positivity: "Positivity score from 0 to 1"
      }

      assert SentimentSchema.__schema__(:input_descriptions) == expected_input_descriptions
      assert SentimentSchema.__schema__(:output_descriptions) == expected_output_descriptions
    end

    test "formats input according to template" do
      messages = [
        %{role: "user", content: "Hello!"},
        %{role: "assistant", content: "Hi there!"},
        %{role: "user", content: "How are you?"}
      ]

      formatted = SentimentSchema.format_input(%{messages: messages})

      assert formatted == [
               "user: Hello!",
               "assistant: Hi there!",
               "user: How are you?"
             ]
    end

    test "handles zero shot attribute" do
      assert SentimentSchema.__schema__(:zero_shot?) == true
    end
  end
end
