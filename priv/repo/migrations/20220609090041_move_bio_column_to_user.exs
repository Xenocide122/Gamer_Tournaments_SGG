defmodule Strident.Repo.Migrations.MoveBioColumnToUser do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :bio, :text, null: true
    end

    execute """
    UPDATE users SET bio = (SELECT bio FROM pros WHERE pros.user_id = users.id);
    """

    alter table(:pros) do
      remove :bio
    end
  end

  def down do
    alter table(:pros) do
      add :bio, :text, null: true
    end

    execute """
    UPDATE pros SET bio = (SELECT bio FROM users WHERE pros.user_id = users.id);
    """

    alter table(:users) do
      remove :bio
    end
  end
end
