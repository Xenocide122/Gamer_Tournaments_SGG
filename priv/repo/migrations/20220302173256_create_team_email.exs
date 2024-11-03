defmodule Strident.Repo.Migrations.CreateTeamEmail do
  use Ecto.Migration

  def change do
    alter table(:teams) do
      add :email, :string, null: true
    end

    execute("""
      UPDATE teams AS t
        SET email = tmp.email
        FROM (
          SELECT
            user_per_teams.team_id,
            user_per_teams.email
          FROM (
            SELECT
              t.id AS team_id,
              tm.type,
              row_number() over (PARTITION BY t.id ORDER BY tm.type, tm.updated_at) rank,
              pc.email
            FROM teams AS t
            INNER JOIN team_members tm ON t.id = tm.team_id
            INNER JOIN users u on tm.user_id = u.id
            LEFT JOIN password_credentials pc on u.id = pc.user_id
          ) AS user_per_teams
          WHERE user_per_teams.rank = 1
        ) AS tmp
      WHERE t.id = tmp.team_id;
    """)

    alter table(:teams) do
      modify :email, :string, null: false
    end
  end
end
