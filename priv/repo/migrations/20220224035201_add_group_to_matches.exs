defmodule Strident.Repo.Migrations.AddGroupToMatches do
  use Ecto.Migration

  def change do
    alter table(:matches) do
      add :group, :string, size: 8, null: true
    end
  end
end
