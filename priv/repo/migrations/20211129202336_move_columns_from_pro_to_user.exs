defmodule Strident.Repo.Migrations.MoveColumnsFromProToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :avatar_url, :string
    end

    execute("""
      UPDATE users AS u set avatar_url = tmp.avatar_url
      FROM (
        SELECT avatar_url, user_id
        FROM pros
      ) AS tmp
      WHERE tmp.user_id = u.id;
    """)

    alter table(:pros) do
      remove :avatar_url
    end

    create table(:user_favorite_games, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id), null: false
      add :game_id, references(:games, on_delete: :nothing, type: :binary_id), null: false
    end

    create unique_index(:user_favorite_games, [:user_id, :game_id])
    create index(:user_favorite_games, :user_id)
    create index(:user_favorite_games, :game_id)

    execute("""
      INSERT INTO user_favorite_games
        SELECT pfg.id, p.user_id, pfg.game_id
        FROM pro_favorite_games AS pfg
        INNER JOIN pros AS p ON pfg.pro_id = p.id;
    """)

    drop table(:pro_favorite_games)
  end
end
