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

  @doc """
    converts integers from 0 to 100 to floats, from 0 to 1
  """
  def convert_confidence(opts) do
    case opts do
      %{confidence_more: more_than, confidence_less: less_than} ->
        more_than = more_than / 100
        less_than = less_than / 100

        opts
        |> Map.put(:confidence_more, more_than)
        |> Map.put(:confidence_less, less_than)

      %{confidence_more: more_than} ->
        more_than = more_than / 100
        Map.put(opts, :confidence_more, more_than)

      %{confidence_less: less_than} ->
        less_than = less_than / 100
        Map.put(opts, :confidence_less, less_than)

      _ ->
        opts
    end
  end
end
