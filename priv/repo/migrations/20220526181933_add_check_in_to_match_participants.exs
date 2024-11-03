defmodule Strident.Repo.Migrations.AddCheckInToMatchParticipants do
  use Ecto.Migration

  def change do
    alter table(:match_participants) do
      add :check_in, :boolean, default: false
    end
  end
end
