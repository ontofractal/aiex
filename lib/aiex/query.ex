defmodule AIex.Query do
  @moduledoc """
  Provides a composable query API for building AI/LLM requests.
  Similar to Ecto.Query, this module allows building AI requests in a pipeline.
  """

  defstruct provider: nil,
            model: nil,
            messages: [],
            aifunction: nil,
            openai_options: %{}

  @type message :: %{role: String.t(), content: String.t()}
  @type t :: %__MODULE__{
          provider: String.t() | nil,
          model: String.t() | nil,
          messages: [message()],
          aifunction: module() | nil,
          openai_options: map()
        }

  @doc """
  Creates a new AI query.
  """
  def ai(aifunction \\ nil) do
    %__MODULE__{
      aifunction: aifunction
    }
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
  Sets the output schema for the query.
  """
  def output_schema(query, schema) when is_atom(schema) do
    %{query | output_schema: schema}
  end

  @doc """
  Adds a user message to the conversation. If a schema is set and assigns are provided,
  it will render the user template with the given assigns.
  """
  def user_prompt(query, content) when is_binary(content) do
    add_message(query, "user", content)
  end

  def user_prompt(%{aifunction: aifunction} = query, assigns)
      when not is_nil(aifunction) do
    content = apply(aifunction, :render_user_template, [assigns])
    add_message(query, "user", content)
  end

  @doc """
  Adds a system message to the conversation.
  """
  def system_message(query, content) when is_binary(content) do
    add_message(query, "system", content)
  end

  @doc """
  Adds an assistant message to the conversation.
  """
  def assistant_message(query, content) when is_binary(content) do
    add_message(query, "assistant", content)
  end

  defp add_message(query, role, content) do
    message = %{role: role, content: content}
    %{query | messages: query.messages ++ [message]}
  end
end
