defmodule Strident.Moderations.TeamDetailModeration do
  @moduledoc """
  Moderation details for the team
  """

  use TypedEctoSchema
  use EctoAnon.Schema

  import Ecto.Changeset

  alias Strident.Accounts.User
  alias Strident.Teams.Team

  @type id :: Strident.id()

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "team_detail_moderations" do
    belongs_to(:team, Team, foreign_key: :team_id)
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
  def changeset(team_moderation, attrs) do
    team_moderation
    |> cast(attrs, [
      :team_id,
      :status,
      :requested_fields,
      :moderated_fields,
      :acting_moderator,
      :approved_at
    ])
    |> validate_team_status()
  end

  defp validate_team_status(changeset) do
    validate_inclusion(changeset, :status, ["pending_approval", "approved", "rejected"],
      message: "must be either 'pending_approval', 'approved', or 'rejected'"
    )
  end
end
