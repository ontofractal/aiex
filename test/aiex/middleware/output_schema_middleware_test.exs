defmodule AIex.Middleware.OutputSchemaMiddlewareTest do
  use ExUnit.Case
  alias AIex.Middleware.OutputSchemaMiddleware
  alias AIex.Query

  defmodule TestAIFunction do
    use AIex.Aifunction

    output do
      field :name, :string
      field :age, :integer
    end
  end

  describe "before_request/2" do
    test "skips when no aifunction is set" do
      query = %Query{messages: [], aifunction: nil}
      assert OutputSchemaMiddleware.before_request(query, []) == query
    end

    test "uses Python type hints for Google models" do
      query = %Query{
        messages: [],
        aifunction: TestAIFunction,
        model: "google/gemini-pro"
      }

      result = OutputSchemaMiddleware.before_request(query, [])
      [system_message | _] = result.messages

      assert system_message.role == "system"
      assert system_message.content =~ "class TestAIFunction:"
      assert system_message.content =~ "name: str"
      assert system_message.content =~ "age: int"
    end

    test "uses TypeScript for Anthropic models" do
      query = %Query{
        messages: [],
        aifunction: TestAIFunction,
        model: "anthropic/claude-3"
      }

      result = OutputSchemaMiddleware.before_request(query, [])
      [system_message | _] = result.messages

      assert system_message.role == "system"
      assert system_message.content =~ "type TestAIFunction"
      assert system_message.content =~ "name: string"
      assert system_message.content =~ "age: number"
    end

    test "uses JSON Schema for OpenAI models" do
      query = %Query{
        messages: [],
        aifunction: TestAIFunction,
        model: "openai/gpt-4"
      }

      result = OutputSchemaMiddleware.before_request(query, [])
      [system_message | _] = result.messages

      assert system_message.role == "system"
      assert system_message.content =~ ~s("type": "object")
      assert system_message.content =~ ~s("name": {"type": "string"})
      assert system_message.content =~ ~s("age": {"type": "integer"})
    end

    test "defaults to TypeScript for unknown models" do
      query = %Query{
        messages: [],
        aifunction: TestAIFunction,
        model: "unknown/model"
      }

      result = OutputSchemaMiddleware.before_request(query, [])
      [system_message | _] = result.messages

      assert system_message.role == "system"
      assert system_message.content =~ "type TestAIFunction"
      assert system_message.content =~ "name: string"
      assert system_message.content =~ "age: number"
    end
  end

  test "after_request/2 returns response unchanged" do
    response = %{status: :ok}
    assert OutputSchemaMiddleware.after_request(response, []) == response
  end
end
