defmodule Strident.Repo.Local.Migrations.AddIsScrimToTournaments do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :is_scrim, :boolean, default: false
    end
  end
end
