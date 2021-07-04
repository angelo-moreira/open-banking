defmodule OpenBanking.Repo.Migrations.CreateTransactions do
  @moduledoc false
  use Ecto.Migration

  def up do
    create table(:transaction) do
      add(:description, :text, null: false)
      add(:confidence, :float, null: false)
      add(:merchant, :text, null: false)
      timestamps()
    end

    # Installing trigrams extension to Postgres
    # This would let us search a string and return a level of confidence
    execute "CREATE EXTENSION pg_trgm;"

    # Index descriptions so Postgres can run trigrams comparison faster
    execute "CREATE INDEX transaction_name_trigrams_index ON transaction USING GIN (description gin_trgm_ops);"
  end

  def down do
    drop table(:transaction)
    execute("DROP EXTENSION pg_trgm")
  end
end
