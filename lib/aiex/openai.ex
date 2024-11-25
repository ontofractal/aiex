defmodule AIex.OpenAI do
  @moduledoc """
  OpenAI-compatible API adapter behaviour and implementation.
  This module defines the behaviour that OpenAI-compatible API providers must implement,
  similar to how Ecto.Adapter works.
  """

  @type t :: module()
  @type query :: AIex.Query.t()
  @type run_opts :: [{:api_key, String.t()} | {:base_url, String.t()}]

  @doc """
  Callback invoked to run a query through an OpenAI-compatible API.
  """
  @callback run(query(), run_opts()) :: {:ok, map()} | {:error, term()}

  @doc """
  Transforms an AIex.Query into an OpenAI API request format.
  This is a shared implementation that adapters can use.
  """
  def to_request(
        %{
          model: model,
          messages: messages,
          aifunction: aifunction
        } = _query
      )
      when is_binary(model) and is_list(messages) and is_atom(aifunction) do
    system_message = %{role: "system", content: aifunction.render_system_template(%{})}
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

  def to_request(_), do: {:error, :invalid_query}

  @doc """
  Parses the OpenAI API response into a schema.
  This is a shared implementation that adapters can use.
  """
  def parse_response(
        %{"choices" => [%{"message" => %{"content" => content}} | _]} = _response,
        aifunction
      )
      when is_atom(aifunction) do
    with {:ok, parsed} <- Jason.decode(content),
         changeset <- aifunction.cast_output(parsed),
         true <- changeset.valid? do
      {:ok, changeset}
    else
      {:error, _} -> {:error, :invalid_json}
      false -> {:error, :invalid_schema}
    end
  end

  def parse_response(_raw_response, _aifunction) do
    {:error, :invalid_response}
  end

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
end
