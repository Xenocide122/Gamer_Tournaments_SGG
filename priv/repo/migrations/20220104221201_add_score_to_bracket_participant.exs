defmodule Strident.Repo.Migrations.AddScoreToBracketParticipant do
  use Ecto.Migration

  def change do
    alter table(:bracket_participants) do
      add :score, :string
    end
  end
end
