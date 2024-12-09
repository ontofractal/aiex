defmodule AIex.Middleware.OutputSchemaMiddleware do
  @moduledoc """
  Middleware that appends structured output schema to the system prompt based on the model.
  Different models may prefer different typing formats (TypeScript, Python, JSON Schema).
  """
  alias AIex.Providers.GeminiProvider

  def init(opts) do
    {:ok, opts}
  end

  def before_request(query, opts \\ [])
  def before_request(%AIex.Query{aifunction: nil} = query, _opts), do: query

  def before_request(%AIex.Query{aifunction: aifunction, model: model} = query, opts) do
    ai_router_config = Keyword.fetch!(opts, :config)
    provider = Keyword.fetch!(ai_router_config, :provider)

    with output_schema <- Module.concat([aifunction, Output]),
         typing_format <- get_typing_format(model, provider),
         formatted_output_schema <-
           AIex.format_output_schema(output_schema, adapter: typing_format) do
      add_structured_schema_output(query, formatted_output_schema, opts)
    end
  end

  def add_structured_schema_output(query, formatted_output_schema, opts) do
    case Keyword.fetch!(opts[:config], :provider) do
      AIex.Providers.GeminiProvider ->
        %{query | output_schema: formatted_output_schema}

      AIex.Providers.OpenRouterProvider ->
        append_schema_to_prompt(query, formatted_output_schema)
    end
  end

  def after_request(response, _opts), do: response

  # Get preferred typing format based on model namespace
  defp get_typing_format(model, provider) when is_binary(model) do
    case {String.split(model, "/"), provider} do
      # Gemini prefers Python
      {["google" | _], GeminiProvider} -> :openapi
      # # Claude prefers TypeScript
      # ["anthropic" | _] -> :typescript
      # # GPT prefers JSON Schema
      # ["openai" | _] -> :json_schema
      # # Llama prefers Python
      # ["meta" | _] -> :python_type_hint
      # Default to TypeScript
      _ -> :typescript
    end
  end

  defp get_typing_format(_), do: :typescript

  defp append_schema_to_prompt(query, formatted_output_schema) do
    updated_system = """
    #{query.system_prompt}

    Return valid JSON only that conforms to the following schema:
    #{formatted_output_schema}
    """

    %{query | system_prompt: updated_system}
  end

  def add_schema_to_opts(opts, schema) do
    Keyword.put(opts, :output_schema, schema)
  end
end
