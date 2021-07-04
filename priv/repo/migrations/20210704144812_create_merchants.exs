defmodule OpenBanking.Repo.Migrations.CreateMerchants do
  @moduledoc false
  use Ecto.Migration

  def up do
    create table(:merchant) do
      add(:name, :string, null: false)
      timestamps()
    end
  end

  def down do
    drop table(:merchants)
  end
end
