defmodule Mix.Tasks.OpenBanking do
  use Mix.Task
  alias Mix.Tasks.Help

  @shortdoc "Kinda terminal App but not quite :)"

  @moduledoc """
  Shows the commands available for the app

      mix open_banking

  If you are really running this in a iex shell (unlikely) you can run

      Mix.Tasks.OpenBanking.run([])

  """

  @switches [
    save: :boolean,
    confidence_less: :integer,
    confidence_more: :integer
  ]

  @aliases [
    s: :save,
    l: :confidence_less,
    m: :confidence_more
  ]

  @doc false
  def run(args) do
    {_opts, args} = OptionParser.parse!(args, switches: @switches, aliases: @aliases)

    case args do
      [] -> general()
      _ -> Mix.raise("Invalid arguments, expected: mix open-banking")
    end
  end

  defp general do
    Application.ensure_all_started(:open_banking)
    Mix.shell().info("Open Banking v#{Application.spec(:open_banking, :vsn)}")
    Mix.shell().info("An Application to identify transactions with Merchants.")
    Mix.shell().info("\nAvailable tasks:\n")
    Help.run(["--search", "open_banking."])

    # mix open_banking.list --confidence-less 10 --confidence-more 20 --merchant="Uber" --limit 5
    # mix open_banking.approve --transaction-id sadhlsjdasd merchant="Uber"
    # mix open_banking.create_merchant "Cinderella"
  end
end
