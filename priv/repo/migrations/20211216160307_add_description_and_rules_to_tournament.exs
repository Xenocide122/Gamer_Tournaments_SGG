defmodule Strident.Repo.Migrations.AddDescriptionAndRulesToTournament do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :description, :text
      add :rules, :text
    end
  end
end
