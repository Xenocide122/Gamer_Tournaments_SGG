defmodule Strident.Repo.Migrations.RemoveNameFromPro do
  use Ecto.Migration

  def change do
    alter table(:pros) do
      remove :name
    end
  end
end
