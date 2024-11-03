defmodule Strident.Repo.Local.Migrations.AddAllowWagerOnTournament do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :allow_wager, :boolean, default: false
    end
  end
end
