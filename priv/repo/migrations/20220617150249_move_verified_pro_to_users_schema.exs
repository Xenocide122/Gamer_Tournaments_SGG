defmodule Strident.Repo.Migrations.MoveVerifiedProToUsersSchema do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :verified, :boolean, default: false
    end

    execute """
    UPDATE users SET verified = (SELECT verified FROM pros WHERE pros.user_id = users.id);
    """

    alter table(:pros) do
      remove :verified
    end
  end

  def down do
    alter table(:pros) do
      add :verified, :boolean, default: false
    end

    execute """
    	UPDATE pros SET verified = (SELECT verified FROM users WHERE users.id = pros.user_id);
    """

    alter table(:users) do
      remove :verified
    end
  end
end
