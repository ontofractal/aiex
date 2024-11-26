defmodule AIex.AiRouter do
  @moduledoc """
  Provides routing functionality for AI model requests with middleware support.
  """

  @default_middlewares [AIex.Middleware.OutputSchemaMiddleware]

  @callback init(opts :: Keyword.t()) :: {:ok, state :: term} | {:error, term}
  @callback run(query :: AIex.Query.t(), opts :: Keyword.t()) ::
              {:ok, result :: map} | {:error, term}

  @doc """
  Parses the LLM API response into a schema.
  This is a shared implementation that all adapters can use.
  """
  def parse_response(
        %{"choices" => [%{"message" => %{"content" => content}} | _]} = _response,
        aifunction
      )
      when is_atom(aifunction) do
    with {:ok, parsed} <- Jason.decode(content),
         result <- aifunction.cast_output(parsed) do
      result
    else
      {:error, _} -> {:error, :invalid_json}
    end
  end

  def parse_response(_raw_response, _aifunction) do
    {:error, :invalid_response}
  end

  defmacro __using__(opts) do
    quote do
      @behaviour AIex.AiRouter

      def init(opts), do: {:ok, opts}

      def run(query, opts \\ []) do
        default_pre_middlewares = [AIex.Middleware.OutputSchemaMiddleware]
        default_post_middlewares = []

        config = [
          adapter: unquote(opts[:adapter]),
          provider: unquote(opts[:provider])
        ]

        query
        |> apply_middleware(:before_request, default_pre_middlewares)
        |> execute_request(config)
        |> apply_middleware(:after_request, default_post_middlewares)
        |> handle_response()
      end

      defp apply_middleware(data, phase, middlewares) do
        Enum.reduce(middlewares, data, fn middleware, acc ->
          apply(middleware, phase, [data])
        end)
      end

      defp execute_request(query, config) do
        adapter = config[:adapter] || raise "#{__MODULE__} AiRouter adapter not configured"
        provider = config[:provider] || raise "#{__MODULE__} AiRouter provider not configured"

        with {:ok, prepared_query} <- adapter.prepare_query(query),
             {:ok, response} <- provider.request(prepared_query),
             {:ok, parsed} <- AIex.AiRouter.parse_response(response, query.aifunction) do
          {:ok, parsed}
        else
          {:error, _} = err -> err
        end
      end

      defp handle_response({:ok, response}), do: {:ok, response}
      defp handle_response({:error, _} = err), do: err

      defoverridable init: 1, run: 2
    end
  end
end
