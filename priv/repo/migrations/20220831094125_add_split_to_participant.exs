defmodule Strident.Repo.Migrations.AddSplitToParticipant do
  use Ecto.Migration

  def change do
    alter table(:tournament_participants) do
      add :split, :decimal
    end
  end
end
