defmodule AIex.Schema do
  @moduledoc """
  Defines schemas for AI/LLM inputs and outputs.
  Similar to Ecto.Schema, this module allows defining structured inputs and outputs for AI models.
  """

  defmacro __using__(_opts) do
    quote do
      import AIex.Schema, only: [field: 2, field: 3, input: 1, output: 1, input_template: 1]
      import Ecto.Changeset
      @before_compile AIex.Schema
      Module.register_attribute(__MODULE__, :input_fields, accumulate: true)
      Module.register_attribute(__MODULE__, :output_fields, accumulate: true)
      Module.register_attribute(__MODULE__, :template_module, [])
    end
  end

  @doc """
  Defines input fields for the AI schema.
  """
  defmacro input(do: block) do
    quote do
      @input_section true
      unquote(block)
    end
  end

  @doc """
  Defines output fields for the AI schema.
  """
  defmacro output(do: block) do
    quote do
      @input_section false
      unquote(block)
    end
  end

  @doc """
  Defines the input template using HEEx syntax with ~H sigil.
  The template is compiled and validated at compile time.
  """
  defmacro input_template(do: {:sigil_H, _meta, [template_str, []]}) do
    template_module = :"#{__CALLER__.module}.Template"

    quote do
      defmodule unquote(template_module) do
        use Phoenix.Template, pattern: "*.html"

        def render("input.html", assigns) do
          unquote(template_str)
        end
      end

      @template_module unquote(template_module)

      def render_template(assigns) do
        Phoenix.Template.render(@template_module, "input", "html", assigns)
      end
    end
  end

  defmacro input_template(do: _) do
    raise CompileError,
      description: "input_template must use ~H sigil, e.g. ~H\"\"\"\n  template content\n\"\"\""
  end

  @doc """
  Defines a field in the AI schema.
  """
  defmacro field(name, type, opts \\ []) do
    quote do
      if @input_section do
        Module.put_attribute(
          __MODULE__,
          :input_fields,
          {unquote(name), unquote(type), unquote(opts)}
        )
      else
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
      def __schema__(:input_fields) do
        @input_fields |> Enum.map(fn {name, _type, _opts} -> name end)
      end

      def __schema__(:output_fields) do
        @output_fields |> Enum.map(fn {name, _type, _opts} -> name end)
      end

      def __schema__(:input_types) do
        @input_fields |> Enum.map(fn {name, type, _opts} -> {name, type} end) |> Enum.into(%{})
      end

      def __schema__(:output_types) do
        @output_fields |> Enum.map(fn {name, type, _opts} -> {name, type} end) |> Enum.into(%{})
      end

      def cast_input(params) do
        types = __schema__(:input_types)

        {%{}, types}
        |> cast(params, Map.keys(types))
        |> validate_required(Map.keys(types))
      end

      def cast_output(params) do
        types = __schema__(:output_types)

        {%{}, types}
        |> cast(params, Map.keys(types))
        |> validate_required(Map.keys(types))
      end

      def format_input(params) do
        case cast_input(params) do
          %{valid?: true} = changeset ->
            {:ok, render_template(changeset.changes)}

          changeset ->
            {:error, changeset}
        end
      end
    end
  end
end
