defmodule Strident.Repo.Local.Migrations.MakeTournamentManagementPersonnelUniqueOverTournamentAndUser do
  use Ecto.Migration

  def up do
    execute """
    DELETE FROM tournament_management_personnel tmp0 where tmp0.id in (
      SELECT unnest(array_agg(sq.ids)) FROM (
        SELECT
          UNNEST((ARRAY_AGG(tmp1.id))[2:]) as ids,
          tmp1.user_id,
          tmp1.tournament_id,
          count(tmp1.*) AS count
        FROM tournament_management_personnel tmp1
        GROUP BY tmp1.user_id, tmp1.tournament_id
      ) AS sq WHERE sq.count > 1
    );
    """

    create unique_index(:tournament_management_personnel, [:user_id, :tournament_id])
  end

  def down do
    drop unique_index(:tournament_management_personnel, [:user_id, :tournament_id])
  end
end
