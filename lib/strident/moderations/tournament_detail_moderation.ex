defmodule Strident.Moderations.TournamentDetailModeration do
  @moduledoc """
  Moderation details for the tournament
  """
  use TypedEctoSchema
  use EctoAnon.Schema

  import Ecto.Changeset

  alias Strident.Accounts.User
  alias Strident.Tournaments.Tournament

  @type id :: Strident.id()
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "tournament_detail_moderations" do
    belongs_to(:tournament, Tournament, foreign_key: :tournament_id)
    field(:requested_fields, :map, default: %{})
    field(:moderated_fields, :map, default: %{})
    field(:status, :string, default: "pending_approval")
    belongs_to(:moderator, User, foreign_key: :acting_moderator)
    field(:approved_at, :naive_datetime)
    timestamps()
  end

  @doc """
  Changeset for creating/modifying a moderation entry
  """
  def changeset(tournament_moderation, attrs) do
    tournament_moderation
    |> cast(attrs, [
      :tournament_id,
      :status,
      :requested_fields,
      :moderated_fields,
      :acting_moderator,
      :approved_at
    ])
    |> validate_tournament_status()
  end

  defp validate_tournament_status(changeset) do
    validate_inclusion(changeset, :status, ["pending_approval", "approved", "rejected"],
      message: "must be either 'pending_approval', 'approved', or 'rejected'"
    )
  end
end
