defmodule AIex.OpenAI do
  @moduledoc """
  OpenAI API client for AIex
  """

  @doc """
  Transforms an AIex.Query into an OpenAI API request
  """
  def to_request(query) do
    %{model: _model, messages: _messages} = query

    request = %{
      model: query.model,
      messages: query.messages
    }

    {:ok, request}
  end

  @doc """
  Parses the OpenAI API response into a schema
  """
  def parse_response(
        %{"choices" => [%{"message" => %{"content" => content}} | _]} = _response,
        schema
      ) do
    case Jason.decode(content) do
      {:ok, parsed} -> schema.cast_output(parsed)
      {:error, _} -> {:error, :invalid_json}
    end
  end

  def parse_response(_raw_response, _schema) do
    {:error, :invalid_response}
  end
end
