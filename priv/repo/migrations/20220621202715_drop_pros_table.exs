defmodule Strident.Repo.Migrations.DropProsTable do
  use Ecto.Migration

  def change do
    drop table(:pros)
  end
end
