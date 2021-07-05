defmodule OpenBanking.Transaction do
  @moduledoc """
  A transaction represents a string to be parsed and matches against a Merchant

  This could obviously be expanded to have all kind of things, like price or categories
  but that would be against the spec provided for the test
  """

  use Ecto.Schema
  import Ecto.{Query, Changeset}

  alias __MODULE__
  alias Ecto.Multi
  alias OpenBanking.Merchant
  alias OpenBanking.Repo
  NimbleCSV.define(TransactionParser, separator: "\n", escape: "\"")

  @type description :: String.t()
  @type confidence :: Float.t()
  @type merchant :: String.t()

  @type t :: %__MODULE__{
          description: description,
          confidence: confidence,
          merchant: merchant
        }

  schema "transaction" do
    field(:description, :string)
    field(:confidence, :float)
    field(:merchant, :string)
    timestamps()
  end

  @attrs [:description, :confidence, :merchant]

  defp changeset(params) do
    %Transaction{}
    |> cast(params, @attrs)
    |> validate_required(@attrs)
  end

  def get_all, do: Repo.all(Merchant)

  @doc """
  ### Import a file path for a CSV file

  The CSV File should have a return as a separator and use \ as an escape character

  ## Example

      iex> OpenBanking.Transaction.import!("test/transactions.csv")

  """
  @spec import!(Path.t()) :: list(t) | no_return
  def import!(file) when is_bitstring(file) do
    match_to_merchant = fn [description] ->
      match!(description)
    end

    file
    |> File.stream!()
    |> TransactionParser.parse_stream()
    |> Stream.map(match_to_merchant)
    |> Enum.to_list()
  end

  @doc """
  ### Matches a description to a merchant

  The decription should be a string, `match` will try to match it against a merchant
  in the database and return a level of confidence, the matching algorithm uses trigrams
  to try to find a good match.

  If we send anything other than a valid string an exception will be raised, the ! in the
  end of the function indicates that as it is a standard around the Elixir community and
  its many libraries.

  ## Examples

      iex> OpenBanking.Transaction.match!("Netflix")
      %{merchant: "Netflix", confidence: 1.0, description: "Netflix"}

  """
  @spec match!(String.t()) :: map() | no_return
  def match!(text_to_find) when is_bitstring(text_to_find) do
    match =
      Repo.one(
        from(
          t in Transaction,
          select: %{
            description: ^text_to_find,
            merchant: t.merchant,
            confidence: fragment("SIMILARITY(?, ?) AS rank", t.description, ^text_to_find)
          },
          where: fragment("SIMILARITY(?, ?)", t.description, ^text_to_find) > 0.1,
          order_by: fragment("rank DESC"),
          limit: 1
        )
      )

    if is_nil(match) do
      %{description: text_to_find, merchant: "Unknown", confidence: 0.0}
    else
      match
    end
  end

  def match!(_),
    do: raise("To convert a description we need a text input")

  @doc """
  ### Inserts a list of transactions in the DB

  This function expects a list of maps to insert to the Database, it was originally
  created to work alongside `import`, but it should be general enough to be used with
  other cases found later.

  You should get a `{:ok, list_of_transactions_structs}` if everything goes right.

  ### Errors

  If there is any error in any of the changesets it should return `{:error, changesets}`.

  Only the transactions that errored should be returned to make it easier to fix those.

  This should conform to community standards but the code had to do some changesets manipulation
  in order to provide a cleaner API, I think it's an acceptable trade-off

  ## Examples

      iex> OpenBanking.Transaction.insert_all([%{merchant: "Denmark", confidence: 1.0, description: "The Great king of Denmark"}])

  """
  @spec insert_all([map()]) :: {:ok, [t]} | {:error, [Changeset.t()]}
  def insert_all([%{} | _] = maps) do
    changesets_verification =
      maps
      |> Enum.map(&changeset/1)
      |> verify_changesets_ok

    case changesets_verification do
      {:ok, changesets} ->
        changesets
        |> do_add_multi(Multi.new())
        |> Repo.transaction()
        |> transation_to_list

      _ ->
        changesets_verification
    end
  end

  defp verify_changesets_ok(changesets) do
    failed_changesets = Enum.reject(changesets, & &1.valid?)

    if failed_changesets == [] do
      {:ok, changesets}
    else
      {:error, failed_changesets}
    end
  end

  # Gets a multi response and transforms it into a more standard response
  # {:ok, data} or {:error, data}
  defp transation_to_list({:ok, structs}) do
    tags = structs |> Enum.map(&elem(&1, 1))
    {:ok, tags}
  end

  defp transation_to_list(transaction),
    do: transaction

  # I don't usually document private functions but this is a recursive function :)
  # we want to create a transition of inserts here, this way if we have an error
  # in one of these changesets we can just roll back everything, fix the mistake
  # and try again without having to worry what records were inserted before
  # the failure, I think we should aim to have as consistent data as possible
  defp do_add_multi(changesets, multi) do
    if Enum.empty?(changesets) do
      multi
    else
      [hd | tl] = changesets

      new_multi = Multi.insert(multi, hd.changes.description, hd)
      do_add_multi(tl, new_multi)
    end
  end
end
