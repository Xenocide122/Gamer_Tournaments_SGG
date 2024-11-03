defmodule Strident.Repo.Migrations.AddPlatformToTournaments do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :platform, :string
    end
  end
end
