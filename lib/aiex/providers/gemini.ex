defmodule AIex.Providers.GeminiProvider do
  @moduledoc """
  Gemini API provider implementation.
  """

  @doc """
  Makes a request to the Gemini API.
  """
  def request(prepared_request) do
    api_key = System.get_env("GEMINI_API_KEY")

    client = GeminiAI.new(api_key: api_key)

    case GeminiAI.generate_content(
           client,
           prepared_request.model,
           prepared_request.body,
           prepared_request.opts
         ) do
      {:ok, response} ->
        dbg()
        {:ok, response}

      {:error, error} ->
        {:error, "Gemini API error: #{inspect(error)}"}
    end
  end
end
