defmodule Mix.Tasks.OpenBanking.Match do
  use Mix.Task
  import OpenBanking.Transaction, only: [match!: 1, insert_one: 2]
  import Mix.Tasks.OpenBanking.Helper, only: [print_transaction: 1]
  require Logger

  @shortdoc "Matches a description to a merchant and returns a confidence level"

  @moduledoc """
  The decription should be a string, `match` will try to match it against a merchant
  in the database and return a level of confidence, the matching algorithm uses trigrams
  to try to find a good match.

  ## Examples

      mix open_banking.match --description "This is a Netflix description"
      mix open_banking.match --description "This is a Netflix description" --save

  ## Command line options

    * `-s`, `--save` - save the results to the database
    * `-d`, `--description` - text representation of a transaction, this will be matched against a merchant

  """

  @switches [
    save: :boolean,
    description: :string
  ]

  @aliases [
    s: :save,
    d: :description
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
        "Invalid flags: #{invalid_args_keys} \n run `mix help open_banking.match` for a list of options available"
      )
    end

    Mix.shell().info("Matching transaction description \n\n")

    opts = Map.new(opts)

    opts
    |> do_maybe_match!()
    |> do_maybe_save(opts)
    |> print_transaction()
  end

  defp do_maybe_match!(%{description: description}),
    do: match!(description)

  defp do_maybe_match!(_opts) do
    Mix.raise("""
      Required argument: --description is a required flag\n
      run `mix help open_banking.match` for a list of options available and how to use them
    """)
  end

  defp do_maybe_save(transaction, %{save: true}) do
    saved_to_db = insert_one(transaction, %{})

    case saved_to_db do
      {:ok, transaction} -> transaction
      _ -> Mix.raise("Unexpected error saving transaction to the Database")
    end
  end

  defp do_maybe_save(transactions, _opts), do: transactions
end
