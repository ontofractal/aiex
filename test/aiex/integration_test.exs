defmodule AIex.IntegrationTest do
  use ExUnit.Case, async: true
  import AIex.Query

  @moduletag :integration

  defmodule TestAiRouter do
    use AIex.AiRouter,
      adapter: AIex.Adapters.OpenAI,
      provider: AIex.Providers.OpenRouterProvider
  end

  defmodule SentimentAifn do
    use AIex.Aifunction

    system_input do
      field :instruction, :string
    end

    system_template do
      ~H"""
      Instruction: {@instruction}
      """
    end

    user_input do
      field :text, :string
    end

    user_template do
      ~H"""
      Text: {@text}
      """
    end

    output do
      field :id, :string
      field :sentiment, :string
      field :confidence, :float
    end
  end

  describe "OpenRouter integration with OpenAI" do
    setup do
      api_key = System.fetch_env!("OPENROUTER_API_KEY")
      base_url = System.get_env("OPENROUTER_URL", "https://openrouter.ai/api/v1")

      {:ok, api_key: api_key, base_url: base_url}
    end

    @tag :this
    test "performs sentiment analysis via OpenRouter API", %{api_key: api_key, base_url: base_url} do
      text = "I absolutely love this product! It's amazing and has exceeded all my expectations!"

      response =
        ai(SentimentAifn)
        |> model("google/gemini-pro-1.5")
        |> user_prompt(text: text)
        |> system_prompt(instruction: "Perform sentiment analysis on the given text.")
        |> TestAiRouter.run(api_key: api_key, base_url: base_url)

      assert {:ok, output} = response
      assert output.sentiment in ["positive"]
      assert is_binary(output.id)
      assert is_float(output.confidence)
      assert output.confidence >= 0.0 and output.confidence <= 1.0
    end

    test "handles negative sentiment via OpenRouter API", %{api_key: api_key, base_url: base_url} do
      text = "This is terrible! I hate it and will never use it again!"

      response =
        ai(SentimentAifn)
        |> model("google/gemini-pro-1.5")
        |> user_prompt(text: text)
        |> system_prompt(instruction: "Perform sentiment analysis on the given text.")
        |> TestAiRouter.run(api_key: api_key, base_url: base_url)

      assert {:ok, output} = response
      assert output.sentiment == "negative"
      assert is_float(output.confidence)
      assert output.confidence >= 0.0 and output.confidence <= 1.0
    end
  end

  defmodule TestGeminiAiRouter do
    use AIex.AiRouter,
      adapter: AIex.Adapters.GeminiApiAdapter,
      provider: AIex.Providers.GeminiProvider
  end

  describe "Gemini API integration with GeminiApiAdapter" do
    setup do
      api_key = System.fetch_env!("GEMINI_API_KEY")

      base_url =
        System.get_env("GEMINI_URL", "https://generativelanguage.googleapis.com/v1/models")

      {:ok, api_key: api_key, base_url: base_url}
    end

    test "performs sentiment analysis via Gemini API", %{api_key: api_key, base_url: base_url} do
      text = "I absolutely love this product! It's amazing and has exceeded all my expectations!"

      response =
        ai(SentimentAifn)
        |> model("google/gemini-flash-1.5")
        |> user_prompt(text: text)
        |> TestGeminiAiRouter.run(api_key: api_key, base_url: base_url)

      assert {:ok, output} = response
      assert output.sentiment in ["positive", "negative", "neutral"]
      assert is_binary(output.id)
      assert is_float(output.confidence)
      assert output.confidence >= 0.0 and output.confidence <= 1.0
    end

    test "handles negative sentiment via Gemini API", %{api_key: api_key, base_url: base_url} do
      text = "This is terrible! I hate it and will never use it again!"

      response =
        ai(SentimentAifn)
        |> model("google/gemini-flash-1.5")
        |> user_prompt(text: text)
        |> TestGeminiAiRouter.run(api_key: api_key, base_url: base_url)

      assert {:ok, output} = response
      assert output.sentiment == "negative"
      assert is_float(output.confidence)
      assert output.confidence >= 0.0 and output.confidence <= 1.0
    end
  end

  describe "audio analysis" do
    defmodule AudioAiFn do
      use AIex.Aifunction

      system_template do
        ~H"""
        Transcribe the audio.
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
        field :text, :string
      end
    end

    setup do
      api_key = System.fetch_env!("GEMINI_API_KEY")

      {:ok, api_key: api_key}
    end

    test "performs audio analysis via Gemini API", %{api_key: api_key} do
      text = "Be accurate with your responses."
      audio_file = "test/fixtures/example.ogg"
      audio_data = File.read!(audio_file) |> Base.encode64()

      response =
        ai(AudioAiFn)
        |> model("google/gemini-flash-1.5")
        |> user_prompt(text: text)
        |> user_inline_data(ogg: audio_data)
        |> TestGeminiAiRouter.run(api_key: api_key)

      assert {:ok, output} = response

      assert output.text ==
               "This is an example sound file in Ogg Vorbis format from Wikipedia, the free encyclopedia."
    end
  end
end
