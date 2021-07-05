defmodule OpenBankingTransactionTest do
  @moduledoc false

  use ExUnit.Case
  doctest OpenBanking.Transaction

  alias OpenBanking.Transaction

  @testing_data [
    {"sainsbury's sprmrkts lt london", "Sainburys"},
    {"uber help.uber.com", "Uber"},
    {"uber eats j5jgo help.uber.com ", "Uber Eats"},
    {"netflix.com amsterdam", "Netflix"},
    {"amazon eu sarl amazon.co.uk/", "Amazon"},
    {"netflix.com 866-716-0414", "Netflix"},
    {"uber eats 6p7n7 help.uber.com", "Uber Eats"},
    {"google *google g.co/helppay#", "Google"},
    {"amazon prime amzn.co.uk/pm", "Amazon Prime"},
    {"dvla vehicle tax", "DVLA"},
    {"dvla vehicle tax - vis", "DVLA"},
    {"direct debit payment to dvla-i2den", "DVLA"},
    {"dvla-ln99abc", "DVLA"},
    {"sky digital 13524686324522", "Sky Digital"},
    {"direct debit sky digital 83741234567852  ddr", "Sky Digital"},
    {"sky subscription - sky subscription  38195672157 gb", "Sky"},
    {"890e9ias897r9e8dfsf", "Unknown"}
  ]

  @tag :import
  test "can load a CSV file and match to merchants" do
    matches = Transaction.import!("test/transactions.csv")

    all_matched? =
      Enum.all?(@testing_data, fn {match_description, match_merchant} ->
        Enum.find(matches, fn %{description: description, merchant: merchant} ->
          description == match_description && merchant == match_merchant
        end)
      end)

    assert all_matched?
  end

  @tag :import
  @tag :save
  test "can load a CSV file and save it to the DB" do
    res =
      "test/transactions.csv"
      |> Transaction.import!()
      |> Transaction.insert_all()

    assert {:ok, transactions} = res

    all_matched? =
      Enum.all?(@testing_data, fn {match_description, match_merchant} ->
        Enum.find(transactions, fn %{description: description, merchant: merchant} ->
          description == match_description && merchant == match_merchant
        end)
      end)

    assert all_matched?
  end

  @tag :import
  @tag :save
  test "can load a CSV file but should return an error when saving" do
    [first | _] = transactions = Transaction.import!("test/transactions.csv")

    # It shouldn't never fail (famous last words) but let's make him fail :)
    fail =
      transactions
      |> List.first()
      |> Map.put(:confidence, "jklasjedkl")

    transactions_failed =
      transactions
      |> List.replace_at(0, fail)
      |> Transaction.insert_all()

    assert {:error, transactions_failed}

    {:error, [%Ecto.Changeset{} = failed_changeset]} = transactions_failed
    assert failed_changeset.changes.description == first.description
  end

  @tag :match
  test "should return unknown when no merchant could be found" do
    %{merchant: merchant} = Transaction.match!("890e9ias897r9e8dfsf")
    assert merchant == "Unknown"
  end

  @tag :match
  test "should return a valid merchant" do
    %{merchant: merchant} = Transaction.match!("google *google g.co/helppay#")
    assert merchant == "Google"
  end
end
