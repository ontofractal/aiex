defmodule AIex.IntegrationTest do
  use ExUnit.Case, async: true
  import AIex.Query

  @moduletag :integration

  defmodule SentimentAifn do
    use AIex.Aifunction

    system_template do
      ~H"""
      Analyze the sentiment of the following text and respond with a JSON object containing sentiment (positive, negative, or neutral) and confidence (float between 0 and 1).
      """
    end

    user_input do
      field :text, :string
    end

    user_template do
      ~H"""
      Text: <%= @text %>
      """
    end

    output do
      field :sentiment, :string
      field :confidence, :float
    end
  end

  describe "OpenRouter integration" do
    setup do
      api_key = System.fetch_env!("OPENROUTER_API_KEY")
      base_url = System.get_env("OPENROUTER_URL", "https://openrouter.ai/api/v1")

      {:ok, api_key: api_key, base_url: base_url}
    end

    @tag :integration
    @tag :this
    test "performs sentiment analysis via OpenRouter API", %{api_key: api_key, base_url: base_url} do
      text = "I absolutely love this product! It's amazing and has exceeded all my expectations!"

      response =
        ai(SentimentAifn)
        |> model(provider: "google", model: "google/gemini-flash-1.5")
        |> user_prompt(text: text)
        |> AIex.OpenRouter.run(api_key: api_key, base_url: base_url)
        |> IO.inspect()

      assert {:ok, %{valid?: true} = changeset} = response
      assert changeset.changes.sentiment in ["positive", "negative", "neutral"]
      assert is_float(changeset.changes.confidence)
      assert changeset.changes.confidence >= 0.0 and changeset.changes.confidence <= 1.0
    end

    @tag :integration
    test "handles negative sentiment via OpenRouter API", %{api_key: api_key, base_url: base_url} do
      text = "This is terrible! I hate it and will never use it again!"

      response =
        ai(SentimentAifn)
        |> model(provider: "google", model: "google/gemini-flash-1.5")
        |> user_prompt(text: text)
        |> AIex.OpenRouter.run(api_key: api_key, base_url: base_url)

      assert {:ok, %{valid?: true} = changeset} = response
      assert changeset.changes.sentiment == "negative"
      assert is_float(changeset.changes.confidence)
      assert changeset.changes.confidence >= 0.0 and changeset.changes.confidence <= 1.0
    end
  end
end
