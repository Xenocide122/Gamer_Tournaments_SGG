defmodule Strident.Repo.Migrations.AddEmailToParties do
  use Ecto.Migration

  def change do
    alter table(:parties) do
      add :email, :string, null: true
    end

    execute("""
      UPDATE parties AS p
      SET email = tmp.email
      FROM (
        SELECT
          user_per_party.party_id,
          user_per_party.email
        FROM (
          SELECT
            p.id AS party_id,
            pm.type,
            row_number() over (PARTITION BY p.id ORDER BY pm.type, pm.updated_at) rank,
            pc.email
          FROM parties AS p
          INNER JOIN party_members pm ON p.id = pm.party_id
          INNER JOIN users u on pm.user_id = u.id
          LEFT JOIN password_credentials pc on u.id = pc.user_id
        ) AS user_per_party
        WHERE user_per_party.rank = 1
      ) AS tmp
      WHERE p.id = tmp.party_id;
    """)

    alter table(:teams) do
      modify :email, :string, null: false
    end
  end
end
