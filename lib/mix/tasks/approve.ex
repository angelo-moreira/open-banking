defmodule Mix.Tasks.OpenBanking.Approve do
  use Mix.Task
  import OpenBanking.Transaction, only: [approve: 1]
  import Mix.Tasks.OpenBanking.Helper, only: [print_transaction: 1]
  require Logger

  @shortdoc "Approves a transaction manually"

  @moduledoc """
  So the algorithm can improve we would need some feedback about what's wrong and right
  with the data, our match algorithms works with a "confidence level" based on trigrams
  so the more help we get, the better will be able to assert results.

  If we don't use the `--merchant` flag then we assume the bot first guess was right.

  Once a transaction has been approved the level of confidence will be 100%

  ## Examples

      mix open_banking.approve --transaction-id 8
      mix open_banking.approve --transaction-id 10 --merchant "Netflix"

  ## Command line options

    * `-t`, `--transaction-id` - the transaction ID coming from the database
    * `-m`, `--merchant` - merchant name, this can be improved as at the moment
      we only approve if the merchant matches exactly

  """

  @switches [
    transaction_id: :integer,
    merchant: :string
  ]

  @aliases [
    t: :transaction_id,
    m: :merchant
  ]

  @doc false
  def run(args) do
    # We want to start out APP and supervisors because we are going to need to
    # communicate with our DB
    Application.ensure_all_started(:open_banking)
    Logger.configure(level: :warn)

    {opts, _args, invalid_args} = OptionParser.parse(args, strict: @switches, aliases: @aliases)

    if not Enum.empty?(invalid_args) do
      invalid_args_keys =
        invalid_args
        |> Enum.map(fn {arg, _} -> arg end)
        |> Enum.join(",")

      Mix.raise(
        "Invalid flags: #{invalid_args_keys} \n run `mix help open_banking.approve` for a list of options available"
      )
    end

    Mix.shell().info("Approving transaction \n\n")

    opts = Map.new(opts)

    opts
    |> do_maybe_approve!()
    |> print_transaction()
  end

  defp do_maybe_approve!(%{transaction_id: _} = opts) do
    approved = approve(opts)

    case approved do
      {:ok, transaction} -> transaction
      {:error, :merchant_not_found} -> Mix.raise("Merchant is invalid")
      _ -> Mix.raise("Unexpected error saving transaction to the Database")
    end
  end

  defp do_maybe_approve!(_opts) do
    Mix.raise("""
      Required argument: --transaction-id is a required flag\n
      run `mix help open_banking.approve` for a list of options available and how to use them
    """)
  end
end
