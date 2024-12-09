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
    model = model_name_to_gemini_model_id(model)

    contents = build_contents(query, messages)

    opts =
      if query.output_schema do
        [response_schema: query.output_schema]
      else
        []
      end

    request = %{
      model: model,
      body: %{contents: contents},
      opts: opts
    }

    {:ok, request}
  end

  defp build_contents(query, messages) do
    base_contents =
      if query.system_prompt != "" do
        [%{role: "model", parts: [%{text: query.system_prompt}]}]
      else
        []
      end

    contents =
      base_contents ++
        Enum.map(messages, fn
          %{role: "user", content: content} ->
            parts = [%{text: content}]

            parts =
              if Map.has_key?(query, :user_inline_data) do
                parts ++ build_inline_data_parts(query.user_inline_data)
              else
                parts
              end

            %{role: "user", parts: parts}

          %{role: "assistant", content: content} ->
            %{role: "model", parts: [%{text: content}]}
        end)

    contents
  end

  defp build_inline_data_parts(inline_data) do
    Enum.map(inline_data, fn {type, data} ->
      case type do
        :ogg ->
          %{
            inline_data: %{
              mime_type: "audio/ogg",
              data: data
            }
          }

        :mp3 ->
          %{
            inline_data: %{
              mime_type: "audio/mp3",
              data: data
            }
          }

        :wav ->
          %{
            inline_data: %{
              mime_type: "audio/wav",
              data: data
            }
          }

        :aac ->
          %{
            inline_data: %{
              mime_type: "audio/aac",
              data: data
            }
          }

        :flac ->
          %{
            inline_data: %{
              mime_type: "audio/flac",
              data: data
            }
          }

        _ ->
          raise "Unsupported inline data type: #{type}"
      end
    end)
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
