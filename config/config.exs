import Config

config :open_banking, ecto_repos: [OpenBanking.Repo]

import_config "#{Mix.env()}.exs"
