defmodule AIex do
  @moduledoc """
  Documentation for `AIex`.
  """

  alias AIex.AISchemaConverter.{
    JSONSchemaAdapter,
    PythonTypeHintAdapter,
    TypeScriptTypeAdapter
  }

  @schema_options [
    adapter: [
      type: {:in, [:json_schema, :python_type_hint, :typescript]},
      required: true
    ],
    format: [
      type: {:in, [:default, :gemini]},
      default: :default
    ]
  ]

  @doc """
  Builds a JSON prompt for the given schema and options.

  ## Options

    * `:adapter` - The adapter to use for conversion. Required.
      Allowed values: `:json_schema`, `:python_type_hint`, `:typescript`
    * `:format` - The format to use for Python type hints. Optional.
      Allowed values: `:default`, `:gemini`. Defaults to `:default`.

  ## Examples

      iex> schema = MyApp.User
      iex> AIex.build_json_prompt(schema, adapter: :json_schema)
      "{\\"type\\":\\"object\\",\\"properties\\":{\\"id\\":{\\"type\\":\\"integer\\"},\\"name\\":{\\"type\\":\\"string\\"}},\\"required\\":[\\"id\\",\\"name\\"]}"

      iex> schema = MyApp.Post
      iex> AIex.build_json_prompt(schema, adapter: :python_type_hint, format: :gemini)
      "class Post:\\n    id: int\\n    title: str\\n    content: str"

  """
  @spec build_json_prompt(%{__meta__: any()}, keyword()) :: String.t()
  def build_json_prompt(schema, opts \\ []) when is_atom(schema) do
    case NimbleOptions.validate(opts, @schema_options) do
      {:ok, valid_opts} ->
        do_build_json_prompt(schema, valid_opts)

      {:error, error} ->
        raise ArgumentError, message: Exception.message(error)
    end
  end

  defp do_build_json_prompt(schema, opts) do
    case opts[:adapter] do
      :json_schema ->
        schema
        |> JSONSchemaAdapter.convert()
        |> Jason.encode!()

      :python_type_hint ->
        PythonTypeHintAdapter.convert(schema, opts[:format])

      :typescript ->
        TypeScriptTypeAdapter.convert(schema)
    end
  end
end
