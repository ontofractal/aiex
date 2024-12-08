defmodule AIex.Providers.OpenRouterProvider do
  @moduledoc """
  OpenRouter API provider implementation.
  """

  @default_url "https://openrouter.ai/api/v1/chat/completions"

  @doc """
  Makes a request to the OpenRouter API.
  """
  def request(prepared_request) do
    api_key = System.get_env("OPENROUTER_API_KEY")
    url = System.get_env("OPENROUTER_URL", @default_url)

    headers = [
      {"authorization", "Bearer #{api_key}"},
      {"content-type", "application/json"}
    ]

    case Req.post(url,
           json: prepared_request,
           headers: headers
         ) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: status, body: body}} ->
        {:error, "OpenRouter API error: #{status} - #{inspect(body)}"}

      {:error, error} ->
        {:error, "HTTP request failed: #{inspect(error)}"}
    end
  end
end
