defmodule AIex.AifunctionSchemaTest do
  use ExUnit.Case

  describe "basic schema validation" do
    defmodule BasicSchema do
      use AIex.Aifunction

      user_input do
        field :name, :string
        field :age, :integer
        field :tags, {:array, :string}
      end

      user_template do
        ~H"""
        Name: <%= @name %>
        Age: <%= @age %>
        Tags: <%= Enum.join(@tags, ", ") %>
        """
      end

      output do
        field :message, :string
        field :score, :float
      end
    end

    test "validates user input with valid data" do
      params = %{
        "name" => "John Doe",
        "age" => 30,
        "tags" => ["user", "active"]
      }

      assert {:ok, input} = BasicSchema.cast_input(params)
      assert input.name == "John Doe"
      assert input.age == 30
      assert input.tags == ["user", "active"]
    end

    test "validates user input with invalid data" do
      params = %{
        # should be string
        "name" => 123,
        # should be integer
        "age" => "30",
        # should be array
        "tags" => "not_an_array"
      }

      assert {:error, changeset} = BasicSchema.cast_input(params)
      errors = errors_on(changeset)
      assert errors[:name]
      assert errors[:age]
      assert errors[:tags]
    end

    test "validates output with valid data" do
      params = %{
        "message" => "Success",
        "score" => 0.95
      }

      assert {:ok, output} = BasicSchema.cast_output(params)
      assert output.message == "Success"
      assert output.score == 0.95
    end

    test "validates output with invalid data" do
      params = %{
        # should be string
        "message" => 123,
        # should be float
        "score" => "not_a_float"
      }

      assert {:error, changeset} = BasicSchema.cast_output(params)
      errors = errors_on(changeset)
      assert errors[:message]
      assert errors[:score]
    end
  end

  describe "embedded schema validation" do
    defmodule EmbeddedSchema do
      use AIex.Aifunction

      defmodule Location do
        use Ecto.Schema
        import Ecto.Changeset

        @primary_key false
        embedded_schema do
          field :city, :string
          field :country, :string
          field :coordinates, {:array, :float}
        end

        def changeset(struct, params) do
          struct
          |> cast(params, [:city, :country, :coordinates])
          |> validate_required([:city, :country])
          |> validate_length(:coordinates, is: 2, message: "must be [latitude, longitude]")
        end
      end

      defmodule Metadata do
        use Ecto.Schema
        import Ecto.Changeset

        @primary_key false
        embedded_schema do
          field :key, :string
          field :value, :string
          field :priority, :integer
        end

        def changeset(struct, params) do
          struct
          |> cast(params, [:key, :value, :priority])
          |> validate_required([:key, :value])
          |> validate_number(:priority, greater_than_or_equal_to: 0, less_than_or_equal_to: 10)
        end
      end

      user_input do
        field :user_id, :string
        embeds_one(:location, Location)
        embeds_many(:metadata, Metadata)
      end

      user_template do
        ~H"""
        User ID: <%= @user_id %>
        Location: <%= @location.city %>, <%= @location.country %>
        Coordinates: <%= Enum.join(@location.coordinates, ", ") %>
        Metadata:
        <%= for meta <- @metadata do %>
        - <%= meta.key %>: <%= meta.value %> (priority: <%= meta.priority %>)
        <% end %>
        """
      end

      output do
        field :success, :boolean
        embeds_one(:matched_location, Location)
        embeds_many(:matched_metadata, Metadata)
      end
    end

    test "validates user input with valid embedded fields" do
      params = %{
        "user_id" => "user123",
        "location" => %{
          "city" => "San Francisco",
          "country" => "USA",
          "coordinates" => [37.7749, -122.4194]
        },
        "metadata" => [
          %{"key" => "type", "value" => "residential", "priority" => 5},
          %{"key" => "status", "value" => "active", "priority" => 3}
        ]
      }

      assert input = EmbeddedSchema.cast_input(params) |> Ecto.Changeset.apply_action!(:validate)
      assert input.user_id == "user123"
      assert input.location.city == "San Francisco"
      assert input.location.coordinates == [37.7749, -122.4194]
      assert length(input.metadata) == 2
      assert Enum.at(input.metadata, 0).key == "type"
    end

    test "validates user input with invalid embedded fields" do
      params = %{
        "user_id" => "user123",
        "location" => %{
          "city" => "San Francisco",
          # missing country
          # invalid coordinates length
          "coordinates" => [37.7749]
        },
        "metadata" => [
          # invalid priority
          %{"key" => "type", "value" => "residential", "priority" => 15},
          # missing required value
          %{"key" => "status"}
        ]
      }

      assert {:error, changeset} = EmbeddedSchema.cast_input(params)
      errors = errors_on(changeset)

      assert %{location: %{country: ["can't be blank"]}} = errors
      assert %{location: %{coordinates: ["must be [latitude, longitude]"]}} = errors

      assert %{
               metadata: [
                 %{priority: ["must be less than or equal to 10"]},
                 %{value: ["can't be blank"]}
               ]
             } = errors
    end

    test "validates output with valid embedded fields" do
      params = %{
        "success" => true,
        "matched_location" => %{
          "city" => "San Francisco",
          "country" => "USA",
          "coordinates" => [37.7749, -122.4194]
        },
        "matched_metadata" => [
          %{"key" => "match_type", "value" => "exact", "priority" => 8}
        ]
      }

      assert {:ok, output} = EmbeddedSchema.cast_output(params)
      assert output.success == true
      assert output.matched_location.city == "San Francisco"
      assert length(output.matched_metadata) == 1
      assert Enum.at(output.matched_metadata, 0).priority == 8
    end

    test "validates output with invalid embedded fields" do
      params = %{
        "success" => "not_a_boolean",
        "matched_location" => %{
          # invalid coordinates length
          "coordinates" => [1.0, 2.0, 3.0]
        },
        "matched_metadata" => [
          # missing required value
          %{"key" => "match_type"}
        ]
      }

      assert {:error, changeset} = EmbeddedSchema.cast_output(params)
      errors = errors_on(changeset)

      assert errors[:success]
      assert %{matched_location: %{coordinates: ["must be [latitude, longitude]"]}} = errors
      assert %{matched_metadata: [%{value: ["can't be blank"]}]} = errors
    end
  end

  describe "embedded coordinates schema validation" do
    defmodule CoordinatesSchema do
      use AIex.Aifunction

      defmodule Coordinate do
        use Ecto.Schema
        import Ecto.Changeset

        @primary_key false
        embedded_schema do
          field :lat, :float
          field :lon, :float
        end

        def changeset(struct, params) do
          struct
          |> cast(params, [:lat, :lon])
          |> validate_required([:lat, :lon])
          |> validate_number(:lat, greater_than_or_equal_to: -90, less_than_or_equal_to: 90)
          |> validate_number(:lon, greater_than_or_equal_to: -180, less_than_or_equal_to: 180)
        end
      end

      user_input do
        embeds_many(:coordinates, Coordinate)
      end

      user_template do
        ~H"""
        Name: <%= @name %>
        Coordinates:
        <%= for coord <- @coordinates do %>
        - Lat: <%= coord.lat %>, Lon: <%= coord.lon %>
        <% end %>
        """
      end

      output do
        field :success, :boolean
      end
    end

    test "validates user input with valid coordinates list" do
      coords = [
        %CoordinatesSchema.Coordinate{lat: 37.7749, lon: -122.4194},
        %CoordinatesSchema.Coordinate{lat: 34.0522, lon: -118.2437}
      ]

      params = %{
        :name => "Route 1",
        :coordinates => coords
      }

      assert input =
               CoordinatesSchema.cast_input(params) |> Ecto.Changeset.apply_action!(:validate)

      assert length(input.coordinates) == 2
      assert Enum.at(input.coordinates, 0).lat == 37.7749
      assert Enum.at(input.coordinates, 0).lon == -122.4194
    end

    @tag :this
    test "validates user input with invalid coordinates" do
      coords = [
        # invalid latitude
        %CoordinatesSchema.Coordinate{lat: 91.0, lon: -122.4194},
        # invalid longitude (nil)
        %CoordinatesSchema.Coordinate{lat: 34.0522, lon: nil}
      ]

      params = %{
        "coordinates" => coords
      }

      assert {:error, changeset} = CoordinatesSchema.cast_input(params)
      errors = errors_on(changeset)

      assert %{
               coordinates: [
                 %{lat: ["must be less than or equal to 90"]},
                 %{lon: ["can't be blank"]}
               ]
             } = errors
    end
  end

  describe "system input schema validation" do
    defmodule SystemInputSchema do
      use AIex.Aifunction

      system_input do
        field :api_key, :string
        field :model_params, :map
        field :temperature, :float
      end

      system_template do
        ~H"""
        API Key: <%= @api_key %>
        Temperature: <%= @temperature %>
        Model Params: <%= inspect(@model_params) %>
        """
      end

      user_input do
        field :query, :string
      end

      user_template do
        ~H"""
        <%= @query %>
        """
      end

      output do
        field :response, :string
      end
    end

    test "validates system input with valid data" do
      params = %{
        "api_key" => "sk-123456",
        "model_params" => %{"max_tokens" => 100},
        "temperature" => 0.7
      }

      assert {:ok, input} = SystemInputSchema.cast_system_input(params)
      assert input.api_key == "sk-123456"
      assert input.model_params == %{"max_tokens" => 100}
      assert input.temperature == 0.7
    end

    test "validates system input with invalid data" do
      params = %{
        # should be string
        "api_key" => 123,
        # should be map
        "model_params" => "not_a_map",
        # should be float
        "temperature" => "not_a_float"
      }

      assert {:error, changeset} = SystemInputSchema.cast_system_input(params)
      errors = errors_on(changeset)
      assert errors[:api_key] == ["is invalid"]
      assert errors[:model_params] == ["is invalid"]
      assert errors[:temperature] == ["is invalid"]
    end

    test "raises error when system_input is defined without system_template" do
      assert_raise RuntimeError,
                   ~r/system_template is required when system_input is defined/,
                   fn ->
                     defmodule InvalidSchema do
                       use AIex.Aifunction

                       system_input do
                         field :api_key, :string
                       end

                       user_input do
                         field :query, :string
                       end

                       user_template do
                         ~H"""
                         <%= @query %>
                         """
                       end
                     end
                   end
    end
  end

  # Helper function for error testing
  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
