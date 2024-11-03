defmodule StridentWeb.SitemapView do
  use StridentWeb, :view
  alias Strident.Extension.NaiveDateTime

  def format_date(date) do
    date
    |> NaiveDateTime.to_date()
    |> to_string()
  end
end
