defmodule AIex.AifunctionStructuredTest do
  use ExUnit.Case

  defmodule ComplexAIFunction do
    use AIex.Aifunction

    user_template do
      ~H"""
      """
    end

    system_template do
      ~H"""
      aaa
      """
    end

    output do
    end
  end

  describe "schema definition and validation" do
    test "validates correct user input" do
      valid_params = %{
        name: "Test User",
        numbers: [1, 2, 3],
        items: [
          %{id: 1, description: "First item"},
          %{id: 2, description: "Second item"}
        ]
      }

      changeset =
        ComplexAIFunction.UserInput.changeset(%ComplexAIFunction.UserInput{}, valid_params)

      assert changeset.valid?
    end

    test "validates output with complex nested structures" do
      valid_output = %{
        result_text: "Analysis complete",
        confidence_score: 0.95,
        tags: ["important", "verified"],
        classifications: [
          %{category: "positive", probability: 0.8},
          %{category: "neutral", probability: 0.2}
        ],
        summary: %{
          title: "Test Summary",
          key_points: ["Point 1", "Point 2"]
        }
      }

      changeset = ComplexAIFunction.Output.changeset(%ComplexAIFunction.Output{}, valid_output)
      assert changeset.valid?
    end

    test "invalidates missing required fields in user input" do
      invalid_params = %{
        numbers: [1, 2, 3]
        # missing required name field
      }

      changeset =
        ComplexAIFunction.UserInput.changeset(%ComplexAIFunction.UserInput{}, invalid_params)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
    end

    test "validates array type constraints" do
      invalid_params = %{
        name: "Test User",
        # should be integers
        numbers: ["not", "numbers"],
        items: []
      }

      changeset =
        ComplexAIFunction.UserInput.changeset(%ComplexAIFunction.UserInput{}, invalid_params)

      refute changeset.valid?
      assert errors_on(changeset).numbers
    end

    test "validates nested embeds in output" do
      invalid_output = %{
        result_text: "Test",
        confidence_score: 0.9,
        tags: ["test"],
        classifications: [
          # should be float
          %{category: "positive", probability: "not a float"}
        ],
        summary: %{
          title: "Test",
          # should be array of strings
          key_points: "not an array"
        }
      }

      changeset = ComplexAIFunction.Output.changeset(%ComplexAIFunction.Output{}, invalid_output)
      refute changeset.valid?
    end
  end
end
