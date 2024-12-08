defmodule AIex.Adapters.GeminiApiAdapter do
  @moduledoc """
  Adapter for converting AIex queries to Gemini-compatible format
  """
  alias AIex.Query

  @type t :: module()
  @type query :: AIex.Query.t()
  @type run_opts :: [{:api_key, String.t()} | {:base_url, String.t()}]

  @callback run(query(), run_opts()) :: {:ok, map()} | {:error, term()}

  @doc """
  Transforms an AIex.Query into a Gemini API request format.
  """
  def prepare_query(%Query{model: model, messages: messages, aifunction: aifunction} = query)
      when is_binary(model) and is_list(messages) and is_atom(aifunction) do
    dbg(query)

    # Convert chat messages to Gemini format
    contents =
      Enum.map(messages, fn
        %{role: "user", content: content} -> %{role: "user", parts: [%{text: content}]}
        %{role: "assistant", content: content} -> %{role: "model", parts: [%{text: content}]}
      end)

    # Build request with system instruction if present
    request =
      if query.system_prompt != "" do
        %{
          system_instruction: %{
            parts: [%{text: query.system_prompt}]
          },
          contents: contents
        }
      else
        %{contents: contents}
      end

    dbg(request)
    {:ok, request}
  end

  def prepare_query(_), do: {:error, :invalid_query}

  @doc """
  Helper to validate API key from options
  """
  def validate_api_key(opts) do
    dbg(opts)

    case Keyword.fetch(opts, :api_key) do
      {:ok, key} when is_binary(key) and byte_size(key) > 0 -> {:ok, key}
      _ -> {:error, :missing_api_key}
    end
  end

  @doc """
  Helper to create Gemini API client with optional base URL
  """
  def create_client(api_key, opts) do
    client = GeminiAI.new(api_key: api_key)

    case Keyword.get(opts, :base_url) do
      nil -> client
      base_url -> GeminiAI.with_base_url(client, base_url)
    end
  end

  def run(query, opts \\ []) do
    with {:ok, api_key} <- validate_api_key(opts),
         client <- create_client(api_key, opts),
         {:ok, request} <- prepare_query(query),
         {:ok, response} <- GeminiAI.generate_content(client, query.model, request) do
      dbg(response)

      transformed_response = %{
        "choices" => [
          %{
            "message" => %{
              "content" => GeminiAI.get_text(response)
            }
          }
        ]
      }

      dbg(transformed_response)
      {:ok, transformed_response}
    end
  end
end
