defmodule AIex.Query do
  @moduledoc """
  Provides a composable query API for building AI/LLM requests.
  Similar to Ecto.Query, this module allows building AI requests in a pipeline.
  """

  defstruct provider: nil,
            model: nil,
            system_prompt: nil,
            messages: [],
            response_schema: nil

  @type message :: %{role: String.t(), content: String.t()}
  @type t :: %__MODULE__{
          provider: String.t() | nil,
          model: String.t() | nil,
          system_prompt: String.t() | nil,
          messages: [message()],
          response_schema: module() | nil
        }

  @doc """
  Creates a new AI query.
  """
  def ai do
    %__MODULE__{}
  end

  @doc """
  Sets the model provider and name for the query.
  """
  def model(query, provider: provider, model: model)
      when is_binary(provider) and is_binary(model) do
    %{query | provider: provider, model: model}
  end

  @doc """
  Sets the system prompt for the query.
  """
  def system_prompt(query, prompt) when is_binary(prompt) do
    %{query | system_prompt: prompt}
  end

  @doc """
  Adds a user message to the conversation.
  """
  def user_prompt(query, content) when is_binary(content) do
    add_message(query, "user", content)
  end

  @doc """
  Adds an assistant message to the conversation.
  """
  def assistant_message(query, content) when is_binary(content) do
    add_message(query, "assistant", content)
  end

  @doc """
  Sets the response schema for the query.
  The schema module should implement AIex.Schema.
  """
  def response_schema(query, schema) when is_atom(schema) do
    %{query | response_schema: schema}
  end

  @doc """
  Validates that the query is ready to be executed.
  """
  def validate(%__MODULE__{} = query) do
    with :ok <- validate_provider_and_model(query),
         :ok <- validate_messages(query),
         :ok <- validate_schema(query) do
      {:ok, query}
    end
  end

  # Private functions

  defp add_message(query, role, content) do
    message = %{role: role, content: content}
    %{query | messages: query.messages ++ [message]}
  end

  defp validate_provider_and_model(%{provider: nil}), do: {:error, "provider is required"}
  defp validate_provider_and_model(%{model: nil}), do: {:error, "model is required"}
  defp validate_provider_and_model(_), do: :ok

  defp validate_messages(%{messages: []}), do: {:error, "at least one message is required"}
  defp validate_messages(_), do: :ok

  defp validate_schema(%{response_schema: nil}), do: {:error, "response schema is required"}
  defp validate_schema(%{response_schema: schema}) do
    if Code.ensure_loaded?(schema) and function_exported?(schema, :__schema__, 1) do
      :ok
    else
      {:error, "invalid schema module"}
    end
  end
end
