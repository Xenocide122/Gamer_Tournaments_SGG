defmodule Strident.Repo.Migrations.AddTableUserFollowers do
  use Ecto.Migration

  def change do
    create table(:user_followers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id), null: false
      add :follower_id, references(:users, on_delete: :nothing, type: :binary_id), null: false

      timestamps()
    end

    create unique_index(:user_followers, [:user_id, :follower_id])
  end
end
