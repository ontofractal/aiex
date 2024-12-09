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
    # Extract model name without the lab name
    model = model_name_to_gemini_model_id(model)
    # Convert chat messages to Gemini format
    contents =
      if query.system_prompt != "" do
        [
          %{role: "model", parts: [%{text: query.system_prompt}]}
          | Enum.map(messages, fn
              %{role: "user", content: content} ->
                %{role: "user", parts: [%{text: content}]}

              %{role: "assistant", content: content} ->
                %{role: "model", parts: [%{text: content}]}
            end)
        ]
      else
        Enum.map(messages, fn
          %{role: "user", content: content} -> %{role: "user", parts: [%{text: content}]}
          %{role: "assistant", content: content} -> %{role: "model", parts: [%{text: content}]}
        end)
      end

    opts =
      if query.output_schema do
        [response_schema: query.output_schema]
      else
        []
      end

    # Build request
    request = %{
      model: model,
      body: %{contents: contents},
      opts: opts
    }

    {:ok, request}
  end

  def prepare_query(_), do: {:error, :invalid_query}

  @doc """
  Converts model names to the format expected by the Gemini API.
  """
  def model_name_to_gemini_model_id(model) do
    [_, model] = model |> String.split("/")

    model
    |> String.split("-")
    |> case do
      ["gemini", submodel, version] -> "gemini-#{version}-#{submodel}"
      [_, _, _] -> raise "Invalid model name: #{model}"
    end
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
  Helper to create Gemini API client with optional base URL
  """
  def create_client(api_key, opts) do
    client = GeminiAI.new(api_key: api_key)

    case Keyword.get(opts, :base_url) do
      nil -> client
      base_url -> %{client | base_url: base_url}
    end
  end
end
