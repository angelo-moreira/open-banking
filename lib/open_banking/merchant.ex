defmodule OpenBanking.Merchant do
  @moduledoc """
  Merchants data structure and functionality

  Merchantes are companies such as Google, Amazon, Netflix
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__
  alias OpenBanking.Repo

  schema "merchant" do
    field(:name, :string)
    timestamps()
  end

  @typedoc """
  This implementation models the Merchant struct.

    * `name` - string representing the name of the merchant

  """
  @type t :: %__MODULE__{
          name: String.t()
        }

  defp changeset(struct, params) do
    struct
    |> cast(params, [:name])
    |> validate_required([:name])
  end

  @doc """
  Fetches a Merchant from the database, at the moment the string needs to match
  with name perfectly

  ## Example

      iex> OpenBanking.Merchant.get_by_name("Netflix")

  """
  @spec get_by_name(String.t()) :: t() | nil
  def get_by_name(name) do
    Repo.get_by(Merchant, name: name)
  end

  @spec insert_one(map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def insert_one(merchant) do
    %Merchant{}
    |> changeset(merchant)
    |> Repo.insert()
  end
end
