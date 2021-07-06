alias OpenBanking.Merchant
alias OpenBanking.Transaction
alias OpenBanking.Repo

merchants = [
  "Sainburys",
  "Uber",
  "Netflix",
  "Amazon",
  "Uber Eats",
  "Google",
  "Amazon Prime",
  "DVLA",
  "Sky Digital",
  "Sky"
]

merchants
|> Enum.map(&Repo.insert!(%Merchant{name: &1}))
|> Enum.map(fn %{name: name} ->
  Repo.insert!(%Transaction{description: name, confidence: 1.0, merchant: name})
end)
