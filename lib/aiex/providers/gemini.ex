defmodule AIex.Providers.GeminiProvider do
  @moduledoc """
  Gemini API provider implementation.
  """

  @default_url "https://generativelanguage.googleapis.com/v1/models"

  @doc """
  Makes a request to the Gemini API.
  """
  def request(prepared_request) do
    api_key = System.get_env("GEMINI_API_KEY")
    _url = System.get_env("GEMINI_URL", @default_url)

    client = GeminiAI.new(api_key: api_key)

    case GeminiAI.generate_content(client, prepared_request.model, prepared_request) do
      {:ok, response} -> {:ok, response}
      {:error, error} -> {:error, "Gemini API error: #{inspect(error)}"}
    end
  end
end
