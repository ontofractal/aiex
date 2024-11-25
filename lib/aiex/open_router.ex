defmodule AIex.OpenRouter do
  @moduledoc """
  OpenRouter API adapter implementation for OpenAI-compatible interface.
  """
  @behaviour AIex.OpenAI

  @doc """
  Runs a query through OpenRouter.
  """
  def run(%{aifunction: aifunction} = query, opts) when is_list(opts) do
    with {:ok, api_key} <- AIex.OpenAI.validate_api_key(opts),
         {:ok, request} <- AIex.OpenAI.to_request(query),
         {:ok, response} <- make_request(request, api_key) do
      AIex.OpenAI.parse_response(response, aifunction)
    end
  end

  defp make_request(request, api_key) do
    opts = [base_url: "https://openrouter.ai/api/v1"]
    client = AIex.OpenAI.create_client(api_key, opts)

    case OpenaiEx.Chat.Completions.create(client, request) do
      {:ok, response} ->
        {:ok, response}

      {:error, error} ->
        {:error, error}
    end
  end
end
