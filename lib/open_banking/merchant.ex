defmodule OpenBanking.Merchant do
  @moduledoc """
  Merchants data structure and functionality

  Merchantes are companies such as Google, Amazon, Netflix
  """

  use Ecto.Schema

  alias __MODULE__
  alias OpenBanking.Repo

  schema "merchant" do
    field(:name, :string)
    timestamps()
  end

  def get_all, do: Repo.all(Merchant)
end
