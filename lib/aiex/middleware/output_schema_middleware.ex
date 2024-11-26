defmodule AIex.Middleware.OutputSchemaMiddleware do
  @moduledoc """
  Middleware that appends structured output schema to the system prompt based on the model.
  Different models may prefer different typing formats (TypeScript, Python, JSON Schema).
  """

  def init(opts) do
    {:ok, opts}
  end

  def before_request(query, opts \\ [])
  def before_request(%AIex.Query{aifunction: nil} = query, _opts ), do: query

  def before_request(%AIex.Query{aifunction: aifunction, model: model} = query, _opts ) do
    with output_schema <- Module.concat([aifunction, Output]),
         typing_format <- get_typing_format(model),
         prompt <- AIex.build_json_prompt(output_schema, adapter: typing_format) do
      append_schema_to_prompt(query, prompt)
    end
  end

  def after_request(response, _opts), do: response

  # Get preferred typing format based on model namespace
  defp get_typing_format(model) when is_binary(model) do
    case String.split(model, "/") do
      # ["google" | _] -> :python_type_hint  # Gemini prefers Python
      # ["anthropic" | _] -> :typescript     # Claude prefers TypeScript
      # ["openai" | _] -> :json_schema       # GPT prefers JSON Schema
      # ["meta" | _] -> :python_type_hint    # Llama prefers Python
      _ -> :typescript                     # Default to TypeScript
    end
  end
  defp get_typing_format(_), do: :typescript

  defp append_schema_to_prompt(query, schema_prompt) do
    updated_system = """
    #{query.system_prompt}

    The response MUST conform to this structured output schema:
    #{schema_prompt}
    """

    %{query | system_prompt: updated_system}
  end
end
