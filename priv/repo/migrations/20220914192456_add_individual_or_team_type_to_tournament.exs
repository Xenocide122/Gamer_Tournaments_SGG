defmodule Strident.Repo.Migrations.AddIndividualOrTeamTypeToTournament do
  use Ecto.Migration

  def change do
    create_query = "CREATE TYPE tournament_participant_type AS ENUM ('individual', 'team')"
    drop_query = "DROP TYPE tournament_participant_type"
    execute(create_query, drop_query)

    alter table(:tournaments) do
      add :participant_type, :tournament_participant_type
      add :players_per_participant, :integer, default: 1
    end

    execute """
    UPDATE tournaments SET participant_type='individual';
    """

    execute """
    UPDATE tournaments SET players_per_participant='1';
    """

    alter table(:tournaments) do
      modify :participant_type, :tournament_participant_type, null: false
      remove :required_player_count
    end
  end
end
