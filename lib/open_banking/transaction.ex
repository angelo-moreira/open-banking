defmodule OpenBanking.Transaction do
  @moduledoc """
  A transaction represents a string to be parsed and matches against a Merchant

  This could obviously be expanded to have all kind of things, like price or categories
  but that would be against the spec provided for the test
  """

  use Ecto.Schema
  import Ecto.Query

  alias __MODULE__
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

  def get_all, do: Repo.all(Merchant)

  @doc """
  ### Import a file path for a CSV file

  The CSV File should have a return as a separator and use \ as an escape character

  ## Example

    %OpenBanking.Transaction.import!("test/transactions.csv")

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

  @spec match!(String.t()) :: list(t) | no_return
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
      %{description: text_to_find, merchant: "Unknown", confidence: 0}
    else
      match
    end
  end

  def match!(_),
    do: raise("To convert a description we need a text input")
end
