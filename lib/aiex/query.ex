defmodule AIex.Query do
  @moduledoc """
  Provides a composable query API for building AI/LLM requests.
  Similar to Ecto.Query, this module allows building AI requests in a pipeline.
  """

  defstruct model: nil,
            messages: [],
            aifunction: nil,
            openai_options: %{},
            system_prompt: "",
            output_schema: nil

  @type message :: %{role: String.t(), content: String.t()}
  @type t :: %__MODULE__{
          model: String.t() | nil,
          messages: [message()],
          aifunction: module() | nil,
          openai_options: map(),
          system_prompt: String.t() | nil,
          output_schema: atom() | nil
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
  Sets the model for the query in the format "namespace/name".
  Example: "google/gemini-pro-1.5" or "anthropic/claude-3-opus"
  """
  def model(query, model_string) when is_binary(model_string) do
    case String.split(model_string, "/") do
      [namespace, model_name] when namespace != "" and model_name != "" ->
        %__MODULE__{query | model: model_string}

      _ ->
        raise ArgumentError,
              "Model string must be in format 'namespace/model' with non-empty parts"
    end
  end

  @doc """
  Sets the system prompt for the query.
  """
  def system_prompt(query, prompt) when is_binary(prompt) do
    %__MODULE__{query | system_prompt: prompt}
  end

  def system_prompt(%{aifunction: aifunction} = query, assigns)
      when not is_nil(aifunction) do
    content = apply(aifunction, :render_system_template, [assigns])
    %__MODULE__{query | system_prompt: content}
  end

  @doc """
  Sets the output schema for the query.
  """
  def output_schema(query, schema) when is_atom(schema) do
    %__MODULE__{query | output_schema: schema}
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
    %__MODULE__{query | messages: query.messages ++ [message]}
  end
end
