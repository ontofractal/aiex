defmodule AIex.QueryTest do
  use ExUnit.Case
  import AIex.Query

  defmodule SentimentSchema do
    use AIex.Aifunction

    input do
      field :questions, {:array, :string}
    end

    input_template do
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
        ai()
        |> model(provider: "google", model: "gemini-flash-1.5")

      assert query.provider == "google"
      assert query.model == "gemini-flash-1.5"
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
        |> response_schema(SentimentSchema)

      assert query.response_schema == SentimentSchema
    end

    test "builds complete query" do
      query =
        ai()
        |> model(provider: "google", model: "gemini-flash-1.5")
        |> system_prompt("You are a helpful assistant")
        |> user_prompt("What is the weather?")
        |> assistant_message("It's sunny.")
        |> user_prompt("What's the temperature?")
        |> response_schema(SentimentSchema)

      assert query.provider == "google"
      assert query.model == "gemini-flash-1.5"
      assert query.system_prompt == "You are a helpful assistant"
      assert length(query.messages) == 3
      assert query.response_schema == SentimentSchema
    end
  end

  describe "query validation" do
    test "validates complete query" do
      query =
        ai()
        |> model(provider: "google", model: "gemini-flash-1.5")
        |> user_prompt("Test message")
        |> response_schema(SentimentSchema)

      assert {:ok, _} = validate(query)
    end

    test "requires provider" do
      query =
        ai()
        |> model(provider: nil, model: "gemini-flash-1.5")
        |> user_prompt("Test message")
        |> response_schema(SentimentSchema)

      assert {:error, "provider is required"} = validate(query)
    end

    test "requires model" do
      query =
        ai()
        |> model(provider: "google", model: nil)
        |> user_prompt("Test message")
        |> response_schema(SentimentSchema)

      assert {:error, "model is required"} = validate(query)
    end

    test "requires at least one message" do
      query =
        ai()
        |> model(provider: "google", model: "gemini-flash-1.5")
        |> response_schema(SentimentSchema)

      assert {:error, "at least one message is required"} = validate(query)
    end

    test "requires response schema" do
      query =
        ai()
        |> model(provider: "google", model: "gemini-flash-1.5")
        |> user_prompt("Test message")

      assert {:error, "response schema is required"} = validate(query)
    end
  end
end
