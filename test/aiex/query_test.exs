defmodule AIex.QueryTest do
  use ExUnit.Case
  import AIex.Query

  defmodule SentimentSchema do
    use AIex.Aifunction

    user_input do
      field :questions, {:array, :string}
    end

    user_template do
      ~H"""
      <%= for question <- @questions do %>
      <%= question %>
      <%= end %>
      """
    end

    output do
      field :answers, {:array, :string}
    end
  end

  describe "query building" do
    test "creates a basic query" do
      query = ai()
      assert %AIex.Query{} = query
    end

    test "sets model and provider" do
      query =
        ai() |> model("google/gemini-pro-1.5")

      assert query.model == "google/gemini-pro-1.5"
    end

    test "sets system prompt" do
      query =
        ai()
        |> system_prompt("You are a helpful assistant")

      assert query.system_prompt == "You are a helpful assistant"
    end

    test "adds user message" do
      query =
        ai()
        |> user_prompt("What is the weather?")

      assert [%{role: "user", content: "What is the weather?"}] = query.messages
    end

    test "adds multiple conversation messages" do
      query =
        ai()
        |> user_prompt("What is the weather?")
        |> assistant_message("It's sunny and warm.")
        |> user_prompt("What's the temperature?")

      assert [
               %{role: "user", content: "What is the weather?"},
               %{role: "assistant", content: "It's sunny and warm."},
               %{role: "user", content: "What's the temperature?"}
             ] = query.messages
    end

    test "sets response schema" do
      query =
        ai()

      assert query.response_schema == SentimentSchema
    end

    test "builds complete query" do
      query =
        ai()
        |> model("google/gemini-pro-1.5")
        |> system_prompt("You are a helpful assistant")
        |> user_prompt("What is the weather?")
        |> assistant_message("It's sunny.")
        |> user_prompt("What's the temperature?")

      assert query.model == "google/gemini-pro-1.5"
      assert query.system_prompt == "You are a helpful assistant"
      assert length(query.messages) == 3
    end

    test "creates a query with prompt string" do
      query = ai("Test prompt")
      assert %AIex.Query{} = query
      assert [%{role: "user", content: "Test prompt"}] = query.messages
      assert is_nil(query.aifunction)
    end

    test "creates a query with multiline prompt" do
      prompt = """
      This is a multiline
      test prompt with
      multiple lines
      """

      query = ai(prompt)
      assert %AIex.Query{} = query
      assert [%{role: "user", content: ^prompt}] = query.messages
      assert is_nil(query.aifunction)
    end
  end

  describe "OpenRouter model names" do
    test "requires full model name for OpenRouter" do
      query =
        ai()
        |> model("openai/gpt-4")

      assert query.model == "openai/gpt-4"

      query =
        ai()
        |> model("google/gemini-pro-1.5")

      assert query.model == "google/gemini-pro-1.5"
    end

    test "raises error for invalid model format" do
      assert_raise ArgumentError, "Model string must be in format 'namespace/model'", fn ->
        ai()
        |> model("invalid-model-format")
      end

      assert_raise ArgumentError, "Model string must be in format 'namespace/model'", fn ->
        ai()
        |> model("gemini-pro-1.5")
      end
    end
  end

  describe "query validation" do
    test "validates complete query" do
      query =
        ai()
        |> model("openai/gpt-4")
        |> user_prompt("Test message")

      assert :ok = AIex.Query.validate_query(query)
    end

    test "requires at least one message" do
      query =
        ai()
        |> model("openai/gpt-4")

      assert {:error, :messages_required} = AIex.Query.validate_query(query)
    end

    test "requires response schema when aifunction has output" do
      query =
        ai(SentimentSchema)
        |> model("openai/gpt-4")
        |> user_prompt(%{questions: ["How are you?"]})

      assert {:error, :response_schema_required} = AIex.Query.validate_query(query)
    end

    test "requires model" do
      query =
        ai()
        |> user_prompt("What is the weather?")

      assert {:error, :model_required} = validate_query(query)
    end

    test "requires response schema" do
      query =
        ai()
        |> model("google/gemini-pro-1.5")
        |> user_prompt("Test message")

      assert {:error, :response_schema_required} = validate_query(query)
    end
  end

  describe "input validation" do
    test "raises error for invalid model format" do
      assert_raise ArgumentError, ~r/Model string must be in format.*with non-empty parts/, fn ->
        ai() |> model("invalid_model")
      end

      assert_raise ArgumentError, ~r/Model string must be in format.*with non-empty parts/, fn ->
        ai() |> model("/no-namespace")
      end

      assert_raise ArgumentError, ~r/Model string must be in format.*with non-empty parts/, fn ->
        ai() |> model("namespace/")
      end
    end

    test "validates user input against schema" do
      query = ai(SentimentSchema)

      assert_raise ArgumentError, ~r/message content must be a string or valid assigns map/, fn ->
        query |> user_prompt(%{invalid: "format"})
      end
    end

    test "validates system prompt is string" do
      assert_raise ArgumentError, ~r/system prompt must be a string/, fn ->
        ai() |> system_prompt(123)
      end
    end
  end

  # Helper to get errors from changeset
  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
