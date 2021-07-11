defmodule Mix.Tasks.OpenBanking.List do
  use Mix.Task
  import OpenBanking.Transaction, only: [get_all: 1]
  import Mix.Tasks.OpenBanking.Helper, only: [print_transaction: 1]
  require Logger

  @shortdoc "lists all the transactions stored in the database"

  @moduledoc """
  Lists all the transactions in the database, we have some options to limit the amount of
  transactions returned

  ## Examples

      mix open_banking.list --merchant "Unknown"
      mix open_banking.list --merchant "Netflix" --confidence-less 20

  ## Command line options

    * `-cl`, `--confidence_less` - only returns the transactions that are below or equals a value
      from 0% to 100% represented by integers from 0 to 100
    * `-cm`, `--confidence_more` - only returns the transactions that are above or equals a value
      from 0% to 100% represented by integers from 0 to 100
    * `-m`, `--merchant` - only returns the transactions that matches the merchant name, the name
      must match the value exactly
    * `-l`, `--limit` - limits the number of transactions returned

  """

  @switches [
    confidence_less: :integer,
    confidence_more: :integer,
    merchant: :string,
    limit: :integer
  ]

  @aliases [
    cl: :confidence_less,
    cm: :confidence_more,
    m: :merchant,
    l: :limit
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
        "Invalid flags: #{invalid_args_keys} \n run `mix help open_banking.list` for a list of options available"
      )
    end

    Mix.shell().info("Fetching transactions from the database \n\n")

    opts = Map.new(opts)

    opts
    |> do_convert_confidence()
    |> get_all()
    |> Enum.map(&print_transaction/1)
  end

  # converting integers from 0 to 100 to floats, from 0 to 1
  # this is done to reuse the `import!` function and provide a nice easy API to use
  defp do_convert_confidence(opts) do
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
