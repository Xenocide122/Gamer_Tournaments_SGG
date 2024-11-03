defmodule Strident.Repo.Migrations.PartiesNameCitext do
  use Ecto.Migration

  def change do
    alter table(:parties) do
      modify :name, :citext, null: false
    end
  end
end
