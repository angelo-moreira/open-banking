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

  @typedoc """
  This implementation models the Transaction struct, this should be a transaction returned
  by a banking API.

    * `description` - string representing the transaction
    * `merchant` - company that receives the transaction, for example Github
    * `confidence` - `1` for 100%, `0` for 0%. We might not always be able to assert with
                      100% of confidence which merchant the transaction matches to.

  """
  @type t :: %__MODULE__{
          description: description,
          confidence: confidence,
          merchant: merchant
        }

  @typedoc """
  Confidence level options, used for filtering, adding to the database, this is a crucial
  concept that we want our users to understand, important enough to deserver it's own type

    * `confidence_more` - `1` for 100%, `0` for 0%. Filters or adds transactions that are
        equal or above this level of confidence

    * `confidence_less` - `1` for 100%, `0` for 0%. Filters or adds transactions that are
        equal or below this level of confidence
  """
  @type confidence_opts :: %{
          confidence_more: float(),
          confidence_less: float()
        }

  schema "transaction" do
    field(:description, :string)
    field(:confidence, :float)
    field(:merchant, :string)
    timestamps()
  end

  @attrs [:description, :confidence, :merchant]

  defp changeset(struct, params) do
    struct
    |> cast(params, @attrs)
    |> validate_required(@attrs)
  end

  @doc """
  ### Import a file path for a CSV file

  The CSV File should have a return as a separator and use \ as an escape character

  #### Options:

    * `confidence_more` - accepts a float that represents 1 as 100% and 0 as 0% and then filters the
        results based on the confidence level that is bigger than the input
    * `confidence_less` - accepts a float that represents 1 as 100% and 0 as 0% and then filters the
        results based on the confidence level that is less than the input


  ## Example

      iex> OpenBanking.Transaction.import!("test/transactions.csv", %{})

  """
  @spec import!(Path.t(), confidence_opts) :: list(t) | no_return
  def import!(file, opts = %{}) when is_bitstring(file) do
    match_to_merchant = fn [description] ->
      match!(description)
    end

    file
    |> File.stream!()
    |> TransactionParser.parse_stream()
    |> Stream.map(match_to_merchant)
    |> Enum.to_list()
    |> do_import_filter_results(opts)
  end

  defp do_import_filter_results(transactions, %{confidence_more: more_than} = opts) do
    opts = Map.delete(opts, :confidence_more)

    transactions
    |> Enum.filter(&(&1.confidence >= more_than))
    |> do_import_filter_results(opts)
  end

  defp do_import_filter_results(transactions, %{confidence_less: less_than} = opts) do
    opts = Map.delete(opts, :confidence_less)

    transactions
    |> Enum.filter(&(&1.confidence <= less_than))
    |> do_import_filter_results(opts)
  end

  defp do_import_filter_results(transactions, _), do: transactions

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
  ### Gets transactions with options

  This function sole responsibility is to give access to all the data in the database so helpdesk
  staff can see the data that needs to be "fixed" and spot issues where the algorithm is not doing
  a good enough job.

  #### Options:

    * `merchant` - filters the results by merchant name (at the moment this is a naive implementation,
       but we should really use something like Myers Difference here)
    * `limit` - limits the results returned, just like SQL
    * `confidence_more` - accepts a float that represents 1 as 100% and 0 as 0% and then filters the
       results based on the confidence level that is bigger than the input
    * `confidence_less` - accepts a float that represents 1 as 100% and 0 as 0% and then filters the
       results based on the confidence level that is less than the input

  ## Examples

      iex> OpenBanking.Transaction.get_all(%{confidence_more: 0.85, merchant: "Netflix"})

      iex> OpenBanking.Transaction.get_all([confidence_less: 0.10, limit: 5])

      iex> OpenBanking.Transaction.get_all(%{merchant: "Unknown"})

  """
  @spec get_all(Keyword.t() | map()) :: list(t)
  def get_all(opts) when is_map(opts) do
    # let's put a limit otherwise people can be a bit silly
    # 1000 is already very silly imo :)

    Transaction
    |> limit(1000)
    |> do_get_all(opts)
  end

  def get_all(opts) do
    if Keyword.keyword?(opts) do
      opts
      |> Map.new()
      |> get_all()
    else
      get_all(%{})
    end
  end

  defp do_get_all(query, %{merchant: merchant} = opts) do
    opts = Map.delete(opts, :merchant)

    query
    |> where([t], t.merchant == ^merchant)
    |> do_get_all(opts)
  end

  defp do_get_all(query, %{confidence_more: more_than} = opts) do
    opts = Map.delete(opts, :confidence_more)

    query
    |> where([t], t.confidence >= ^more_than)
    |> do_get_all(opts)
  end

  defp do_get_all(query, %{confidence_less: less_than} = opts) do
    opts = Map.delete(opts, :confidence_less)

    query
    |> where([t], t.confidence <= ^less_than)
    |> do_get_all(opts)
  end

  defp do_get_all(query, %{limit: limit} = opts) do
    opts = Map.delete(opts, :limit)

    query
    |> limit(^limit)
    |> do_get_all(opts)
  end

  defp do_get_all(query, _), do: Repo.all(query)

  @doc """
  ### Inserts a single transactions to the DB

  This function expects a map to be inserted to the Database.

  It takes advantage of `insert_all` behind the scenes by wrapping the transaction
  in a list, I think it's good for code reuse and it makes software simple with
  less places for bugs.

  You should get a `{:ok, struct}` if everything goes right.

  ### Errors

  If there is any error it should return `{:error, changeset}`.

  ## Examples

      iex> OpenBanking.Transaction.insert_one(%{merchant: "Denmark", confidence: 1.0, description: "The Great king of Denmark"})

  """
  @spec insert_one(map(), confidence_opts | map()) :: {:ok, t} | {:error, Changeset.t()}
  def insert_one(%{} = transaction, %{} = opts) do
    res = insert_all([transaction], opts)

    case res do
      {:ok, [transaction]} -> {:ok, transaction}
      {:error, [changeset]} -> {:error, changeset}
    end
  end

  def insert_one(_), do: {:error, :not_a_valid_map}

  @doc """
  ### Inserts a list of transactions in the DB

  This function expects a list of maps to insert to the Database, it was originally
  created to work alongside `import`, but it should be general enough to be used with
  other cases found later.

  You should get a `{:ok, list_of_transactions_structs}` if everything goes right.

  #### Options:

  * `confidence_more` - accepts a float that represents 1 as 100% and 0 as 0% only transactions
      that are equal or above the `confidence_more` threshold will be saved
  * `confidence_less` - accepts a float that represents 1 as 100% and 0 as 0% only transactions
      that are less or equal the `confidence_less` threshold will be saved

  ### Errors

  If there is any error in any of the changesets it should return `{:error, changesets}`.

  Only the transactions that errored should be returned to make it easier to fix those.

  This should conform to community standards but the code had to do some changesets manipulation
  in order to provide a cleaner API, I think it's an acceptable trade-off

  ## Examples

      iex> OpenBanking.Transaction.insert_all([%{merchant: "Denmark", confidence: 1.0, description: "The Great king of Denmark"}], %{})

      iex> OpenBanking.Transaction.insert_all([%{merchant: "Denmark", confidence: 1.0, description: "The Great king of Denmark"}], %{confidence_more: 0.3})

  """
  @spec insert_all([map()], confidence_opts | map()) :: {:ok, [t]} | {:error, [Changeset.t()]}
  def insert_all([%{} | _] = maps, %{confidence_more: equal_or_above} = opts) do
    opts = Map.delete(opts, :confidence_more)

    maps
    |> Enum.filter(fn transaction -> transaction.confidence >= equal_or_above end)
    |> insert_all(opts)
  end

  def insert_all([%{} | _] = maps, %{confidence_less: equal_or_below} = opts) do
    opts = Map.delete(opts, :confidence_less)

    maps
    |> Enum.filter(fn transaction -> transaction.confidence <= equal_or_below end)
    |> insert_all(opts)
  end

  def insert_all([%{} | _] = maps, %{}) do
    changesets_verification =
      maps
      |> Enum.map(&changeset(%Transaction{}, &1))
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

  @doc """
  ### Approves transactions by id

  So the algorithm can improve we would need some feedback about what's wrong and right
  with the data, our match algorithms works with a "confidence level" based on trigrams
  so the more help we get, the better will be able to assert results.

  In a prod product we would want to expose an API and show a user interface to our helpdesk
  staff that would interact with our API.

  Once a transaction has been approved the level of confidence will be 100%

  ## Examples

      iex> OpenBanking.Transaction.approve(%{transaction_id: 1, merchant: "Netflix"})

      iex> OpenBanking.Transaction.approve([transaction_id: 1, merchant: "Netflix"])

  """
  @spec approve(Keyword.t() | map()) :: {:ok, t} | {:error, String}
  def approve(%{transaction_id: id, merchant: merchant})
      when is_integer(id) and is_bitstring(merchant) do
    transaction = Repo.get_by(Transaction, id: id)
    merchant = Merchant.get_by_name(merchant)

    cond do
      is_nil(transaction) -> {:error, :transaction_id_not_found}
      is_nil(merchant) -> {:error, :merchant_not_found}
      true -> do_approve(transaction, %{merchant: merchant.name})
    end
  end

  def approve(%{transaction_id: id}) when is_integer(id) do
    transaction = Repo.get_by(Transaction, id: id)

    if is_nil(transaction) do
      {:error, :transaction_id_not_found}
    else
      do_approve(transaction, %{})
    end
  end

  def approve(keywords) do
    if Keyword.keyword?(keywords) do
      keywords
      |> Map.new()
      |> approve()
    else
      {:error, {:wrong_input, "please run `h OpenBaking.approve to see the documentation`"}}
    end
  end

  defp do_approve(struct, changes) do
    changes_with_confidence = Map.put(changes, :confidence, 1.0)

    struct
    |> changeset(changes_with_confidence)
    |> Repo.update()
  end
end
