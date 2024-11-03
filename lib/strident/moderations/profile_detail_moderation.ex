defmodule Strident.Moderations.ProfileDetailModeration do
  @moduledoc """
  Moderation details for a user
  """
  use TypedEctoSchema
  use EctoAnon.Schema

  import Ecto.Changeset

  alias Strident.Accounts.User

  @type id :: Strident.id()

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "profile_detail_moderations" do
    belongs_to(:user, User, foreign_key: :user_id)
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
  def changeset(moderation, attrs) do
    moderation
    |> cast(attrs, [
      :user_id,
      :status,
      :requested_fields,
      :moderated_fields,
      :acting_moderator,
      :approved_at
    ])
    |> validate_status()
  end

  defp validate_status(changeset) do
    validate_inclusion(changeset, :status, ["pending_approval", "approved", "rejected"],
      message: "must be either 'pending_approval', 'approved', or 'rejected'"
    )
  end
end
