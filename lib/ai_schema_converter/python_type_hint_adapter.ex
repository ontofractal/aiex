defmodule AIex.AISchemaConverter.PythonTypeHintAdapter do
  @moduledoc """
  Adapter for converting Ecto schemas to Python type hint annotations.
  """

  def convert(schema, format \\ :default) do
    fields = schema.__schema__(:fields)
    schema_name = schema |> Module.split() |> List.last()

    field_annotations =
      Enum.map(fields, fn field ->
        type = schema.__schema__(:type, field)
        python_type = type_to_python(type, format)
        "    #{field}: #{python_type}"
      end)

    """
    class #{schema_name}:
    #{Enum.join(field_annotations, "\n")}
    """
  end

  defp type_to_python(:string, _), do: "str"
  defp type_to_python(:integer, _), do: "int"
  defp type_to_python(:float, _), do: "float"
  defp type_to_python(:boolean, _), do: "bool"
  defp type_to_python({:array, type}, :gemini), do: "list[#{type_to_python(type, :gemini)}]"
  defp type_to_python({:array, type}, _), do: "List[#{type_to_python(type, :default)}]"
  defp type_to_python(_, :gemini), do: "str"
  defp type_to_python(_, _), do: "Any"
end
