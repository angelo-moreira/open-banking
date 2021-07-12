defmodule Mix.Tasks.OpenBanking.CreateMerchant do
  use Mix.Task
  import OpenBanking.Merchant, only: [insert_one: 1]
  require Logger

  @shortdoc "Creates a Merchant in the database"

  @moduledoc """
  Creates a merchant in the database, we just need to pass a name, behind the scenes
  it also creates a transaction with the description as the merchant name so we start
  matching transactions against the merchant.

  ## Examples

      mix open_banking.create_merchant --merchant "Cinderella"

  ## Command line options

    * `-m`, `--merchant` - merchant name

  """

  @switches [
    merchant: :string
  ]

  @aliases [
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
        "Invalid flags: #{invalid_args_keys} \n run `mix help open_banking.create-merchant` for a list of options available"
      )
    end

    Mix.shell().info("Creating a merchant \n\n")

    opts
    |> Map.new()
    |> do_create_merchant()

    Mix.shell().info("Merchant created successfully \n")
  end

  defp do_create_merchant(%{merchant: name}) do
    insert_one(%{name: name})
  end

  defp do_create_merchant(_opts) do
    Mix.raise("""
      Required argument: --merchant is a required flag\n
      run `mix help open_banking.create_merchant` for a list of options available and how to use them
    """)
  end
end
