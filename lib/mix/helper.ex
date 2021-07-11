defmodule Mix.Tasks.OpenBanking.Helper do
  @moduledoc false
  def print_transaction(transaction) do
    id =
      if Map.has_key?(transaction, :id) do
        transaction.id
      else
        "not saved"
      end

    msg = """
    ID: #{id}
    Description: #{transaction.description}
    Merchant: #{transaction.merchant}
    Confidence: #{transaction.confidence * 100}
    \n=======================\n
    """

    Mix.shell().info(msg)
  end
end
