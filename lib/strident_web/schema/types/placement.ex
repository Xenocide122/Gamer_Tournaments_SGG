defmodule StridentWeb.Schema.Types.Placement do
  @moduledoc false

  use Absinthe.Schema.Notation

  @desc """
  A Placement is where we save the result for a user
  given a specific tournament.

  We use the Placement schemas as a way to save results from external tournament sites like Smash.gg,
  Matcherino, etc.

  Placements in internal, Stride, tournaments are saved in the TournamentParticipant struct.

  These placements are then used to show a players track record
  on their Go Stake Me / Profile page.
  """
  object :placement do
    field :user, :user
    field :canonical_url, :string
    field :rank, :integer
    field :source, :string
    field :total_players, :integer
    field :date, :naive_datetime
    field :title, :string
    field :game_title, :string
  end

  object :list_of_placements do
    field(:entries, list_of(non_null(:placement)))
    field(:page_number, :integer)
    field(:page_size, :integer)
    field(:total_pages, :integer)
    field(:total_entries, :integer)
  end
end
