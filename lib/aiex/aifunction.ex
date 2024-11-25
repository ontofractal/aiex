defmodule AIex.Aifunction do
  @moduledoc """
  Defines AI functions for structured inputs and outputs.
  Similar to Ecto.Schema, this module allows defining structured inputs and outputs for AI models.
  """

  defmacro __using__(_opts) do
    quote do
      import AIex.Aifunction,
        only: [
          field: 2,
          field: 3,
          user_input: 1,
          system_input: 1,
          output: 1,
          user_template: 1,
          system_template: 1
        ]

      import Ecto.Changeset
      @before_compile AIex.Aifunction
      Module.register_attribute(__MODULE__, :user_input_fields, accumulate: true)
      Module.register_attribute(__MODULE__, :system_input_fields, accumulate: true)
      Module.register_attribute(__MODULE__, :output_fields, accumulate: true)
      Module.register_attribute(__MODULE__, :template_module, [])
      Module.register_attribute(__MODULE__, :user_template_content, [])
      Module.register_attribute(__MODULE__, :input_section, [])
      Module.register_attribute(__MODULE__, :has_output_section, [])
    end
  end

  @doc """
  Defines user input fields for the AI schema.
  """
  defmacro user_input(do: block) do
    quote do
      @input_section :user
      unquote(block)
    end
  end

  @doc """
  Defines system input fields for the AI schema.
  """
  defmacro system_input(do: block) do
    quote do
      @input_section :system
      unquote(block)
    end
  end

  @doc """
  Defines output fields for the AI schema.
  """
  defmacro output(do: block) do
    quote do
      @input_section :output
      Module.put_attribute(__MODULE__, :has_output_section, true)
      unquote(block)
    end
  end

  @doc """
  Sets the output schema module for type validation and casting.
  """
  defmacro output_schema(module) do
    quote do
      Module.put_attribute(__MODULE__, :output_schema_module, unquote(module))
    end
  end

  @doc """
  Defines the system template using HEEx syntax with ~H sigil.
  """
  defmacro system_template(do: {:sigil_H, _meta, [{:<<>>, _, [template_str]}, []]}) do
    compiled = EEx.compile_string(template_str)

    quote do
      def render_system_template(assigns) do
        var!(assigns) = assigns
        unquote(compiled)
      end
    end
  end

  @doc """
  Defines the user template using HEEx syntax with ~H sigil.
  """
  defmacro user_template(do: {:sigil_H, _meta, [{:<<>>, _, [template_str]}, []]}) do
    compiled = EEx.compile_string(template_str)

    quote do
      def render_user_template(assigns) do
        var!(assigns) = assigns
        unquote(compiled)
      end
    end
  end

  @doc """
  Defines a field in the AI schema.
  """
  defmacro field(name, type, opts \\ []) do
    quote do
      case @input_section do
        :user ->
          Module.put_attribute(
            __MODULE__,
            :user_input_fields,
            {unquote(name), unquote(type), unquote(opts)}
          )

        :system ->
          Module.put_attribute(
            __MODULE__,
            :system_input_fields,
            {unquote(name), unquote(type), unquote(opts)}
          )

        :output ->
          Module.put_attribute(
            __MODULE__,
            :output_fields,
            {unquote(name), unquote(type), unquote(opts)}
          )
      end
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      def __schema__(:user_input_fields) do
        @user_input_fields |> Enum.map(fn {name, _type, _opts} -> name end)
      end

      def __schema__(:system_input_fields) do
        @system_input_fields |> Enum.map(fn {name, _type, _opts} -> name end)
      end

      def __schema__(:output_fields) do
        @output_fields |> Enum.map(fn {name, _type, _opts} -> name end)
      end

      def __schema__(:user_input_types) do
        @user_input_fields
        |> Enum.map(fn {name, type, _opts} -> {name, type} end)
        |> Enum.into(%{})
      end

      def __schema__(:system_input_types) do
        @system_input_fields
        |> Enum.map(fn {name, type, _opts} -> {name, type} end)
        |> Enum.into(%{})
      end

      def __schema__(:output_types) do
        @output_fields |> Enum.map(fn {name, type, _opts} -> {name, type} end) |> Enum.into(%{})
      end

      def __schema__(:output_schema) do
        if Module.get_attribute(__MODULE__, :has_output_section) do
          __MODULE__
        end
      end

      def cast_user_input(params) do
        types = __schema__(:user_input_types)

        {%{}, types}
        |> cast(params, Map.keys(types))
        |> validate_required(Map.keys(types))
      end

      def cast_system_input(params) do
        types = __schema__(:system_input_types)

        {%{}, types}
        |> cast(params, Map.keys(types))
      end

      def cast_output(params) do
        types = __schema__(:output_types)
        schema_module = __schema__(:output_schema)

        {%{}, types}
        |> cast(params, Map.keys(types))
        |> validate_required(Map.keys(types))
        |> maybe_apply_output_schema(schema_module)
      end

      defp maybe_apply_output_schema(changeset, nil), do: changeset

      defp maybe_apply_output_schema(changeset, schema_module) do
        case changeset do
          %{valid?: true} = changeset ->
            case apply(schema_module, :cast, [changeset.changes]) do
              {:ok, data} ->
                put_in(changeset.changes, data)

              {:error, reason} ->
                add_error(changeset, :output_schema, reason)
            end

          changeset ->
            changeset
        end
      end

      def format_input(params) do
        with {:ok, system_template} <- format_system_template(params),
             {:ok, user_template} <- format_user_template(params) do
          {:ok, [system_template, user_template]}
        end
      end

      defp format_system_template(params) do
        case cast_system_input(params) do
          %{valid?: true} = changeset ->
            {:ok, render_system_template(changeset.changes)}

          _ ->
            {:ok, nil}
        end
      end

      defp format_user_template(params) do
        case cast_user_input(params) do
          %{valid?: true} = changeset ->
            {:ok, render_user_template(changeset.changes)}

          changeset ->
            {:error, changeset}
        end
      end
    end
  end
end
