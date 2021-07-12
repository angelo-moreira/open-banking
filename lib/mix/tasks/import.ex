defmodule Mix.Tasks.OpenBanking.Import do
  use Mix.Task
  import OpenBanking.Transaction, only: [import!: 2, insert_all: 2]
  import Mix.Tasks.OpenBanking.Helper, only: [print_transaction: 1, convert_confidence: 1]
  require Logger

  @shortdoc "Reads a CSV file and shows a list of matches against previous seen transactions"

  @moduledoc """
  Imports a CSV file to the database, you can save it and filter it, please look at the command
  line options and example to understand how

  ## Examples

      mix open_banking.import --file "path to the file in the system"
      mix open_banking.import --file "path to the file in the system" --save --confidence-more 10

  ## Command line options

    * `-s`, `--save` - save the results to the database, if confidences flags are passed
      it will only save the results that match
    * `-f`, `--file` - specificies the file path in the system to import, needs to be a CSV file
    * `-cl`, `--confidence_less` - only returns the transactions that are below or equals a value
    ` from 0% to 100% represented by integers from 0 to 100
    * `-cm`, `--confidence_more` - only returns the transactions that are above or equals a value
    ` from 0% to 100% represented by integers from 0 to 100

  """

  @switches [
    save: :boolean,
    file: :string,
    confidence_less: :integer,
    confidence_more: :integer
  ]

  @aliases [
    s: :save,
    f: :file,
    cl: :confidence_less,
    cm: :confidence_more
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
        "Invalid flags: #{invalid_args_keys} \n run `mix help open_banking.import` for a list of options available"
      )
    end

    Mix.shell().info("Importing file \n\n")

    opts = Map.new(opts)

    opts
    |> convert_confidence()
    |> do_import(nil, %{})
    |> do_maybe_save(opts)
    |> print_to_terminal()
  end

  defp do_import(%{file: file} = opts, _, _args) do
    opts
    |> Map.delete(:file)
    |> do_import(file)
  end

  defp do_import(_opts, file, _args) when is_nil(file) do
    Mix.raise(
      "Required argument: --file is a required flag\n run `mix help open_banking.import` for a list of options available and how to use them"
    )
  end

  defp do_import(opts, file),
    do: import!(file, opts)

  defp do_maybe_save(transactions, %{save: true}) do
    saved_to_db = insert_all(transactions, %{})

    case saved_to_db do
      {:ok, transactions} -> transactions
      _ -> Mix.raise("Unexpected error saving transactions to the Database")
    end
  end

  defp do_maybe_save(transactions, _opts), do: transactions

  defp print_to_terminal(transactions) do
    Enum.map(transactions, &print_transaction/1)
  end
end
