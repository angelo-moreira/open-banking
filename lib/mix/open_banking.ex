defmodule Mix.Tasks.OpenBanking do
  use Mix.Task
  alias Mix.Tasks.Help

  @shortdoc "Kinda terminal App but not quite :)"

  @moduledoc """
  Shows the available tasks for the app

      mix open_banking

  """

  @doc false
  def run(args) do
    {_opts, args} = OptionParser.parse!(args, strict: [])

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
  end
end
