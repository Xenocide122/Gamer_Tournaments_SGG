defmodule Strident.Repo.Migrations.AddTypeBoolsToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :is_tournament_organizer, :boolean
      add :is_caster, :boolean
      add :is_graphic_designer, :boolean
      add :is_producer, :boolean
    end
  end
end
