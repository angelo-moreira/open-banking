defmodule OpenBankingTransactionTest do
  @moduledoc false

  use ExUnit.Case
  doctest OpenBanking.Transaction

  alias Ecto.Adapters.SQL.Sandbox, as: SqlSandbox
  alias OpenBanking.Repo
  alias OpenBanking.Transaction

  setup do
    :ok = SqlSandbox.checkout(OpenBanking.Repo)
  end

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
    matches = Transaction.import!("test/transactions.csv", %{})

    all_matched? =
      Enum.all?(@testing_data, fn {match_description, match_merchant} ->
        Enum.find(matches, fn %{description: description, merchant: merchant} ->
          description == match_description && merchant == match_merchant
        end)
      end)

    assert all_matched?
  end

  @tag :import
  @tag :save_all
  test "can load a CSV file and save it to the DB" do
    res =
      "test/transactions.csv"
      |> Transaction.import!(%{})
      |> Transaction.insert_all(%{})

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
  @tag :save_all
  test "can load a CSV file but should return an error when saving" do
    [first | _] = transactions = Transaction.import!("test/transactions.csv", %{})

    # It shouldn't never fail (famous last words) but let's make him fail :)
    fail =
      transactions
      |> List.first()
      |> Map.put(:confidence, "jklasjedkl")

    transactions_failed =
      transactions
      |> List.replace_at(0, fail)
      |> Transaction.insert_all(%{})

    assert {:error, transactions_failed}

    {:error, [%Ecto.Changeset{} = failed_changeset]} = transactions_failed
    assert failed_changeset.changes.description == first.description
  end

  @tag :save_all
  @tag :save_all_with_options
  test "should only transactions with level of confidence the same or above 30%" do
    confidence = 0.3

    all_transactions = [
      %{merchant: "Disney", confidence: 0.1, description: "Disney 10%"},
      %{merchant: "Disney", confidence: 0.2, description: "Disney 20%"},
      %{merchant: "Disney", confidence: 0.3, description: "Disney 30%"},
      %{merchant: "Disney", confidence: 0.4, description: "Disney 40%"}
    ]

    assert {:ok, transactions} =
             Transaction.insert_all(all_transactions, %{confidence_more: confidence})

    assert length(transactions) == 2

    above_30? =
      Enum.all?(transactions, fn transaction -> transaction.confidence >= confidence end)

    assert above_30?
  end

  @tag :save_all
  @tag :save_all_with_options
  test "should only transactions with level of confidence the same or below 20%" do
    confidence = 0.2

    all_transactions = [
      %{merchant: "Disney", confidence: 0.1, description: "Disney 10%"},
      %{merchant: "Disney", confidence: 0.2, description: "Disney 20%"},
      %{merchant: "Disney", confidence: 0.3, description: "Disney 30%"},
      %{merchant: "Disney", confidence: 0.4, description: "Disney 40%"}
    ]

    assert {:ok, transactions} =
             Transaction.insert_all(all_transactions, %{confidence_less: confidence})

    assert length(transactions) == 2

    below_20? =
      Enum.all?(transactions, fn transaction -> transaction.confidence <= confidence end)

    assert below_20?
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

  @tag :save_one
  @tag :save_one_ok
  test "should save a record successfully " do
    res =
      Transaction.insert_one(
        %{
          merchant: "Fantasy Island",
          description: "Testing transaction",
          confidence: 0.8
        },
        %{}
      )

    assert {:ok, transaction} = res
    assert transaction.description == "Testing transaction"
  end

  @tag :save_one
  @tag :save_one_error
  test "shouldn't save a record if confidence is not bigger than 30%" do
    res =
      Transaction.insert_one(
        %{
          merchant: "Fantasy Island",
          description: "Testing transaction",
          confidence: 0.8
        },
        %{confidence_more: 0.3}
      )

    assert {:ok, %Transaction{}} = res
  end

  @tag :list
  test "get_all with only merchant should work" do
    Enum.map(1..3, fn _ ->
      Repo.insert!(%Transaction{
        confidence: 1.0,
        merchant: "Disney",
        description: "testing transaction"
      })
    end)

    transactions = Transaction.get_all(%{limit: 2, merchant: "Disney"})

    right_merchant? = Enum.all?(transactions, &(&1.merchant == "Disney"))
    assert right_merchant?
  end

  @tag :list
  test "get_all with limit and merchant should list 2 records" do
    Enum.map(1..3, fn _ ->
      Repo.insert!(%Transaction{
        confidence: 1.0,
        merchant: "Disney",
        description: "testing transaction"
      })
    end)

    transactions = Transaction.get_all(%{limit: 2, merchant: "Disney"})
    assert length(transactions) == 2
  end

  @tag :list
  test "get_all with confidence and merchant should work" do
    samples = [
      %Transaction{
        confidence: 1.0,
        merchant: "Disney",
        description: "testing transaction"
      },
      %Transaction{
        confidence: 0.9,
        merchant: "Disney",
        description: "testing transaction"
      },
      %Transaction{
        confidence: 0.8,
        merchant: "Disney",
        description: "testing transaction"
      },
      %Transaction{
        confidence: 0.7,
        merchant: "Disney",
        description: "testing transaction"
      }
    ]

    Enum.map(samples, &Repo.insert!/1)

    transactions = Transaction.get_all(%{confidence_more: 0.85, merchant: "Disney"})
    assert length(transactions) == 2

    transactions = Transaction.get_all(%{confidence_less: 0.85, merchant: "Disney"})
    assert length(transactions) == 2

    transactions =
      Transaction.get_all(%{confidence_more: 0.85, confidence_less: 0.95, merchant: "Disney"})

    assert length(transactions) == 1

    [transaction] = transactions
    assert transaction.confidence == 0.9
  end

  @tag :list
  test "get_all should work with keywords" do
    samples = [
      %Transaction{
        confidence: 1.0,
        merchant: "Disney",
        description: "testing transaction"
      },
      %Transaction{
        confidence: 0.9,
        merchant: "Disney",
        description: "testing transaction"
      }
    ]

    Enum.map(samples, &Repo.insert!/1)

    transactions = Transaction.get_all(merchant: "Disney", limit: 1)
    assert length(transactions) == 1

    merchant =
      transactions
      |> Enum.at(0)
      |> Map.get(:merchant)

    assert merchant == "Disney"
  end

  @tag :approve
  @tag :approve_ok
  test "should approve a transaction without a merchant" do
    %{id: inserted_id} =
      Repo.insert!(%Transaction{
        confidence: 1.0,
        merchant: "Disney",
        description: "testing transaction"
      })

    assert {:ok, transaction} = Transaction.approve(%{transaction_id: inserted_id})
    assert transaction.confidence == 1.0
  end

  @tag :approve
  @tag :approve_ok
  test "should approve a transaction and change the merchant" do
    %{id: inserted_id} =
      Repo.insert!(%Transaction{
        confidence: 1.0,
        merchant: "Disney",
        description: "testing transaction"
      })

    assert {:ok, transaction} =
             Transaction.approve(%{transaction_id: inserted_id, merchant: "Netflix"})

    assert transaction.confidence == 1.0
  end

  @tag :approve
  @tag :approve_error
  test "approve a transaction should fail because the ID is incorrect" do
    assert {:error, :transaction_id_not_found} =
             Transaction.approve(%{transaction_id: 45_678_345_646_465_465})
  end

  @tag :approve
  @tag :approve_error
  test "approve a transaction should fail because the merchant name is incorrect" do
    assert {:error, :merchant_not_found} =
             Transaction.approve(%{transaction_id: 1, merchant: "Non existing fairy tales"})
  end
end
