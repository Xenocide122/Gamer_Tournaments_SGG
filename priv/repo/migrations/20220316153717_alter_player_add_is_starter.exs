defmodule Strident.Repo.Migrations.AlterPlayerAddIsStarter do
  use Ecto.Migration

  def change do
    alter table(:players) do
      add :is_starter, :boolean, default: true
    end
  end
end
