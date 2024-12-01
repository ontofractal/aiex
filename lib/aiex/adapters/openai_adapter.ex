defmodule AIex.Adapters.OpenAI do
  @moduledoc """
  Adapter for converting AIex queries to OpenAI-compatible format
  """
  alias AIex.Query

  @type t :: module()
  @type query :: AIex.Query.t()
  @type run_opts :: [{:api_key, String.t()} | {:base_url, String.t()}]

  @callback run(query(), run_opts()) :: {:ok, map()} | {:error, term()}

  @doc """
  Transforms an AIex.Query into an OpenAI API request format.
  """
  def prepare_query(%Query{model: model, messages: messages, aifunction: aifunction} = query)
      when is_binary(model) and is_list(messages) and is_atom(aifunction) do
    system_message = %{role: "system", content: query.system_prompt}
    messages = [system_message | messages]
    openai_options = aifunction.__schema__(:openai_options)

    request =
      OpenaiEx.Chat.Completions.new(
        model: model,
        messages: messages
      )
      |> Map.merge(openai_options)

    {:ok, request}
  end

  def prepare_query(_), do: {:error, :invalid_query}

  @doc """
  Helper to validate API key from options
  """
  def validate_api_key(opts) do
    case Keyword.fetch(opts, :api_key) do
      {:ok, key} when is_binary(key) and byte_size(key) > 0 -> {:ok, key}
      _ -> {:error, :missing_api_key}
    end
  end

  @doc """
  Helper to create OpenAI client with optional base URL
  """
  def create_client(api_key, opts) do
    client = OpenaiEx.new(api_key)

    case Keyword.get(opts, :base_url) do
      nil -> client
      base_url -> OpenaiEx.with_base_url(client, base_url)
    end
  end

  def run(query, opts \\ []) do
    with {:ok, api_key} <- validate_api_key(opts),
         client <- create_client(api_key, opts),
         {:ok, request} <- prepare_query(query) do
      OpenaiEx.chat_completion(client, request)
    end
  end
end
