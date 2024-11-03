defmodule Strident.Repo.Migrations.AddTypeToMatches do
  use Ecto.Migration

  def change do
    alter table(:matches) do
      add :type, :string, null: true
    end

    execute("UPDATE matches set type='standard';", "")

    alter table(:matches) do
      modify :type, :string, null: false
    end
  end
end
