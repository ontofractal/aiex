defmodule Aiex.AiRouterTest do
  use ExUnit.Case
  import AIex.Query

  describe "AiRouter" do
    defmodule TestAiRouter do
      use AIex.AiRouter,
        adapter: AIex.Adapters.OpenAI,
        provider: AIex.Providers.OpenRouterProvider
    end

    test "basic usage" do
      ai("Say hello world")
      |> model("google/gemini-1.5-flash")
      |> TestAiRouter.run()
    end
  end
end
