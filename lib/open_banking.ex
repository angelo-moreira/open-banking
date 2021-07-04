defmodule OpenBanking do
  @moduledoc """
  Open Banking is a test exercise to parse descriptions that comes
  from multiple open banking APIs and try to match them with Merchants

  This solution is very simple and concentrates in the requirements given
  (match a description to a Merchant)

  We are using 2 data structures to represent all the data

    * `Merchant` - Represents all the known Merchants in the system,
      for example Netflix and Amazon

    * `Transaction` - A description of a transaction, at the moment
      this is just a description that we will try to match with a merchant
      with a confidence level

  """
end
