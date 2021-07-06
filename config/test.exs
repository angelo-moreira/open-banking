use Mix.Config

# Usually credentials are not hardcoded in this file and should
# instead be env variables in the pipeline
# but to not "pollute" your dev machine and since this is not
# prod credentials I'm going to be submitting this to the repo :) (naughty smile)
config :open_banking, OpenBanking.Repo,
  database: "open_banking_test",
  username: "open_banking_user",
  password: "open_banking_pass",
  hostname: "localhost",
  port: 5444,
  migration_source: "_migrations_for_db",
  pool: Ecto.Adapters.SQL.Sandbox

# we want to run the tests in the sandbox so we don't share
# data between the tests

# Print only warnings and errors during test
config :logger, level: :warn
