defmodule Strident.Games.UserFavoriteGame do
  @moduledoc false
  use TypedEctoSchema

  import Ecto.Changeset

  alias Strident.Accounts.User
  alias Strident.Games.Game

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "user_favorite_games" do
    belongs_to :user, User
    belongs_to :game, Game
  end

  @doc false
  def changeset(pro_favorite_game, attrs) do
    pro_favorite_game
    |> bulk_update_changeset(attrs)
    |> unsafe_validate_unique([:user_id, :game_id], Strident.Repo)
  end

  @doc false
  def bulk_update_changeset(pro_favorite_game, attrs) do
    pro_favorite_game
    |> cast(attrs, [:user_id, :game_id])
    |> validate_required([:user_id, :game_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:game_id)
  end
end
