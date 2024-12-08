defmodule Aiex.Adapters.Adapter do
  @moduledoc """
  Behavior module for AI adapters.
  """

  @callback run(query :: Aiex.Query.t(), opts :: keyword()) :: {:ok, map()} | {:error, term()}
  @callback prepare_query(query :: Aiex.Query.t()) :: {:ok, map()} | {:error, term()}
  @callback validate_api_key(opts :: keyword()) :: {:ok, String.t()} | {:error, term()}
  @callback create_client(api_key :: String.t(), opts :: keyword()) :: any()
end
