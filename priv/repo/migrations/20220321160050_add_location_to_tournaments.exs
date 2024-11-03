defmodule Strident.Repo.Migrations.AddLocationToTournaments do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :location, :string
    end
  end
end
