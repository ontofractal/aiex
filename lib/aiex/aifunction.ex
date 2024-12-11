defmodule AIex.Aifunction do
  @moduledoc """
  Defines AI functions for structured inputs and outputs.
  Similar to Ecto.Schema, this module allows defining structured inputs and outputs for AI models.
  """

  defmacro __using__(_opts) do
    quote do
      import AIex.Aifunction,
        only: [
          ai_field: 2,
          ai_field: 3,
          user_input: 1,
          system_input: 1,
          output: 1,
          user_template: 1,
          system_template: 1
        ]

      import Ecto.Changeset
      import Ecto.Schema
      @before_compile AIex.Aifunction
      Module.register_attribute(__MODULE__, :user_input_fields, accumulate: true)
      Module.register_attribute(__MODULE__, :system_input_fields, accumulate: true)
      Module.register_attribute(__MODULE__, :output_fields, accumulate: true)
      Module.register_attribute(__MODULE__, :template_module, [])
      Module.register_attribute(__MODULE__, :user_template_content, [])
      Module.register_attribute(__MODULE__, :system_template_content, [])
      Module.register_attribute(__MODULE__, :has_system_template, default: false)
      Module.register_attribute(__MODULE__, :input_section, [])
      Module.register_attribute(__MODULE__, :has_output_section, [])
      Module.register_attribute(__MODULE__, :has_system_input, default: false)
      Module.register_attribute(__MODULE__, :user_input_schema_module, [])
      Module.register_attribute(__MODULE__, :system_input_schema_module, [])
      Module.register_attribute(__MODULE__, :output_schema_module, [])
    end
  end

  @doc """
  Defines user input fields for the AI schema.
  """
  defmacro user_input(do: block) do
    quote do
      @input_section :user

      defmodule UserInput do
        use Ecto.Schema
        import Ecto.Changeset

        @primary_key false
        embedded_schema do
          unquote(block)
        end

        def changeset(struct \\ %__MODULE__{}, params) do
          fields = __MODULE__.__schema__(:fields)
          non_embeds = fields -- __MODULE__.__schema__(:embeds)
          embeds = __MODULE__.__schema__(:embeds)

          struct
          |> cast(params, non_embeds)
          |> cast_embeds_if_any(embeds)
          |> validate_required(non_embeds)
        end

        defp cast_embeds_if_any(changeset, []), do: changeset

        defp cast_embeds_if_any(changeset, embeds) do
          Enum.reduce(embeds, changeset, fn embed, acc ->
            cast_embed(acc, embed,
              with: fn
                # this line casts params that are passed by caller in user input as structs
                struct, params when is_struct(params) ->
                  params.__struct__.changeset(params, %{})

                # this line casts embedded struct for params that are maps (not structs)
                struct, params ->
                  struct.__struct__.changeset(struct, params)
              end
            )
          end)
        end
      end

      Module.put_attribute(__MODULE__, :user_input_schema_module, UserInput)
    end
  end

  @doc """
  Defines system input fields for the AI schema.
  """
  defmacro system_input(do: block) do
    quote do
      @input_section :system

      # Register that we have system input fields
      Module.put_attribute(__MODULE__, :has_system_input, true)

      defmodule SystemInput do
        use Ecto.Schema
        import Ecto.Changeset

        @primary_key false
        embedded_schema do
          unquote(block)
        end

        def changeset(struct \\ %__MODULE__{}, params) do
          fields = __MODULE__.__schema__(:fields)
          non_embeds = fields -- __MODULE__.__schema__(:embeds)
          embeds = __MODULE__.__schema__(:embeds)

          struct
          |> cast(params, non_embeds)
          |> cast_embeds_if_any(embeds)
          |> validate_required(non_embeds)
        end

        defp cast_embeds_if_any(changeset, []), do: changeset

        defp cast_embeds_if_any(changeset, embeds) do
          Enum.reduce(embeds, changeset, fn embed, acc ->
            cast_embed(acc, embed,
              with: fn
                struct, params when is_struct(params) ->
                  params.__struct__.changeset(params, %{})

                struct, params ->
                  struct.__struct__.changeset(struct, params)
              end
            )
          end)
        end
      end

      Module.put_attribute(__MODULE__, :system_input_schema_module, SystemInput)
    end
  end

  @doc """
  Defines output fields for the AI schema.
  """
  defmacro output(do: block) do
    quote do
      @input_section :output
      Module.put_attribute(__MODULE__, :has_output_section, true)

      defmodule Output do
        use Ecto.Schema
        import Ecto.Changeset

        @primary_key false
        embedded_schema do
          unquote(block)
        end

        def changeset(struct \\ %__MODULE__{}, params) do
          fields = __MODULE__.__schema__(:fields)
          non_embeds = fields -- __MODULE__.__schema__(:embeds)
          embeds = __MODULE__.__schema__(:embeds)

          struct
          |> cast(params, non_embeds)
          |> cast_embeds_if_any(embeds)
          |> validate_required(non_embeds)
        end

        defp cast_embeds_if_any(changeset, []), do: changeset

        defp cast_embeds_if_any(changeset, embeds) do
          Enum.reduce(embeds, changeset, fn embed, acc ->
            cast_embed(acc, embed)
          end)
        end
      end

      Module.put_attribute(__MODULE__, :output_schema_module, Output)
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
    compiled =
      EEx.compile_string(template_str,
        engine: Phoenix.LiveView.TagEngine,
        caller: __CALLER__,
        tag_handler: Phoenix.LiveView.HTMLEngine,
        source: __CALLER__.file
      )

    quote do
      Module.put_attribute(__MODULE__, :system_template_content, unquote(template_str))

      def render_system_template(assigns) do
        raw_assigns =
          for {k, v} <- assigns, into: %{} do
            {k, Phoenix.HTML.raw(v)}
          end

        var!(assigns) = raw_assigns

        unquote(compiled)
        |> Phoenix.HTML.html_escape()
        |> Phoenix.HTML.safe_to_string()
      end
    end
  end

  @doc """
  Defines the user template using HEEx syntax with ~H sigil.
  """
  defmacro user_template(do: {:sigil_H, _meta, [{:<<>>, _, [template_str]}, []]}) do
    compiled =
      EEx.compile_string(template_str,
        engine: Phoenix.LiveView.TagEngine,
        caller: __CALLER__,
        tag_handler: Phoenix.LiveView.HTMLEngine,
        source: __CALLER__.file
      )

    quote do
      def render_user_template(assigns) do
        raw_assigns =
          for {k, v} <- assigns, into: %{} do
            {k, Phoenix.HTML.raw(v)}
          end

        var!(assigns) = raw_assigns

        unquote(compiled)
        |> Phoenix.HTML.html_escape()
        |> Phoenix.HTML.safe_to_string()
      end
    end
  end

  @doc """
  Defines a field in the AI schema.
  """
  defmacro ai_field(name, type, opts \\ []) do
    quote do
      field = {unquote(name), unquote(type), unquote(opts)}

      case @input_section do
        :user -> Module.put_attribute(__MODULE__, :user_input_fields, field)
        :system -> Module.put_attribute(__MODULE__, :system_input_fields, field)
        :output -> Module.put_attribute(__MODULE__, :output_fields, field)
      end
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      def __schema__(:user_input_fields) do
        __MODULE__.UserInput.__schema__(:fields)
      end

      def __schema__(:system_input_fields) do
        __MODULE__.SystemInput.__schema__(:fields)
      end

      def __schema__(:output_fields) do
        __MODULE__.Output.__schema__(:fields)
      end

      def cast_input(params) do
        __MODULE__.UserInput.changeset(params)
      end

      def cast_system_input(params) do
        case __MODULE__.SystemInput.changeset(params) do
          %{valid?: true} = changeset -> {:ok, Ecto.Changeset.apply_changes(changeset)}
          changeset -> {:error, changeset}
        end
      end

      def cast_output(params) do
        case __MODULE__.Output.changeset(params) do
          %{valid?: true} = changeset -> Ecto.Changeset.apply_action(changeset, :validate)
          changeset -> {:error, changeset}
        end
      end

      def format_input(params) do
        case cast_input(params) do
          %{valid?: true} = changeset ->
            {:ok, render_template(Ecto.Changeset.apply_action(changeset, :validate))}

          changeset ->
            {:error, changeset}
        end
      end

      def render_template(assigns) do
        render_user_template(assigns)
      end

      @has_output_section Module.get_attribute(__MODULE__, :has_output_section)
      def __schema__(:output_schema) do
        if @has_output_section do
          __MODULE__
        end
      end

      def __schema__(:openai_options) do
        if @has_output_section do
          %{response_format: %{type: "json_object"}}
        else
          %{}
        end
      end

      def maybe_apply_output_schema(changeset, nil), do: changeset

      def maybe_apply_output_schema(changeset, schema_module) do
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
    end
  end
end
