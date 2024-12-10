defmodule AIex.Adapters.GeminiApiAdapterTest do
  use ExUnit.Case, async: true
  alias AIex.Adapters.GeminiApiAdapter
  alias AIex.Query

  describe "prepare_query/1" do
    test "transforms a basic query with user message" do
      query = %Query{
        model: "gemini-pro",
        messages: [%{role: "user", content: "Hello"}],
        aifunction: nil,
        system_prompt: ""
      }

      assert {:ok, request} = GeminiApiAdapter.prepare_query(query)
      assert %{contents: [%{role: "user", parts: [%{text: "Hello"}]}]} = request
    end

    test "transforms a query with user and assistant messages" do
      query = %Query{
        model: "gemini-pro",
        messages: [
          %{role: "user", content: "Hello"},
          %{role: "assistant", content: "Hi there"}
        ],
        aifunction: nil,
        system_prompt: ""
      }

      assert {:ok, request} = GeminiApiAdapter.prepare_query(query)
      assert %{contents: contents} = request

      assert [
               %{role: "user", parts: [%{text: "Hello"}]},
               %{role: "model", parts: [%{text: "Hi there"}]}
             ] = contents
    end

    test "includes system prompt when present" do
      query = %Query{
        model: "gemini-pro",
        messages: [%{role: "user", content: "Hello"}],
        aifunction: nil,
        system_prompt: "You are a helpful assistant"
      }

      assert {:ok, request} = GeminiApiAdapter.prepare_query(query)

      assert %{
               system_instruction: %{parts: [%{text: "You are a helpful assistant"}]},
               contents: [%{role: "user", parts: [%{text: "Hello"}]}]
             } = request
    end

    test "returns error for invalid query" do
      assert {:error, :invalid_query} = GeminiApiAdapter.prepare_query(%{invalid: "query"})
    end
  end

  describe "validate_api_key/1" do
    test "validates presence of API key" do
      assert {:ok, "test-key"} = GeminiApiAdapter.validate_api_key(api_key: "test-key")
    end

    test "returns error when API key is missing" do
      assert {:error, :missing_api_key} = GeminiApiAdapter.validate_api_key([])
    end

    test "returns error when API key is empty" do
      assert {:error, :missing_api_key} = GeminiApiAdapter.validate_api_key(api_key: "")
    end
  end

  describe "create_client/2" do
    test "creates client with default base URL" do
      client = GeminiApiAdapter.create_client("test-key", [])
      assert %GeminiAI.Client{api_key: "test-key"} = client
    end

    test "creates client with custom base URL" do
      client = GeminiApiAdapter.create_client("test-key", base_url: "https://custom.api.com")
      assert %GeminiAI.Client{api_key: "test-key", base_url: "https://custom.api.com"} = client
    end
  end

  describe "run/2" do
    # Note: These tests would typically require mocking the GeminiAI client
    # For now, we'll test the error cases that don't require external calls

    test "returns error with missing API key" do
      query = %Query{
        model: "gemini-pro",
        messages: [%{role: "user", content: "Hello"}],
        aifunction: nil,
        system_prompt: ""
      }

      assert {:error, :missing_api_key} = GeminiApiAdapter.run(query, [])
    end
  end
end
