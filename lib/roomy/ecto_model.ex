defmodule Roomy.EctoModel do
  @moduledoc """
  Provides simple default functions for setting up an Ecto Model

  ## Requirements
  - In order for `create/2` and `update/3` to work you need to define `create_changeset/2` and `update_changeset/2`

  ## Usage
  Just add a use statement in your Ecto Model
  ```
  use Roomy.EctoModel
  ```

  By default `Roomy.EctoModel` imports the following modules:
  - `Ecto.Query`
  - `Ecto.Changeset`

  ### Default preloads
  To specify default preloads just pass the option:
  ```
  use Roomy.EctoModel, preloads: [post: [author: :mentions]]
  ```
  This will specify a `@default_preloads` module attribute in your module which you can use in your functions as well.

  ### Overwrite functions
  All the provided functions are overridable as easily as:
  ```
  def create(attrs, preloads) do
    case super(attrs, preloads) do
      {:ok, data} -> data
      {:error, _reason} -> nil
    end
  end
  ```
  """

  defmacro __using__(opts) do
    default_preloads = Keyword.get(opts, :preloads, [])

    calling_module = __CALLER__.module
    Module.put_attribute(calling_module, :default_preloads, default_preloads)

    quote do
      use Ecto.Schema

      import Ecto.Changeset

      import Ecto.Query,
        only: [
          from: 1,
          from: 2,
          where: 2,
          order_by: 2,
          preload: 2,
          dynamic: 1,
          dynamic: 2,
          join: 5,
          subquery: 1,
          subquery: 2
        ]

      alias Roomy.Repo

      @type get_by :: map() | struct() | [{atom(), any()}]
      @type order_by :: {:asc, atom()} | {:desc, atom()}
      @type preloads :: [atom()] | [{atom(), preloads()}]

      @spec create(map() | struct(), preloads()) ::
              {:ok, __MODULE__.t()} | {:error, Ecto.Changeset.t()}
      def create(map_or_struct, preloads \\ @default_preloads)

      def create(attrs, preloads) when is_struct(attrs) do
        attrs
        |> Map.from_struct()
        |> __MODULE__.create(preloads)
      end

      def create(attrs, preloads) do
        __MODULE__
        |> struct()
        |> create_changeset(attrs)
        |> Repo.insert()
        |> case do
          {:ok, %{} = struct} when is_struct(struct, __MODULE__) ->
            {:ok, Repo.preload(struct, preloads)}

          {:error, reason} ->
            {:error, reason}
        end
      end

      @spec update(
              String.t() | pos_integer() | __MODULE__.t() | Ecto.Changeset.t(),
              map() | struct(),
              preloads()
            ) :: {:ok, __MODULE__.t()} | {:error, Ecto.Changeset.t()}
      def update(id_or_struct, attrs \\ %{}, preloads \\ @default_preloads)

      def update(string_id, attrs, preloads) when is_binary(string_id) do
        parse_execute(string_id, &__MODULE__.update(&1, attrs, preloads))
      end

      def update(id, attrs, preloads) when is_struct(attrs) do
        __MODULE__.update(id, Map.from_struct(attrs), preloads)
      end

      def update(id, attrs, preloads) when is_integer(id) do
        fetch_execute(id, &__MODULE__.update(&1, attrs, preloads))
      end

      def update(%{} = struct, attrs, preloads) when is_struct(struct, __MODULE__) do
        struct
        |> update_changeset(attrs)
        |> __MODULE__.update(attrs, preloads)
      end

      def update(%{} = changeset, attrs, preloads) when is_struct(changeset, Ecto.Changeset) do
        changeset
        |> Repo.update()
        |> case do
          {:ok, %{} = data} when is_struct(data, __MODULE__) ->
            {:ok, Repo.preload(data, preloads)}

          {:error, reason} ->
            {:error, reason}
        end
      end

      @spec get(String.t() | pos_integer(), preloads()) ::
              {:ok, __MODULE__.t()} | {:error, :not_found}
      def get(id, preloads \\ @default_preloads)

      def get(string_id, preloads) when is_binary(string_id) do
        parse_execute(string_id, &__MODULE__.get(&1, preloads))
      end

      def get(id, preloads) when is_integer(id) do
        __MODULE__.get_by([id: id], preloads)
      end

      @spec get!(String.t() | pos_integer(), preloads()) :: __MODULE__.t()
      def get!(id, preloads \\ @default_preloads)

      def get!(string_id, preloads) when is_binary(string_id) do
        parse_execute(string_id, &__MODULE__.get!(&1, preloads))
      end

      def get!(id, preloads) when is_integer(id) do
        case __MODULE__.get_by([id: id], preloads) do
          {:ok, user} -> user
          {:error, _} -> throw("Database object with id #{id} cannot be found!")
        end
      end

      @spec get_by(get_by(), preloads()) :: {:ok, __MODULE__.t()} | {:error, :not_found}
      def get_by(filters, preloads \\ @default_preloads) do
        query = from(rows in __MODULE__)
        {new_query, dynamic_where} = dynamic_where_clause(query, filters)

        new_query
        |> where(^dynamic_where)
        |> preload(^preloads)
        |> Repo.one()
        |> case do
          %{} = struct when is_struct(struct, __MODULE__) -> {:ok, struct}
          nil -> {:error, :not_found}
        end
      end

      @spec all() :: [__MODULE__.t()]
      def all() do
        Repo.all(__MODULE__)
      end

      @spec all_by(
              filter: get_by(),
              order_by: order_by(),
              preloads: preloads()
            ) :: [__MODULE__.t()]
      def all_by(options) do
        filters =
          options
          |> Keyword.get(:filter, [])
          |> normalize_filter_options()

        order_by = Keyword.get(options, :order_by, [])
        preloads = Keyword.get(options, :preloads, @default_preloads)

        query = from(rows in __MODULE__)
        {new_query, dynamic_where} = dynamic_where_clause(query, filters)

        new_query
        |> where(^dynamic_where)
        |> order_by(^order_by)
        |> preload(^preloads)
        |> Repo.all()
      end

      @spec delete(String.t() | pos_integer() | __MODULE__.t() | Ecto.Changeset.t()) ::
              {:ok, __MODULE__.t()} | {:error, Ecto.Changeset.t()}
      def delete(id_or_struct)

      def delete(string_id) when is_binary(string_id) do
        parse_execute(string_id, &__MODULE__.delete/1)
      end

      def delete(id) when is_integer(id) do
        fetch_execute(id, &__MODULE__.delete/1)
      end

      def delete(%{} = struct) when is_struct(struct, __MODULE__) do
        Repo.delete(struct)
      end

      def delete(%{} = changeset) when is_struct(changeset, Ecto.Changeset) do
        Repo.delete(changeset)
      end

      @spec delete_by(get_by()) :: {:ok, __MODULE__.t()} | {:error, Ecto.Changeset.t()}
      def delete_by(filter) do
        with {:ok, struct} when is_struct(struct, __MODULE__) <- get_by(filter) do
          delete(struct)
        end
      end

      defp parse_execute(string_id, fun) when is_binary(string_id) and is_function(fun) do
        with {_, {id, ""}} <- {:parse_int, Integer.parse(string_id)},
             {:ok, data} <- fun.(id) do
          {:ok, data}
        else
          {:parse_int, _} ->
            {:error, :not_found}

          error ->
            error
        end
      end

      defp fetch_execute(id, fun) when is_integer(id) and is_function(fun) do
        with {:ok, %{} = struct} when is_struct(struct, __MODULE__) <- __MODULE__.get(id, []) do
          fun.(struct)
        end
      end

      defp dynamic_where_clause(query, search_terms) do
        Enum.reduce(
          search_terms,
          {query, dynamic(true)},
          &dynamic_where_clause(&1, &2, nil)
        )
      end

      defp dynamic_where_clause({column, nil}, {query, where_clauses}, nil) do
        {
          query,
          dynamic([table], is_nil(field(table, ^column)) and ^where_clauses)
        }
      end

      defp dynamic_where_clause({column, [_ | _] = values}, {query, where_clauses}, nil) do
        if association_field?(column) do
          new_query = join(query, :inner, [table], assoc in assoc(table, ^column), as: ^column)

          Enum.reduce(values, {new_query, where_clauses}, &dynamic_where_clause(&1, &2, column))
        else
          {
            query,
            dynamic([table], field(table, ^column) in ^values and ^where_clauses)
          }
        end
      end

      defp dynamic_where_clause({column, value}, {query, where_clauses}, nil) do
        {
          query,
          dynamic([table], field(table, ^column) == ^value and ^where_clauses)
        }
      end

      defp dynamic_where_clause({column, nil}, {query, where_clauses}, association) do
        {
          query,
          dynamic(
            [{^association, table}],
            is_nil(field(table, ^column)) and ^where_clauses
          )
        }
      end

      defp dynamic_where_clause({column, [_ | _] = values}, {query, where_clauses}, association) do
        {
          query,
          dynamic(
            [{^association, table}],
            field(table, ^column) in ^values and ^where_clauses
          )
        }
      end

      defp dynamic_where_clause({column, value}, {query, where_clauses}, association) do
        {
          query,
          dynamic(
            [{^association, table}],
            field(table, ^column) == ^value and ^where_clauses
          )
        }
      end

      defp association_field?(field) do
        __MODULE__
        |> struct()
        |> Map.from_struct()
        |> Map.get(field)
        |> case do
          %Ecto.Association.NotLoaded{__field__: ^field} -> true
          _ -> false
        end
      end

      defp normalize_filter_options(filter) do
        case filter do
          struct when is_struct(struct) -> struct |> Map.from_struct() |> Map.to_list()
          map when is_map(map) -> Map.to_list(map)
          list when is_list(list) -> list
        end
      end

      defoverridable create: 2,
                     update: 3,
                     get: 1,
                     get: 2,
                     get!: 1,
                     get!: 2,
                     get_by: 2,
                     all: 0,
                     all_by: 1,
                     delete: 1,
                     delete_by: 1
    end
  end
end
