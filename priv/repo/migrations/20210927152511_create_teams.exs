defmodule Strident.Repo.Migrations.CreateTeams do
  use Ecto.Migration

  def change do
    create table(:teams, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :logo_url, :string, null: false
      add :description, :string, null: false

      timestamps()
    end
  end
end
